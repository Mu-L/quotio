import Foundation
import QuotioDomain

public enum AccountServiceFailure: Error, Equatable, Sendable {
    case invalidCredential
    case duplicateAccount
    case accountNotFound
    case deletionNotAllowed
}

public enum NativeSourceAuthorizationFailure: Error, Equatable, Sendable {
    case quotioVault
    case nativeKeychain
    case nativeLogin
    case invalidCredential
    case timeout
    case unknown
}

public struct NativeSourcePermission: Codable, Hashable, Identifiable, Sendable {
    public let provider: QuotaProvider
    public let kind: String
    public let location: String?

    public init(provider: QuotaProvider, kind: String, location: String?) {
        self.provider = provider
        self.kind = kind
        self.location = location
    }

    public var id: String { provider.rawValue + ":" + kind + ":" + (location ?? "") }
}

public struct NativeDiscoverySnapshot: Sendable {
    public let failedProviders: Set<QuotaProvider>
    public let permissions: [NativeSourcePermission]
    public let knownSources: [NativeSourcePermission]
    public let scannedAt: [QuotaProvider: Date]

    public init(permissions: [NativeSourcePermission] = [], knownSources: [NativeSourcePermission] = [], scannedAt: [QuotaProvider: Date] = [:], failedProviders: Set<QuotaProvider> = []) {
        self.failedProviders = failedProviders
        self.permissions = permissions
        self.knownSources = knownSources
        self.scannedAt = scannedAt
    }
}

public protocol AccountManaging: Sendable {
    func registerDetectedNativeAccounts() async
    func rescanNativeAccounts(for provider: QuotaProvider) async
    func rescanAllNativeAccounts() async
    func nativeDiscoverySnapshot() async -> NativeDiscoverySnapshot
    func authorizeNativeSource(_ source: NativeSourcePermission) async throws
    func accountStorageRequiresAuthorization() async -> Bool
    func authorizeAccountStorage() async throws
    func accounts() async -> [Account]
    func setDisabled(_ disabled: Bool, accountID: String) async
    func delete(accountID: String) async throws
    func saveAPIKey(
        providerID: AccountProviderID,
        label: String,
        apiKey: String,
        existingAccountID: String?,
        fields: [String: String]
    ) async throws
}

public extension AccountManaging {
    func rescanAllNativeAccounts() async { await registerDetectedNativeAccounts() }
    func nativeDiscoverySnapshot() async -> NativeDiscoverySnapshot { .init() }
    func accountStorageRequiresAuthorization() async -> Bool { false }
    func authorizeAccountStorage() async throws { throw NativeSourceAuthorizationFailure.unknown }
}
