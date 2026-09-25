import Foundation
import Observation
import QuotioApplication
import QuotioDomain

@MainActor
@Observable
public final class QuotaFeatureController {
    enum OAuthLaunchMode {
        case manual
        case autoOpen
    }

    public private(set) var providers: [MonitoringProvider] = []
    public private(set) var monitoringSettings: MonitoringSettings?
    public private(set) var settingsError: String?
    public private(set) var isUpdatingSettings = false
    public var trackingPreferences: ProviderTrackingPreferences {
        guard let settings = monitoringSettings else { return .init() }
        return .init(disabledProviders: Set(providers.map(\.id).filter {
            !settings.enabledProviders.contains($0.rawValue) || settings.disabledProviders.contains($0.rawValue)
        }), automaticallyDiscoverLogins: settings.automaticallyDiscoverLogins)
    }
    @ObservationIgnored private let settingsService: any MonitoringSettingsManaging
    @ObservationIgnored private var settingsRequestID = UUID()

    let quota: QuotaScreenModel
    let accounts: AccountsScreenModel
    let oauth: OAuthScreenModel
    let antigravityAccounts: AntigravityAccountScreenModel

    @ObservationIgnored private let modeManager: OperatingModeManager
    @ObservationIgnored private let menuBarSettings: MenuBarSettingsManager
    @ObservationIgnored private let notifications: any NotificationRequesting
    @ObservationIgnored private var authFiles: () -> [ManagedAuthFile]
    @ObservationIgnored private let authFileState: (any ManagedAuthFileStateRepository)?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var didChangeHandler: (@MainActor () -> Void)?

    public init(
        quota: QuotaScreenModel,
        accounts: AccountsScreenModel,
        oauth: OAuthScreenModel,
        antigravityAccounts: AntigravityAccountScreenModel,
        modeManager: OperatingModeManager,
        monitoringSettings: any MonitoringSettingsManaging,
        menuBarSettings: MenuBarSettingsManager,
        notifications: any NotificationRequesting,
        authFiles: @escaping () -> [ManagedAuthFile],
        authFileState: (any ManagedAuthFileStateRepository)? = nil
    ) {
        self.settingsService = monitoringSettings
        self.quota = quota
        self.accounts = accounts
        self.oauth = oauth
        self.antigravityAccounts = antigravityAccounts
        self.modeManager = modeManager
        self.menuBarSettings = menuBarSettings
        self.notifications = notifications
        self.authFiles = authFiles
        self.authFileState = authFileState
    }

    deinit {
        refreshTask?.cancel()
    }

    var operatingMode: QuotaOperatingMode {
        modeManager.isMonitorMode ? .monitor : .localProxy
    }

    var oauthState: QuotaOAuthState? { QuotaOAuthState(oauth.state) }

    public func setAuthFilesProvider(_ provider: @escaping () -> [ManagedAuthFile]) {
        authFiles = provider
    }

    public func setDidChangeHandler(_ handler: (@MainActor () -> Void)?) {
        didChangeHandler = handler
    }

    public func initialize() async {
        await reloadMonitoringSettings()
        await quota.bootstrap(mode: operatingMode)
        await accounts.reloadAuthFiles()
        await reloadAccounts()
        startObservingHost()
    }

    private func reloadMonitoringSettings() async {
        guard !isUpdatingSettings else { return }
        let requestID = UUID()
        settingsRequestID = requestID
        do {
            async let catalog = settingsService.monitoringProviders()
            let settings = try await settingsService.monitoringSettings()
            let descriptors = try await catalog
            guard settingsRequestID == requestID else { return }
            monitoringSettings = settings
            providers = descriptors
            settingsError = nil
        } catch {
            guard settingsRequestID == requestID else { return }
            settingsError = error.localizedDescription
        }
    }

    private func updateSettings(_ change: (inout MonitoringSettings) -> Void) async {
        guard !isUpdatingSettings, var settings = monitoringSettings else { return }
        change(&settings)
        settingsRequestID = UUID()
        isUpdatingSettings = true
        defer { isUpdatingSettings = false }
        do {
            monitoringSettings = try await settingsService.updateMonitoringSettings(settings)
            settingsError = nil
            didChangeHandler?()
        } catch {
            settingsError = error.localizedDescription
        }
    }

    public func setAutomaticDiscovery(_ enabled: Bool) async {
        await updateSettings { $0.automaticallyDiscoverLogins = enabled }
    }

