import QuotioHostClient
import Foundation
import CryptoKit
import QuotioApplication
import QuotioDomain

public actor QuotioCLIBackend: AccountManaging, QuotaCoordinating {
    private struct Empty: Decodable, Sendable {}
    private struct RefreshBody: Encodable {
        let providers: [String]
        let accountId: String?
        let force: Bool
        let disabledProxyAuthFiles: [String]
    }
    private struct APIKeyBody: Encodable {
        let provider: String?
        let label: String
        let apiKey: String
    }
    private struct EnabledBody: Encodable { let enabled: Bool }
    private struct SourceDiscoveryBody: Encodable {
        let provider: String
        let kind: String
        let inspect: Bool
    }
    public private(set) var snapshot = QuotaSnapshot()
    private var client: QuotioHostHTTPClient?
    private var reportedAccounts: [Account] = []
    private var hostSnapshot: QuotioHostSnapshot?
    private var connectionID = UUID()
    private var snapshotRequestID = UUID()
    private var activeMode: QuotaOperatingMode = .monitor
    private var continuations: [UUID: AsyncStream<QuotaSnapshot>.Continuation] = [:]
    private let logger: (any ApplicationLogging)?
    private let trackingPreferences: (any ProviderTrackingPreferencesRepository)?
    private let session: URLSession?
    private let userDefaults: UserDefaults
    private let authFileState: (any ManagedAuthFileStateRepository)?
    private let localization: @MainActor @Sendable () -> (bundle: Bundle, locale: Locale)
    private var storageRequiresAuthorization = false
    private var discoveredNativeSourceKinds: Set<String> = []
    private static let pendingNativeSourcesKey = "quotioCLI.pendingNativeSources.v1"

    public init(
        session: URLSession? = nil,
        logger: (any ApplicationLogging)? = nil,
        trackingPreferences: (any ProviderTrackingPreferencesRepository)? = nil,
        userDefaults: UserDefaults = .standard,
        authFileState: (any ManagedAuthFileStateRepository)? = nil,
        localization: @escaping @MainActor @Sendable () -> (bundle: Bundle, locale: Locale) = { (.main, .current) }
    ) {
        self.session = session
        self.logger = logger
        self.trackingPreferences = trackingPreferences
        self.userDefaults = userDefaults
        self.authFileState = authFileState
        self.localization = localization
    }

    public func connect(_ connection: QuotioHostConnection) {
        connectionID = UUID()
        hostSnapshot = nil
        reportedAccounts = []
        snapshot = QuotaSnapshot()
        client = QuotioHostHTTPClient(connection: connection, session: session)
    }

    public func disconnect() {
        connectionID = UUID()
        client = nil
        markFailure(for: Set(Self.supportedProviders))
    }

    public func states() -> AsyncStream<QuotaSnapshot> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    public func bootstrap(mode: QuotaOperatingMode) async -> QuotaSnapshot {
        selectMode(mode)
        await loadSnapshot(mode: mode)
        return snapshot
    }

    public func refresh(_ request: QuotaFetchRequest) async -> QuotaSnapshot {
        selectMode(request.mode)
        guard isTracked(request.provider) else { return snapshot }
        guard let provider = QuotioCLIProviderMap.cli(request.provider) else { return snapshot }
        var resolvedAccountID: String?
        if case .account(let accountKey) = request.scope {
            resolvedAccountID = await accountID(provider: provider, accountKey: accountKey)
            guard resolvedAccountID != nil else {
                markFailure(for: [request.provider])
                return snapshot
            }
        }
        let importedAccounts: Set<String>? = if case .importedAccounts(let keys) = request.scope { keys } else { nil }
        await performRefresh(
            providers: [provider],
            accountID: resolvedAccountID,
            mode: request.mode,
            force: request.force,
            importedAccounts: importedAccounts
        )
        return snapshot
    }

    public func refreshAll(
        mode: QuotaOperatingMode,
        providers: Set<QuotaProvider>? = nil,
        force: Bool = false
    ) async -> QuotaSnapshot {
        selectMode(mode)
        let selected = (providers ?? Set(Self.supportedProviders)).filter(isTracked).compactMap(QuotioCLIProviderMap.cli)
        await performRefresh(providers: selected, accountID: nil, mode: mode, force: force)
        return snapshot
    }

    public func removeQuota(for account: QuotaAccountID, mode: QuotaOperatingMode) {
        snapshot.quotas[account.provider]?[account.accountKey] = nil
        snapshot.accountIDs[account.provider]?[account.accountKey] = nil
        snapshot.accountAliases[account.provider]?.filter { $0.value == account.accountKey }
            .forEach { snapshot.accountAliases[account.provider]?[$0.key] = nil }
        snapshot.subscriptions[account.provider]?[account.accountKey] = nil
        snapshot.accountIssues[account] = nil
        snapshot.accountStates[account] = nil
        publish()
    }

    public func cancel(provider: QuotaProvider) {
        snapshot.refreshingProviders.remove(provider)
        publish()
    }

    public func cancelForTermination() {
        snapshot.refreshingProviders.removeAll()
        for continuation in continuations.values { continuation.finish() }
        continuations.removeAll()
    }

    public func registerDetectedNativeAccounts() async {
        guard trackingPreferences?.load().automaticallyDiscoverLogins != false else { return }
        await discoverNativeAccounts(providerID: nil)
    }

    private func discoverNativeAccounts(providerID: String?) async {
        guard let client,
              let response: QuotioCLIProviderList = try? await client.request("v1/providers"),
              response.schemaVersion == 1 else { return }
        var known = discoveredNativeSourceKinds
        var pending = Set(pendingNativeSources())
        for provider in response.providers {
            guard providerID == nil || providerID == provider.id else { continue }
            guard let domainProvider = QuotioCLIProviderMap.domain(provider.id), isTracked(domainProvider) else { continue }
            for source in provider.capabilities.sourceReferences
            where source.origin == "borrowed_native" && source.platforms.contains("macos") {
                let sourceKey = provider.id + ":" + source.kind
                guard !known.contains(sourceKey) else { continue }
                do {
                    let discovered = try await discoverNativeSource(
                        client: client, provider: provider.id, kind: source.kind, inspect: true
                    )
                    await logger?.write(.info, message: "Native discovery provider=\(domainProvider.rawValue) available=\(discovered.candidates.filter { $0.status == "available" }.count) permissionRequired=\(discovered.candidates.filter { $0.status == "permission_required" }.count)")
                    pending = pending.filter { $0.kind != source.kind }
                    if let domainProvider = QuotioCLIProviderMap.domain(provider.id) {
                        pending.formUnion(discovered.candidates.compactMap { candidate in
                            guard candidate.status == "permission_required" else { return nil }
                            return NativeSourcePermission(
                                provider: domainProvider,
                                kind: candidate.source.kind,
                                location: candidate.source.location
                            )
                        })
                    }
                    savePendingNativeSources(pending)
                    var registrationError: Error?
                    for candidate in discovered.candidates where candidate.status == "available" {
                        do {
                            let body = try JSONEncoder.quotioCLI.encode(candidate.source)
                            try await mutate(
                                client: client,
                                path: "v1/account-sources",
                                method: "POST",
                                body: body,
                                idempotencyKey: "quotio-native-v1-" + Self.sourceID([
                                    sourceKey,
                                    candidate.source.kind,
                                    candidate.source.location ?? "",
                                    candidate.source.discoveryRef ?? "",
                                    UUID().uuidString,
                                ])
                            )
                        } catch {
                            registrationError = error
                        }
                    }
                    if let registrationError { throw registrationError }
                    known.insert(sourceKey)
                    discoveredNativeSourceKinds = known
                } catch {
                    await logger?.write(.warning, message: "Native discovery provider=\(domainProvider.rawValue) failed=\(Self.failureCategory(error))")
                    continue
                }
            }
        }
    }

    public func rescanNativeAccounts(for provider: QuotaProvider) async {
        guard isTracked(provider), let providerID = QuotioCLIProviderMap.cli(provider) else { return }
        discoveredNativeSourceKinds = discoveredNativeSourceKinds.filter { !$0.hasPrefix(providerID + ":") }
        await discoverNativeAccounts(providerID: providerID)
    }

    public func nativeSourcesRequiringPermission() async -> [NativeSourcePermission] {
        let pending = pendingNativeSources().filter { isTracked($0.provider) }
        guard let client,
              let response: QuotioCLIAccountList = try? await client.request("v1/accounts"),
              response.schemaVersion == 1 else { return pending }
        return pending.filter { source in
            !response.accounts.contains {
                QuotioCLIProviderMap.domain($0.provider) == source.provider
                    && $0.sourceKind == source.kind
                    && $0.sourceLocation == source.location
            }
        }
    }

    public func authorizeNativeSource(_ source: NativeSourcePermission) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        let body = try JSONEncoder.quotioCLI.encode(QuotioCLISourceDiscovery.Candidate.Source(
            kind: source.kind,
            location: source.location,
            discoveryRef: nil
        ))
        do {
            try await mutate(
                client: client,
                path: "v1/account-sources/authorize",
                method: "POST",
                body: body,
                idempotencyKey: "quotio-native-permission-" + UUID().uuidString,
                timeout: .seconds(300)
            )
        } catch {
            switch error {
            case QuotioHostClientError.response(_, "quotio_vault_access_failed"),
                 QuotioHostClientError.response(_, "credential_storage_unavailable"):
                throw NativeSourceAuthorizationFailure.quotioVault
            case QuotioHostClientError.response(_, "native_keychain_access_failed"):
                throw NativeSourceAuthorizationFailure.nativeKeychain
            case QuotioHostClientError.response(_, "native_login_required"):
                throw NativeSourceAuthorizationFailure.nativeLogin
            case QuotioHostClientError.response(_, "native_credential_invalid"):
                throw NativeSourceAuthorizationFailure.invalidCredential
            case QuotioHostClientError.timeout:
                throw NativeSourceAuthorizationFailure.timeout
            default:
                throw NativeSourceAuthorizationFailure.unknown
            }
        }
        var authorized = Set(await authorizedNativeSources())
        authorized.insert(source)
        userDefaults.set(try? JSONEncoder().encode(authorized.sorted { $0.id < $1.id }), forKey: "quotioCLI.authorizedNativeSources.v1")
        savePendingNativeSources(Set(pendingNativeSources()).subtracting([source]))
        await registerDetectedNativeAccounts()
    }

    public func authorizedNativeSources() async -> [NativeSourcePermission] {
        guard let data = userDefaults.data(forKey: "quotioCLI.authorizedNativeSources.v1") else { return [] }
        return (try? JSONDecoder().decode([NativeSourcePermission].self, from: data)) ?? []
    }

    public func accountStorageRequiresAuthorization() async -> Bool { storageRequiresAuthorization }

    public func authorizeAccountStorage() async throws {
        guard let client else { throw NativeSourceAuthorizationFailure.unknown }
        do {
            try await mutate(client: client, path: "v1/account-vault/authorize", method: "POST", body: Data("{}".utf8), timeout: .seconds(300))
            storageRequiresAuthorization = false
            discoveredNativeSourceKinds = []
            await registerDetectedNativeAccounts()
        } catch {
            throw NativeSourceAuthorizationFailure.quotioVault
        }
    }

    public func accounts() async -> [Account] {
        await loadSnapshot(mode: activeMode)
        return reportedAccounts
    }

    func resolvedAccounts() async throws -> QuotioHostAccountList {
        guard let client else { throw QuotioHostClientError.disconnected }
        let result: QuotioHostAccountList = try await client.request("v2/accounts")
        guard result.schemaVersion == 2, result.host.apiVersions.contains(2) else {
            throw QuotioHostClientError.incompatible
        }
        return result
    }

    func renameResolvedAccount(id: String, userLabel: String?) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        let body = try JSONSerialization.data(withJSONObject: ["user_label": userLabel.map { $0 as Any } ?? NSNull()])
        try await mutate(client: client, path: QuotioHostAccountTarget.account(id).path, method: "PATCH", body: body)
    }

    func setResolvedEnabled(_ enabled: Bool, target: QuotioHostAccountTarget) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        let body = try JSONEncoder.quotioCLI.encode(EnabledBody(enabled: enabled))
        try await mutate(client: client, path: target.path, method: "PATCH", body: body)
    }

    func removeResolved(_ target: QuotioHostAccountTarget) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        try await mutate(client: client, path: target.path, method: "DELETE", body: nil)
    }

    public func importLegacyAccount(_ account: Account, credential: StoredCredential, disabled: Bool) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        struct Import: Encodable {
            let legacyId: String
            let provider: String
            let label: String
            let enabled: Bool
            let credential: StoredCredential
        }
        guard let domainProvider = QuotaProvider(rawValue: account.providerID.rawValue),
              let provider = QuotioCLIProviderMap.cli(domainProvider) else {
            throw QuotioHostClientError.incompatible
        }
        var credential = credential
        if domainProvider == .antigravity {
            let parameters = AntigravityAccountSwitcher.oauthClientParameters
            credential.extra["clientId"] = parameters["client_id"]
            credential.extra["clientSecret"] = parameters["client_secret"]
        }
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let seconds = date.timeIntervalSince1970
            guard seconds.isFinite, seconds >= 0, seconds < Double(Int64.max) else {
                throw QuotioHostClientError.incompatible
            }
            var container = encoder.singleValueContainer()
            try container.encode(Int64(seconds))
        }
        encoder.outputFormatting = [.sortedKeys]
        let body = try encoder.encode(Import(
            legacyId: account.id, provider: provider, label: account.accountKey,
            enabled: !disabled, credential: credential
        ))
        try await mutate(client: client, path: "v1/accounts/migrate", method: "POST", body: body,
                         idempotencyKey: "quotio-monitor-v1-" + SHA256.hash(data: Data(account.id.utf8)).map { String(format: "%02x", $0) }.joined())
    }

    public func setDisabled(_ disabled: Bool, accountID: String) async {
        guard let client else { return }
        let body = try? JSONEncoder.quotioCLI.encode(EnabledBody(enabled: !disabled))
        guard let body else { return }
        try? await mutate(
            client: client,
            path: "v2/accounts/\(accountID)",
            method: "PATCH",
            body: body
        )
    }

    public func delete(accountID: String) async throws {
        guard let client else { throw AccountServiceFailure.accountNotFound }
        do {
            try await mutate(
                client: client,
                path: "v2/accounts/\(accountID)",
                method: "DELETE",
                body: nil
            )
        } catch {
            throw Self.accountFailure(error)
        }
    }

    public func synchronizeWarpTokens(_ tokens: [WarpToken]) async throws {
        guard let client else { throw QuotioHostClientError.disconnected }
        let response: QuotioCLIAccountList = try await client.request("v1/accounts")
        guard response.schemaVersion == 1 else { throw QuotioHostClientError.incompatible }
        let existing = response.accounts.filter(QuotioCLIWarpMirror.isMirror)
        var retained = Set<String>()
        for token in tokens where token.isEnabled {
            let account = existing.first {
                QuotioCLIWarpMirror.displayLabel($0.label, provider: $0.provider)
                    .caseInsensitiveCompare(token.name) == .orderedSame
            }
            let body = try JSONEncoder.quotioCLI.encode(APIKeyBody(
                provider: account == nil ? "warp" : nil,
                label: QuotioCLIWarpMirror.storageLabel(token.name),
                apiKey: token.token
            ))
            try await mutate(
                client: client,
                path: account.map { "v1/accounts/\($0.id)" } ?? "v1/accounts",
                method: account == nil ? "POST" : "PATCH",
                body: body
            )
            if let account { retained.insert(account.id) }
        }
        for account in existing where !retained.contains(account.id) {
            try await mutate(
                client: client,
                path: "v1/accounts/\(account.id)",
                method: "DELETE",
                body: nil
            )
        }
    }

    public func saveAPIKey(
        providerID: AccountProviderID,
        label: String,
        apiKey: String,
        existingAccountID: String?
    ) async throws {
        guard let client,
              let provider = QuotaProvider(rawValue: providerID.rawValue),
              let cliProvider = QuotioCLIProviderMap.cli(provider) else {
            throw AccountServiceFailure.invalidCredential
        }
        do {
            if let id = existingAccountID {
                let host = try await client.snapshot()
                guard let account = host.accounts.first(where: { $0.id == id && $0.providerId == cliProvider }) else {
                    throw AccountServiceFailure.accountNotFound
                }
                let sources = account.sources.filter { $0.actions.contains { $0.kind == "replace_api_key" && $0.available } }
                guard sources.count == 1 else { throw AccountServiceFailure.invalidCredential }
                let body = try JSONSerialization.data(withJSONObject: ["api_key": apiKey])
                try await mutate(client: client, path: QuotioHostAccountTarget.source(sources[0].id).path, method: "PATCH", body: body)
            } else {
                let body = try JSONEncoder.quotioCLI.encode(APIKeyBody(provider: cliProvider, label: label, apiKey: apiKey))
                try await mutate(client: client, path: "v2/accounts", method: "POST", body: body)
            }
        } catch {
            throw Self.accountFailure(error)
        }
    }

    func beginOAuth(provider: String) async throws -> QuotioCLIOAuthSession {
        guard let client else { throw QuotioHostClientError.disconnected }
        let body = try JSONSerialization.data(withJSONObject: [
            "provider": provider,
            "callback_mode": "relay",
        ])
        return try await client.request(
            "v1/auth/sessions",
            method: "POST",
            body: body,
            idempotencyKey: UUID().uuidString
        )
    }

    func oauthSession(id: String) async throws -> QuotioCLIOAuthSession {
        guard let client else { throw QuotioHostClientError.disconnected }
        return try await client.request("v1/auth/sessions/\(id)")
    }

    func completeOAuth(id: String, callbackURL: String? = nil, code: String? = nil) async throws -> QuotioCLIOAuthSession {
        guard let client else { throw QuotioHostClientError.disconnected }
        var value: [String: String] = [:]
        if let callbackURL { value["callback_url"] = callbackURL }
        if let code { value["code"] = code }
        let body = try JSONSerialization.data(withJSONObject: value)
        return try await client.request(
            "v1/auth/sessions/\(id)/callback",
            method: "POST",
            body: body,
            timeout: 60
        )
    }

    func cancelOAuth(id: String) async {
        guard let client else { return }
        let _: QuotioCLIOAuthSession? = try? await client.request(
            "v1/auth/sessions/\(id)",
            method: "DELETE"
        )
    }

    private func isTracked(_ provider: QuotaProvider) -> Bool {
        trackingPreferences?.load().isEnabled(provider) != false
    }

    private func performRefresh(
        providers: [String],
        accountID: String?,
        mode: QuotaOperatingMode,
        force: Bool,
        importedAccounts: Set<String>? = nil
    ) async {
        removeDisabledProxyQuotas()
        guard let client, !providers.isEmpty, activeMode == mode else { return }
        let domainProviders = Set(providers.compactMap(QuotioCLIProviderMap.domain))
        snapshot.refreshingProviders.formUnion(domainProviders)
        publish()
        do {
            let body = try JSONEncoder.quotioCLI.encode(RefreshBody(
                providers: providers,
                accountId: accountID,
                force: force,
                disabledProxyAuthFiles: (authFileState?.disabledAuthFileNames() ?? []).sorted()
            ))
            var operation: QuotioCLIOperation = try await client.request(
                "v1/refresh",
                method: "POST",
                body: body
            )
            let deadline = ContinuousClock.now + .seconds(180)
            while operation.status == "running" {
                guard ContinuousClock.now < deadline else { throw QuotioHostClientError.timeout }
                try await Task.sleep(for: .milliseconds(300))
                operation = try await client.request("v1/operations/\(operation.id)")
            }
            guard operation.status == "completed" else {
                throw QuotioHostClientError.response(500, operation.error ?? operation.status)
            }
            await loadSnapshot(mode: mode, refreshedProviders: domainProviders, importedAccounts: importedAccounts)
        } catch {
            await logger?.write(.warning, message: "Quota refresh failed=\(Self.failureCategory(error))")
            guard activeMode == mode else { return }
            snapshot.refreshingProviders.subtract(domainProviders)
            markFailure(for: domainProviders)
        }
    }

    private func loadSnapshot(
        mode: QuotaOperatingMode,
        refreshedProviders: Set<QuotaProvider>? = nil,
        importedAccounts: Set<String>? = nil
    ) async {
        guard let client else {
            markFailure(for: refreshedProviders ?? Set(Self.supportedProviders))
            return
        }
        let requestConnection = connectionID
        let requestID = UUID()
        snapshotRequestID = requestID
        do {
            let host = try await client.snapshot()
            let localization = await localization()
            guard activeMode == mode, connectionID == requestConnection, snapshotRequestID == requestID else { return }
            var frame = host
            if let previous = hostSnapshot, previous.host.id == host.host.id {
                if host.revision < previous.revision { return }
                if host.revision == previous.revision { frame = previous }
            }
            let refreshing = snapshot.refreshingProviders
            var next = QuotioHostPresentationMapper.resolvedSnapshot(frame, bundle: localization.bundle, locale: localization.locale)
            next.refreshingProviders = refreshing.subtracting(refreshedProviders ?? [])
            let accounts = frame.accounts.compactMap(Self.resolvedAccount)
            let changed = snapshot != next || reportedAccounts != accounts
            snapshot = next
            hostSnapshot = frame
            reportedAccounts = accounts
            storageRequiresAuthorization = false
            if changed { publish() }
        } catch {
            guard activeMode == mode, connectionID == requestConnection, snapshotRequestID == requestID else { return }
            if Self.failureCategory(error) == "account_storage" { storageRequiresAuthorization = true }
            await logger?.write(.warning, message: "Quota snapshot failed=\(Self.failureCategory(error))")
            markFailure(for: refreshedProviders ?? Set(Self.supportedProviders))
        }
    }

    private func selectMode(_ mode: QuotaOperatingMode) {
        guard activeMode != mode else { return }
        activeMode = mode
        snapshot = QuotaSnapshot()
        reportedAccounts = []
        publish()
    }

    private func accountID(provider: String, accountKey: String) async -> String? {
        hostSnapshot?.accounts.first { $0.providerId == provider && $0.id == accountKey }?.id
    }

    private static func resolvedAccount(_ value: QuotioHostSnapshot.Account) -> Account? {
        guard let provider = QuotioCLIProviderMap.domain(value.providerId) else { return nil }
        func sourceKind(_ origin: String) -> AccountSource {
            switch origin {
            case "owned": .quotioKeychain
            case "borrowed_proxy": .legacyCLIProxy
            default: .nativeCredential
            }
        }
        func status(_ state: String) -> AccountStatus {
            switch state {
            case "ready": .ready
            case "disabled": .disabled
            case "needs_login": .expired
            case "needs_authorization", "unavailable": .unavailable
            default: .unknown
            }
        }
        var capabilities: Set<AccountCapability> = []
        if value.actions.contains(where: { $0.kind == "remove" && $0.available }) { capabilities.insert(.delete) }
        if value.actions.contains(where: { $0.kind == "set_enabled" && $0.available }) { capabilities.insert(.disable) }
        let editable = value.sources.filter { $0.actions.contains { $0.kind == "replace_api_key" && $0.available } }
        if editable.count == 1 { capabilities.insert(.edit) }
        let source = value.sources.first(where: \.selected) ?? value.sources.first
        return Account(
            identity: AccountIdentity(id: value.id, providerID: .init(rawValue: provider.rawValue), accountKey: value.id),
            displayName: value.displayName, source: sourceKind(source?.origin ?? ""),
            credentialReference: source?.kind, capabilities: capabilities,
            status: status(value.state), enabled: value.enabled,
            sources: value.sources.map { source in
                AccountLoginSource(accountID: source.id, source: sourceKind(source.origin), credentialReference: source.kind,
                    status: status(source.state), location: source.location)
            }
        )
    }

    private func disabledProxyAccountIDs() -> Set<String> {
        Set((authFileState?.disabledAuthFileNames() ?? []).flatMap { name in
            Self.supportedProviders.compactMap(QuotioCLIProviderMap.cli).map {
                Self.sourceID(["cli_proxy_auth_file", $0, name])
            }
        })
    }

    private func discoverNativeSource(
        client: QuotioHostHTTPClient,
        provider: String,
        kind: String,
        inspect: Bool
    ) async throws -> QuotioCLISourceDiscovery {
        let body = try JSONEncoder.quotioCLI.encode(SourceDiscoveryBody(
            provider: provider,
            kind: kind,
            inspect: inspect
        ))
        let response: QuotioCLISourceDiscovery = try await client.request(
            "v1/account-sources/discover",
            method: "POST",
            body: body
        )
        guard response.schemaVersion == 1 else { throw QuotioHostClientError.incompatible }
        return response
    }

    private func pendingNativeSources() -> [NativeSourcePermission] {
        guard let data = userDefaults.data(forKey: Self.pendingNativeSourcesKey) else { return [] }
        return (try? JSONDecoder().decode([NativeSourcePermission].self, from: data)) ?? []
    }

    private func savePendingNativeSources(_ sources: Set<NativeSourcePermission>) {
        let ordered = sources.sorted { $0.id < $1.id }
        userDefaults.set(try? JSONEncoder().encode(ordered), forKey: Self.pendingNativeSourcesKey)
    }

    private func removeDisabledProxyQuotas() {
        let excludedIDs = disabledProxyAccountIDs()
        guard !excludedIDs.isEmpty else { return }
        reportedAccounts.removeAll { excludedIDs.contains($0.id) }
        for (provider, accounts) in snapshot.accountIDs {
            for (key, id) in accounts where excludedIDs.contains(id) {
                removeQuota(for: QuotaAccountID(provider: provider, accountKey: key), mode: activeMode)
            }
        }
    }

    private static func sourceID(_ parts: [String]) -> String {
        var data = Data()
        for part in parts {
            var length = UInt64(part.utf8.count).bigEndian
            withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
            data.append(contentsOf: part.utf8)
        }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func mutate(
        client: QuotioHostHTTPClient,
        path: String,
        method: String,
        body: Data?,
        idempotencyKey: String = UUID().uuidString,
        timeout: Duration = .seconds(60)
    ) async throws {
        var operation: QuotioCLIOperation = try await client.request(
            path,
            method: method,
            body: body,
            idempotencyKey: idempotencyKey
        )
        let deadline = ContinuousClock.now + timeout
        while operation.status == "running" {
            guard ContinuousClock.now < deadline else { throw QuotioHostClientError.timeout }
            try await Task.sleep(for: .milliseconds(100))
            operation = try await client.request("v1/operations/\(operation.id)")
        }
        guard operation.status == "completed" else {
            throw QuotioHostClientError.response(500, operation.error ?? operation.status)
        }
    }

    private func markFailure(for providers: Set<QuotaProvider>) {
        guard providers.contains(where: { snapshot.issues[$0]?.kind != .failed || snapshot.issues[$0]?.reason != nil || snapshot.refreshingProviders.contains($0) }) else { return }
        let now = Date()
        snapshot.refreshingProviders.subtract(providers)
        for provider in providers {
            snapshot.issues[provider] = QuotaRefreshIssue(kind: .failed, occurredAt: now)
        }
        publish()
    }

    private func publish() {
        for continuation in continuations.values { continuation.yield(snapshot) }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }

    private static func failureCategory(_ error: Error) -> String {
        switch error {
        case QuotioHostClientError.response(_, "credential_storage_unavailable"),
             QuotioHostClientError.response(_, "account_storage_unavailable"),
             QuotioHostClientError.response(_, "account_storage_disabled"):
            "account_storage"
        case QuotioHostClientError.response(_, "duplicate_account"): "duplicate_account"
        case QuotioHostClientError.response(_, "credential_validation_failed"): "credential_validation"
        case QuotioHostClientError.response(let status, _): "http_\(status)"
        case QuotioHostClientError.timeout: "timeout"
        case QuotioHostClientError.disconnected: "disconnected"
        default: "unclassified"
        }
    }

    private static func accountFailure(_ error: Error) -> AccountServiceFailure {
        guard case let QuotioHostClientError.response(_, code) = error else {
            return .invalidCredential
        }
        switch code {
        case "account_not_found": return .accountNotFound
        case "duplicate_account": return .duplicateAccount
        case "unsupported_operation": return .deletionNotAllowed
        default: return .invalidCredential
        }
    }

    private static let supportedProviders: [QuotaProvider] = [
        .claude, .codex, .antigravity, .kiro, .copilot, .cursor, .factoryDroid,
        .devin, .grok, .openRouter, .amp, .glm, .vertex, .warp, .clinePass,
    ]
}

private extension JSONEncoder {
    static var quotioCLI: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
