import Foundation
import Observation
import QuotioApplication
import QuotioDomain

@MainActor
@Observable
public final class AccountsScreenModel {
    public private(set) var accounts: [Account] = []
    public private(set) var authFiles: [AuthFileDescriptor] = []
    public private(set) var nativeSourcePermissions: [NativeSourcePermission] = []
    public private(set) var authorizedNativeSources: [NativeSourcePermission] = []
    public private(set) var isScanningAll = false
    public private(set) var authorizingNativeSourceID: String?
    public private(set) var storageAccessRequired = false
    public private(set) var authorizingStorage = false
    public private(set) var nativeAuthorizationFailure: NativeSourceAuthorizationFailure?
    public private(set) var lastScannedAt: [QuotaProvider: Date] = [:]
    public private(set) var discoveringProvider: QuotaProvider?
    public private(set) var failure: AccountServiceFailure?

    @ObservationIgnored private var accountAliases: [QuotaProvider: [String: String]] = [:]
    @ObservationIgnored private let accountService: any AccountManaging
    @ObservationIgnored private let authFileRepository: any AuthFileRepository

    public init(
        accountService: any AccountManaging,
        authFileRepository: any AuthFileRepository
    ) {
        self.accountService = accountService
        self.authFileRepository = authFileRepository
    }

    public func reloadAccounts() async {
        accounts = canonicalized(await accountService.accounts())
        storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
    }

    public func registerDetectedNativeAccounts() async {
        await accountService.registerDetectedNativeAccounts()
        for provider in QuotaProvider.allCases where provider.hasDiscoverableNativeLogin {
            lastScannedAt[provider] = Date()
        }
        nativeSourcePermissions = await accountService.nativeSourcesRequiringPermission()
        authorizedNativeSources = await accountService.authorizedNativeSources()
        storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
    }

    public func scanAllNativeAccounts() async {
        guard !isScanningAll else { return }
        isScanningAll = true
        defer { isScanningAll = false }
        for provider in QuotaProvider.allCases where provider.hasDiscoverableNativeLogin {
            await rescanNativeAccounts(for: provider)
        }
    }

    public func rescanNativeAccounts(for provider: QuotaProvider) async {
        guard discoveringProvider == nil else { return }
        discoveringProvider = provider
        defer { discoveringProvider = nil }
        await accountService.rescanNativeAccounts(for: provider)
        lastScannedAt[provider] = Date()
        nativeSourcePermissions = await accountService.nativeSourcesRequiringPermission()
        authorizedNativeSources = await accountService.authorizedNativeSources()
        storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
        await reloadAccounts()
    }

    public func authorizeNativeSource(_ source: NativeSourcePermission) async throws {
        nativeAuthorizationFailure = nil
        authorizingNativeSourceID = source.id
        defer { authorizingNativeSourceID = nil }
        do {
            try await accountService.authorizeNativeSource(source)
        } catch {
            nativeAuthorizationFailure = error as? NativeSourceAuthorizationFailure ?? .unknown
            throw error
        }
        nativeSourcePermissions = await accountService.nativeSourcesRequiringPermission()
        authorizedNativeSources = await accountService.authorizedNativeSources()
        storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
        await reloadAccounts()
    }

    public func authorizeAccountStorage() async throws {
        guard !authorizingStorage else { return }
        authorizingStorage = true
        defer { authorizingStorage = false }
        do {
            try await accountService.authorizeAccountStorage()
            storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
            nativeSourcePermissions = await accountService.nativeSourcesRequiringPermission()
            authorizedNativeSources = await accountService.authorizedNativeSources()
            await reloadAccounts()
        } catch {
            nativeAuthorizationFailure = error as? NativeSourceAuthorizationFailure ?? .unknown
            throw error
        }
    }

    public func reloadAccounts(
        merging quotas: [QuotaProvider: [String: ProviderQuota]],
        aliases: [QuotaProvider: [String: String]] = [:]
    ) async {
        accountAliases = aliases
        accounts = AccountSelectionPolicy.mergingQuotaAccounts(
            canonicalized(await accountService.accounts()),
            quotas: quotas
        )
        storageAccessRequired = await accountService.accountStorageRequiresAuthorization()
    }

    private func canonicalized(_ candidates: [Account]) -> [Account] {
        guard !accountAliases.isEmpty else { return candidates }
        let canonical = candidates.map { account in
            guard let provider = QuotaProvider(rawValue: account.providerID.rawValue),
                  let key = accountAliases[provider]?[account.id] ?? accountAliases[provider]?[account.accountKey] else { return account }
            return Account(
                identity: AccountIdentity(id: account.id, providerID: account.providerID, accountKey: key),
                displayName: account.displayName,
                source: account.source,
                credentialReference: account.credentialReference,
                capabilities: account.capabilities,
                status: account.status,
                credentialMetadata: account.credentialMetadata,
                sources: account.sources
            )
        }
        return AccountSelectionPolicy.preferred(
            canonical,
            disabledIDs: Set(canonical.filter(\.isDisabled).map(\.id))
        )
    }

    public func reloadAuthFiles() async {
        authFiles = await authFileRepository.scanAllAuthFiles()
    }

    public func replaceAccounts(_ accounts: [Account]) {
        self.accounts = accounts
    }

    public func setDisabled(_ disabled: Bool, accountID: String) async {
        await accountService.setDisabled(disabled, accountID: accountID)
        await reloadAccounts()
    }

    public func delete(accountID: String) async throws {
        do {
            try await accountService.delete(accountID: accountID)
            await reloadAccounts()
            failure = nil
        } catch let error as AccountServiceFailure {
            failure = error
            throw error
        }
    }

    public func saveAPIKey(
        providerID: AccountProviderID,
        label: String,
        apiKey: String,
        existingAccountID: String? = nil
    ) async throws {
        do {
            try await accountService.saveAPIKey(
                providerID: providerID,
                label: label,
                apiKey: apiKey,
                existingAccountID: existingAccountID
            )
            await reloadAccounts()
            failure = nil
        } catch let error as AccountServiceFailure {
            failure = error
            throw error
        }
    }

    public func importAuthFile(from url: URL) async throws {
        let content = try await authFileRepository.readAuthFileForImport(from: url)
        try await authFileRepository.uploadAuthFile(name: url.lastPathComponent, content: content)
        await reloadAuthFiles()
    }

    public func readAuthFileForImport(from url: URL) async throws -> Data {
        try await authFileRepository.readAuthFileForImport(from: url)
    }

    public func writeDownloadedAuthFile(_ content: Data, to url: URL) async throws {
        try await authFileRepository.writeDownloadedAuthFile(content, to: url)
    }

    public func exportAuthFile(name: String, to url: URL) async throws {
        let content = try await authFileRepository.downloadAuthFile(name: name)
        try await authFileRepository.writeDownloadedAuthFile(content, to: url)
    }
}