    public func setRefreshInterval(_ seconds: Int) async {
        await updateSettings { $0.refreshInterval = seconds }
    }

    public func setProviderEnabled(_ enabled: Bool, provider: QuotaProvider) async {
        await updateSettings {
            if enabled {
                $0.enabledProviders.insert(provider.rawValue)
                $0.disabledProviders.remove(provider.rawValue)
            } else {
                $0.disabledProviders.insert(provider.rawValue)
            }
        }
    }

    public func refreshAll(force: Bool = false) async {
        await quota.refreshAll(
            mode: operatingMode,
            force: force
        )
        await antigravityAccounts.detectActiveAccount()
        await finishRefresh()
    }

    public func refresh(provider: QuotaProvider, force: Bool = true) async {
        guard trackingPreferences.isEnabled(provider) else { return }
        await quota.refresh(provider: provider, mode: operatingMode, force: force)
        if provider == .antigravity {
            await antigravityAccounts.detectActiveAccount()
        }
        await finishRefresh()
    }

    public func refresh(account: QuotaAccountID) async {
        guard trackingPreferences.isEnabled(account.provider) else { return }
        await quota.refresh(
            provider: account.provider,
            scope: .account(account.accountKey),
            mode: operatingMode,
            force: true
        )
        await finishRefresh()
    }

    func refreshAutoDetectedProviders() async {
        await refreshAll(force: true)
    }

    func refreshImportedIDEQuotas() async {
        for provider in [QuotaProvider.cursor, .trae] where provider.supportsQuotaOnlyMode && trackingPreferences.isEnabled(provider) {
            let keys = Set(quota.providerQuotas[provider]?.keys.map { $0 } ?? [])
            guard !keys.isEmpty else { continue }
            await quota.refresh(
                provider: provider,
                scope: .importedAccounts(keys),
                mode: operatingMode,
                force: true
            )
        }
    }

    func importIDEProvider(_ provider: QuotaProvider) async -> [String: ProviderQuota] {
        guard trackingPreferences.isEnabled(provider), provider.isImportedFromLocalIDE, provider.supportsQuotaOnlyMode else { return [:] }
        await quota.refresh(provider: provider, mode: operatingMode, force: true)
        await finishRefresh()
        return quota.providerQuotas[provider] ?? [:]
    }

    func remove(account: QuotaAccountID) async {
        if let storedAccount = accounts.accounts.first(where: {
            $0.providerID.rawValue == account.provider.rawValue && $0.accountKey == account.accountKey
        }), storedAccount.canDelete {
            if storedAccount.source == .localIDE {
                await accounts.setDisabled(false, accountID: storedAccount.id)
            } else {
                try? await accounts.delete(accountID: storedAccount.id)
            }
        }
        await quota.removeQuota(for: account, mode: operatingMode)
        await finishRefresh()
    }

    func setAccountDisabled(_ disabled: Bool, accountID: String) async {
        let account = accounts.accounts.first { $0.id == accountID }
        await accounts.setDisabled(disabled, accountID: accountID)
        if disabled, let account, let provider = QuotaProvider(rawValue: account.providerID.rawValue) {
            await quota.removeQuota(
                for: QuotaAccountID(provider: provider, accountKey: account.accountKey),
                mode: operatingMode
            )
        }
        await finishRefresh()
    }

    func saveAPIKey(
        provider: QuotaProvider,
        label: String,
        apiKey: String,
        existingAccountID: String? = nil,
        fields: [String: String] = [:]
    ) async throws {
        try await accounts.saveAPIKey(
            providerID: AccountProviderID(rawValue: provider.rawValue),
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            existingAccountID: existingAccountID,
            fields: fields
        )
        await refresh(provider: provider)
    }

    func startOAuth(
        for provider: QuotaProvider,
        method: OAuthAuthorizationMethod = .providerDefault,
        launchMode: OAuthLaunchMode = .manual
    ) async {
        await oauth.start(OAuthAuthorizationRequest(
            providerID: AccountProviderID(rawValue: provider.rawValue),
            method: method,
            automaticallyOpensBrowser: launchMode == .autoOpen
        ))
    }

    func completeMonitorOAuthCode(_ code: String, provider: QuotaProvider) async {
        guard modeManager.isMonitorMode else { return }
        await oauth.completeManualCode(code)
    }

    func cancelOAuth() {
        Task { await oauth.cancel() }
    }

