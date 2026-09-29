import SwiftUI

struct WidgetGallery: View {
    @Environment(HostStore.self) private var store
    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Keep an eye on your quota from the Home Screen and Lock Screen.").foregroundStyle(.secondary)
                Picker("Percentage", selection: $store.state.showUsed) {
                    Text("Remaining").tag(false)
                    Text("Used").tag(true)
                }.pickerStyle(.segmented).onChange(of: store.state.showUsed) { store.persist() }
                Text("Home Screen").font(.title2.weight(.semibold))
                if let account = store.selected?.snapshot?.accounts.first {
                    AccountCard(account: account, hidden: store.state.hideValues, showUsed: store.state.showUsed)
                    Text("Layout preview · small, medium and large").font(.caption).foregroundStyle(.secondary)
                } else {
                    ContentUnavailableView("Connect a host first", systemImage: "square.grid.2x2", description: Text("Your accounts will be available in the widget editor after connecting."))
                }
                Text("Lock Screen").font(.title2.weight(.semibold))
                HStack(spacing: 24) {
                    Image(systemName: "gauge.with.needle").font(.largeTitle)
                    VStack(alignment: .leading) { Text("Quota at a glance").font(.headline); Text("Circular, rectangular and inline").foregroundStyle(.secondary) }
                }.padding(24).cardSurface()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add a widget").font(.headline)
                    Text("Touch and hold your Home Screen, choose Edit, then Add Widget and find Quotio. For the Lock Screen, touch and hold it, choose Customize, then Add Widgets.")
                    Text("Edit the widget to choose its host, account, quota window and percentage. Tap it to open the account in Quotio.")
                    Text("Widgets show the last available observation. iOS controls update timing; your computer and VPN must be reachable to get new data.")
                }.font(.callout).foregroundStyle(.secondary)
            }.padding(20)
        }.background(Color(.systemGroupedBackground))
    }
}
