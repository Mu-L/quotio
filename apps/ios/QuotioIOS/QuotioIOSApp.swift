import SwiftUI

@main
struct QuotioIOSApp: App {
    @State private var store = HostStore()
    var body: some Scene {
        WindowGroup { RootView().environment(store) }
    }
}
