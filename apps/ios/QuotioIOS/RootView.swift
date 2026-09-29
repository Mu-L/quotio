import SwiftUI
import QuotioMobile

struct RootView: View {
    @Environment(HostStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var addHost = false
    @State private var accountID: String?
    @State private var computerToRemove: HostProfile?

    var body: some View {
        @Bindable var store = store
        TabView(selection: $tab) {
            Tab("Usage", systemImage: "chart.pie.fill", value: 0) {
                NavigationStack {
                    dashboard
                        .navigationTitle("Quotio")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(store.state.hideValues ? "Show values" : "Hide values", systemImage: store.state.hideValues ? "eye.slash" : "eye") {
                                    store.state.hideValues.toggle(); store.persist()
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Add computer", systemImage: "plus") { addHost = true }
                            }
                        }
                        .navigationDestination(item: $accountID) { id in
                            if let account = store.selected?.snapshot?.account(id) {
                                AccountDetail(account: account, hidden: store.state.hideValues, showUsed: store.state.showUsed)
                            } else { ContentUnavailableView("Account unavailable", systemImage: "person.crop.circle.badge.questionmark") }
                        }
                }
            }
            Tab("Widgets", systemImage: "square.grid.2x2.fill", value: 1) {
                NavigationStack { WidgetGallery().navigationTitle("Widgets") }
            }
            Tab("Settings", systemImage: "slider.horizontal.3", value: 2) {
                NavigationStack {
                    Form {
                        Section {
                            ForEach(store.state.hosts) { host in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(host.name)
                                        Text(host.origin.host ?? "").font(.caption).foregroundStyle(.secondary)
                                        if let expiration = host.expiresAt { Text("Expires \(expiration.formatted(date: .abbreviated, time: .omitted))").font(.caption) }
                                    }
                                    Spacer()
                                    Button("Remove computer", systemImage: "trash", role: .destructive) { computerToRemove = host }.labelStyle(.iconOnly)
                                }
                            }
                            Button("Add computer", systemImage: "plus") { addHost = true }
                        } header: { Text("Computers") } footer: { Text("Removing a computer deletes its saved credential on this iPhone. Revoke the device on the computer to end its access everywhere.") }
                        Section("Display") {
                            Toggle("Hide values", isOn: $store.state.hideValues).onChange(of: store.state.hideValues) { store.persist() }
                            Toggle("Show used percentage", isOn: $store.state.showUsed).onChange(of: store.state.showUsed) { store.persist() }
                        }
                        Section {
                            Text("Your provider credentials stay on your computer. Quotio connects through your local network or private VPN using HTTPS.")
                            Text("The host must be awake and running. Widgets update when iOS allows, and may show older data.")
                        }
                    }.navigationTitle("Settings")
                }
            }
        }
        .tint(.green)
        .sheet(isPresented: $addHost) { PairHostView() }
        .confirmationDialog("Remove this computer?", isPresented: Binding(
            get: { computerToRemove != nil }, set: { if !$0 { computerToRemove = nil } }
        ), titleVisibility: .visible) {
            Button("Remove computer", role: .destructive) {
                if let computerToRemove { store.remove(computerToRemove.id) }
                computerToRemove = nil
            }
            Button("Cancel", role: .cancel) { computerToRemove = nil }
        } message: {
            Text(computerToRemove?.name ?? "")
        }
        .overlay {
            if scenePhase != .active && store.state.hideValues {
                Rectangle().fill(.background).ignoresSafeArea().overlay { Label("Quotio", systemImage: "lock.fill").font(.title) }
            }
        }
        .task(id: "\(scenePhase)-\(store.state.selectedHostID ?? "")") {
            guard scenePhase == .active else { store.suspend(); return }
            while !Task.isCancelled {
                await store.refresh()
                do { try await Task.sleep(for: .seconds(store.error == nil ? 30 : 60)) }
                catch { return }
            }
        }
        .onOpenURL { url in
            guard url.scheme == "quotio", url.host == "account", let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let host = components.queryItems?.first(where: { $0.name == "host" })?.value,
                  let account = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  store.state.hosts.contains(where: { $0.id == host }) else { return }
            store.select(host); tab = 0; accountID = account
        }
    }

    @ViewBuilder private var dashboard: some View {
        if let host = store.selected {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if store.demo { Label("Demo data", systemImage: "sparkles").font(.caption).foregroundStyle(.secondary) }
                    Menu {
                        ForEach(store.state.hosts) { host in Button(host.name) { accountID = nil; store.select(host.id) } }
                    } label: { Label(host.name, systemImage: "desktopcomputer").font(.headline) }
                    if let error = store.error { Label(error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.secondary) }
                    if host.needsPairing {
                        ContentUnavailableView {
                            Label("Pair this computer again", systemImage: "lock.slash")
                        } actions: { Button("Pair again") { addHost = true } }
                    } else if let snapshot = host.snapshot {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            Label {
                                Text("Received \(snapshot.receivedAt, style: .relative) ago")
                            } icon: { Image(systemName: context.date.timeIntervalSince(snapshot.receivedAt) > 90 || store.error != nil ? "clock" : "checkmark.circle") }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        if snapshot.accounts.isEmpty { ContentUnavailableView("No accounts", systemImage: "person.crop.circle", description: Text("Add an account in Quotio on your computer.")) }
                        ForEach(snapshot.accounts.sorted { host.pinnedAccountIDs.contains($0.id) && !host.pinnedAccountIDs.contains($1.id) }) { account in
                            Button { accountID = account.id } label: {
                                AccountCard(account: account, hidden: store.state.hideValues, showUsed: store.state.showUsed)
                            }.buttonStyle(.plain)
                                .contextMenu {
                                    Button(host.pinnedAccountIDs.contains(account.id) ? "Unpin account" : "Pin account", systemImage: "pin") {
                                        guard let i = store.state.hosts.firstIndex(where: { $0.id == host.id }) else { return }
                                        if !store.state.hosts[i].pinnedAccountIDs.insert(account.id).inserted { store.state.hosts[i].pinnedAccountIDs.remove(account.id) }
                                        store.persist()
                                    }
                                }
                        }
                    }
                    Text("Reloading reads the host's latest snapshot. Quota refresh is controlled on the computer.").font(.footnote).foregroundStyle(.secondary)
                }.padding(20)
            }.background(Color(.systemGroupedBackground)).refreshable { await store.refresh() }
        } else {
            ContentUnavailableView {
                Label("Your quota, in your pocket", systemImage: "chart.pie")
            } description: {
                Text(store.error ?? String(localized: "Connect to Quotio on your computer to see usage and add widgets."))
            } actions: {
                Button("Add computer") { addHost = true }.buttonStyle(.borderedProminent)
                Button("Explore demo") { store.showDemo() }
            }
        }
    }
}