    func monitorStatus(for account: Account) -> (status: String?, message: String?) {
        guard let provider = QuotaProvider(rawValue: account.providerID.rawValue) else { return (nil, nil) }
        if account.isDisabled { return ("disabled", nil) }
        let accountID = QuotaAccountID(provider: provider, accountKey: account.accountKey)
        let updated = QuotaPolicy.lastUpdated(for: accountID, in: quota.providerQuotas)
        if let issue = quota.state.accountIssues[accountID] {
            return (issue.kind == .partial ? "partial" : "failed", issue.explanation)
        }
        guard let updated else { return (nil, nil) }
        if quota.state.accountStates[accountID]?.quota == .stale {
            return (
                "outdated",
                String(format: "monitor.status.outdated".localized(), updated.formatted(date: .abbreviated, time: .shortened))
            )
        }
        return (
            "ready",
            String(format: "monitor.status.updated".localized(), updated.formatted(date: .omitted, time: .shortened))
        )
    }

    func synchronizeMenuBarSelection() {
        func canonicalItem(_ item: MenuBarQuotaItem) -> MenuBarQuotaItem {
            guard let provider = QuotaProvider(rawValue: item.provider),
                  let aliases = quota.state.accountAliases[provider] else { return item }
            var key = item.accountKey
            if provider == .codex {
                if key.hasPrefix("codex-") { key.removeFirst("codex-".count) }
                if key.hasSuffix(".json") { key.removeLast(".json".count) }
            }
            guard let canonical = aliases[key],
                  quota.providerQuotas[provider]?[canonical] != nil else { return item }
            return MenuBarQuotaItem(provider: item.provider, accountKey: canonical)
        }

        var selectedIDs = Set<String>()
        let selected = menuBarSettings.selectedItems.map(canonicalItem).filter {
            selectedIDs.insert($0.id).inserted
        }
        if selected != menuBarSettings.selectedItems {
            menuBarSettings.selectedItems = selected
        }
        let disabledItemIDs = Set(accounts.accounts.compactMap { account -> String? in
            guard account.isDisabled,
                  let provider = QuotaProvider(rawValue: account.providerID.rawValue) else { return nil }
            return MenuBarQuotaItem(
                provider: provider.rawValue,
                accountKey: account.accountKey
            ).id.lowercased()
        })
        var available: [MenuBarQuotaItem] = []
        var seen = Set<String>()
        for (provider, quotas) in quota.providerQuotas {
            for key in quotas.keys {
                let item = MenuBarQuotaItem(provider: provider.rawValue, accountKey: key)
                if !disabledItemIDs.contains(item.id.lowercased()), seen.insert(item.id).inserted {
                    available.append(item)
                }
            }
        }
        let disabledFiles = authFileState?.disabledAuthFileNames() ?? []
        for file in authFiles() where !file.disabled && !disabledFiles.contains(file.name) {
            guard let provider = file.providerID else { continue }
            let item = canonicalItem(MenuBarQuotaItem(provider: provider.rawValue, accountKey: file.menuBarAccountKey))
            if !disabledItemIDs.contains(item.id.lowercased()), seen.insert(item.id).inserted {
                available.append(item)
            }
        }
        for file in accounts.authFiles
        where file.source != .cliProxyApi || !disabledFiles.contains(file.filename) {
            guard let provider = QuotaProvider(rawValue: file.providerID.rawValue) else { continue }
            let item = canonicalItem(MenuBarQuotaItem(provider: provider.rawValue, accountKey: file.menuBarAccountKey))
            if !disabledItemIDs.contains(item.id.lowercased()), seen.insert(item.id).inserted {
                available.append(item)
            }
        }
        menuBarSettings.pruneInvalidItems(validItems: available)
        menuBarSettings.autoSelectNewAccounts(availableItems: available)
    }

    public func shutdown() async {
        refreshTask?.cancel()
        refreshTask = nil
        await quota.shutdown()
        await oauth.shutdown()
    }

    private func finishRefresh() async {
        await reloadAccounts()
        await removeDisabledMonitorQuotas()
        checkQuotaNotifications()
        synchronizeMenuBarSelection()
        didChangeHandler?()
    }

    private func reloadAccounts() async {
        await accounts.reloadAccounts()
    }

