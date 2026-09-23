import Foundation
import QuotioApplication
import QuotioDomain

public final class UserDefaultsProviderTrackingPreferencesRepository: ProviderTrackingPreferencesRepository, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> ProviderTrackingPreferences {
        ProviderTrackingPreferences(disabledProviders: Set(
            (defaults.stringArray(forKey: "disabledProviders") ?? []).compactMap(QuotaProvider.init(rawValue:))
        ), automaticallyDiscoverLogins: defaults.object(forKey: "automaticallyDiscoverLogins") as? Bool ?? true)
    }

    public func save(_ preferences: ProviderTrackingPreferences) {
        defaults.set(preferences.automaticallyDiscoverLogins, forKey: "automaticallyDiscoverLogins")
        defaults.set(preferences.disabledProviders.map(\.rawValue).sorted(), forKey: "disabledProviders")
    }
}
