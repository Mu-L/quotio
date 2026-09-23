public struct ProviderTrackingPreferences: Equatable, Sendable {
    public var disabledProviders: Set<QuotaProvider>

    public init(disabledProviders: Set<QuotaProvider> = []) {
        self.disabledProviders = disabledProviders
    }

    public func isEnabled(_ provider: QuotaProvider) -> Bool {
        !disabledProviders.contains(provider)
    }
}
