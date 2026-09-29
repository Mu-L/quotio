import Foundation
import QuotioMobile

enum SharedContainer {
    static var storage: MobileStorage? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "QuotioAppGroup") as? String,
              let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { return nil }
        return MobileStorage(directory: directory)
    }
    static var keychain: MobileKeychain {
        MobileKeychain(accessGroup: Bundle.main.object(forInfoDictionaryKey: "QuotioKeychainGroup") as? String)
    }
}
