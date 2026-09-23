import QuotioApplication
import QuotioDomain
import SwiftUI

public struct RootNavigationView: View {
    let logsScreenModel: LogsScreenModel

    public init(logsScreenModel: LogsScreenModel) {
        self.logsScreenModel = logsScreenModel
    }

    @Environment(NavigationScreenModel.self) private var navigation
    @Environment(ProxyManagementScreenModel.self) private var proxyManagement
    @Environment(AccountsScreenModel.self) private var accounts
    @Environment(QuotaScreenModel.self) private var quota
    @Environment(OperatingModeManager.self) private var modeManager
    @Environment(SettingsScreenModel.self) private var settingsModel
    @Environment(\.openSettings) private var openSettings
    @State private var search = ""
    @State private var showAllProviders = false

    private enum Selection: Hashable {
        case page(NavigationPage)
        case provider(QuotaProvider)
    }

    private var selection: Binding<Selection?> {
        Binding {
            navigation.selectedProvider.map(Selection.provider) ?? .page(navigation.currentPage)
        } set: { value in
            switch value {
            case .provider(let provider): navigation.selectProvider(provider)
            case .page(let page):
                navigation.selectedProvider = nil
                navigation.currentPage = page
            case nil: break
            }
        }
    }

    private var visibleProviders: [QuotaProvider] {
        let configured: Set<QuotaProvider>
        if modeManager.isMonitorMode {
            configured = Set(accounts.accounts.filter { !$0.isDisabled }.map(\.provider))
                .union(accounts.nativeSourcePermissions.map(\.provider))
        } else {
            configured = Set(proxyManagement.authFiles.compactMap(\.providerID))
                .union(proxyManagement.directAuthFiles.compactMap { QuotaProvider(rawValue: $0.providerID.rawValue) })
                .union(quota.providerQuotas.keys.filter { !$0.supportsManualAuth })
        }
        return QuotaProvider.allCases.filter {
            (!modeManager.isMonitorMode || $0.supportsQuotaOnlyMode)
                && (showAllProviders || !search.isEmpty || configured.contains($0) || navigation.selectedProvider == $0)
                && (search.isEmpty || $0.displayName.localizedCaseInsensitiveContains(search))
        }.sorted { $0.displayName < $1.displayName }
    }

    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: selection) {
                    Section {
                        Label("nav.dashboard".localized(), systemImage: "gauge.with.dots.needle.33percent")
                            .tag(Selection.page(.dashboard))
                        Label("nav.quota".localized(), systemImage: "chart.bar")
                            .tag(Selection.page(.quota))
                        Label("connections.all".localized(), systemImage: "square.grid.2x2")
                            .tag(Selection.page(.providers))
                    }
                    Section("nav.providers".localized()) {
                        ForEach(visibleProviders) { provider in
                            HStack {
                                ProviderIcon(provider: provider, size: 18)
                                Text(provider.displayName)
                                Spacer()
                                if modeManager.isMonitorMode, accounts.nativeSourcePermissions.contains(where: { $0.provider == provider }) {
                                    Image(systemName: "lock")
                                        .foregroundStyle(.orange)
                                        .accessibilityLabel("providers.nativePermission.title".localized())
                                } else if modeManager.isMonitorMode, accounts.accounts.contains(where: { $0.provider == provider && !$0.isDisabled }),
                                          quota.state.accountIssues.keys.contains(where: { $0.provider == provider })
                                            || quota.state.issues[provider] != nil {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.orange)
                                        .accessibilityLabel("connections.attention".localized())
                                }
                            }
                            .tag(Selection.provider(provider))
                        }
                        Toggle("connections.showAll".localized(), isOn: $showAllProviders)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                    }
                    if modeManager.isLocalProxyMode {
                        Section("connections.gateway".localized()) {
                            Label("nav.agents".localized(), systemImage: "terminal").tag(Selection.page(.agents))
                            Label("nav.apiKeys".localized(), systemImage: "key").tag(Selection.page(.apiKeys))
                            if settingsModel.proxyPreferences.loggingToFile {
                                Label("nav.logs".localized(), systemImage: "doc.text").tag(Selection.page(.logs))
                            }
                        }
                    }
                }
                .searchable(text: $search, placement: .sidebar, prompt: "connections.search".localized())
                Divider()
                HStack {
                    Text(modeManager.isMonitorMode ? "connections.monitor".localized() : "connections.gateway".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { openSettings() } label: { Image(systemName: "gearshape") }
                        .buttonStyle(.plain)
                        .help("nav.settings".localized())
                        .accessibilityLabel("nav.settings".localized())
                }
                .padding(12)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 235, max: 300)
        } detail: {
            switch navigation.currentPage {
            case .dashboard: DashboardScreen()
            case .quota: QuotaScreen()
            case .providers:
                ProvidersScreen(provider: navigation.selectedProvider)
                    .id(navigation.selectedProvider)
            case .agents: AgentSetupScreen()
            case .apiKeys: APIKeysScreen()
            case .logs:
                if proxyManagement.proxy.proxyStatus.running {
                    LogsScreen(model: logsScreenModel)
                } else {
                    ProxyRequiredView(description: "logs.startProxy".localized()) {
                        await proxyManagement.startProxy()
                    }
                    .navigationTitle("nav.logs".localized())
                }
            case .settings: SettingsScreen()
            case .about: AboutScreen()
            }
        }
        .onChange(of: modeManager.currentMode) {
            if modeManager.isMonitorMode {
                navigation.showProviders()
            }
        }
    }
}

struct ProxyStatusRow: View {
    let proxyManagement: ProxyManagementScreenModel

    var body: some View {
        HStack {
            if proxyManagement.proxy.isStarting {
                SmallProgressView(size: 8)
            } else {
                Circle()
                    .fill(proxyManagement.proxy.proxyStatus.running ? .green : .gray)
                    .frame(width: 8, height: 8)
            }

            Text(
                proxyManagement.proxy.isStarting
                    ? "status.starting".localized()
                    : proxyManagement.proxy.proxyStatus.running
                        ? "status.running".localized()
                        : "status.stopped".localized()
            )
            .font(.caption)

            Spacer()

            Text(":" + String(proxyManagement.proxy.port))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct QuotaRefreshStatusRow: View {
    let quota: QuotaScreenModel

    var body: some View {
        HStack {
            if quota.isLoadingQuotas {
                SmallProgressView(size: 8)
                Text("status.refreshing".localized())
                    .font(.caption)
            } else {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let lastRefresh = quota.lastRefreshTime {
                    Text("status.updatedAgo \(lastRefresh, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("status.notRefreshed".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