    private func removeDisabledMonitorQuotas() async {
        guard operatingMode == .monitor else { return }
        for account in accounts.accounts where account.isDisabled {
            guard let provider = QuotaProvider(rawValue: account.providerID.rawValue),
                  let quotaKey = quota.providerQuotas[provider]?.keys.first(where: {
                      $0.caseInsensitiveCompare(account.accountKey) == .orderedSame
                  }) else { continue }
            await quota.removeQuota(
                for: QuotaAccountID(provider: provider, accountKey: quotaKey),
                mode: operatingMode
            )
        }
    }

    private func startObservingHost() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled, let self else { return }
                await reloadMonitoringSettings()
                await quota.bootstrap(mode: operatingMode)
                await finishRefresh()
            }
        }
    }

    private func checkQuotaNotifications() {
        let threshold = notifications.snapshot.preferences.quotaAlertThreshold
        for (provider, accountQuotas) in quota.providerQuotas where trackingPreferences.isEnabled(provider) {
            for (account, data) in accountQuotas {
                let values = data.models.map(\.percentage).filter { $0 >= 0 }
                guard let minimum = values.min() else { continue }
                if minimum <= threshold {
                    notifications.submit(.quotaLow(
                        provider: provider.displayName,
                        account: account,
                        remainingPercent: minimum
                    ))
                } else {
                    notifications.clearQuotaNotification(
                        provider: provider.rawValue,
                        account: account
                    )
                }
            }
        }
    }


}

struct QuotaOAuthState: Identifiable, Equatable {
    let provider: QuotaProvider
    var status: OAuthStatus
    var state: String?
    var error: String?
    var authURL: String?
    var requiresManualCode = false
    var userCode: String?

    @MainActor
    init?(_ flowState: OAuthFlowState) {
        let providerID: AccountProviderID
        let prompt: OAuthPrompt?
        switch flowState {
        case .idle:
            return nil
        case .authorizing(let id):
            providerID = id
            prompt = nil
            status = .waiting
        case .awaitingUser(let id, let value):
            providerID = id
            prompt = value
            status = .polling
        case .awaitingManualCode(let id, let value, let manualState):
            requiresManualCode = true
            providerID = id
            prompt = value
            state = manualState
            status = .polling
        case .succeeded(let id, _):
            providerID = id
            prompt = nil
            status = .success
        case .failed(let id, let failure):
            providerID = id
            prompt = nil
            status = .error
            error = failure.displayMessage
        }
        guard let provider = QuotaProvider(rawValue: providerID.rawValue) else { return nil }
        self.provider = provider
        state = state ?? prompt?.userCode
        userCode = prompt?.userCode
        authURL = prompt?.authorizationURL?.absoluteString
        if error == nil {
            error = prompt?.status?.localizedText
                ?? prompt?.userCode.map { String(format: "oauth.enterDeviceCode".localizedStatic(), $0) }
        }
    }

    var id: String { provider.rawValue }

    enum OAuthStatus {
        case waiting, polling, success, error
    }
}

private extension OAuthFlowFailure {
    @MainActor
    var displayMessage: String {
        switch self {
        case .unsupportedProvider:
            "Quotio-managed login is not available for this provider."
        case .invalidResponse:
            "The OAuth provider returned an invalid response."
        case .expired:
            "The device authorization expired. Please try again."
        case .stateMismatch:
            "The OAuth callback state did not match the login request."
        case .browserOpenFailed:
            "Quotio could not open the OAuth page in your browser."
        case .proxyCLI(let status):
            status.localizedText
        case .provider(let message):
            message
        case .unknown:
            "The OAuth request failed. Please try again."
        }
    }
}

private extension OAuthPromptStatus {
    @MainActor
    var localizedText: String {
        switch self {
        case .proxyCLI(let status): status.localizedText
        case .importingQuotas: "oauth.cli.importingQuotas".localized()
        }
    }
}

private extension ProxyCLIAuthStatus {
    @MainActor
    var localizedText: String {
        switch self {
        case .authenticationCompleted:
            "oauth.cli.authenticationCompleted".localized()
        case .authenticationCancelled:
            "oauth.cli.authenticationCancelled".localized()
        case .copilotBrowserOpened(let deviceCode):
            if let deviceCode {
                String(format: "oauth.cli.copilotBrowserOpenedWithCode".localized(), deviceCode)
            } else {
                "oauth.cli.copilotBrowserOpenedWithoutCode".localized()
            }
        case .browserOpened:
            "oauth.cli.browserOpened".localized()
        case .failedToStart(let details):
            String(format: "oauth.cli.failedToStart".localized(), details)
        }
    }
}
