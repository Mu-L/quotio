//
//  QuotioApp.swift
//  Quotio - CLIProxyAPI GUI Wrapper
//

import SwiftUI
import ServiceManagement

@main
struct QuotioApp: App {
    @State private var viewModel = QuotaViewModel()
    @AppStorage("autoStartProxy") private var autoStartProxy = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        Window("Quotio", id: "main") {
            ContentView()
                .environment(viewModel)
                .task {
                    if autoStartProxy && viewModel.proxyManager.isBinaryInstalled {
                        await viewModel.startProxy()
                    }
                }
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        
        #if os(macOS)
        MenuBarExtra {
            MenuBarView()
                .environment(viewModel)
        } label: {
            MenuBarLabel(
                isRunning: viewModel.proxyManager.proxyStatus.running,
                readyAccounts: viewModel.readyAccounts,
                totalAccounts: viewModel.totalAccounts
            )
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    let isRunning: Bool
    let readyAccounts: Int
    let totalAccounts: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isRunning ? "gauge.with.dots.needle.67percent" : "gauge.with.dots.needle.0percent")
                .symbolRenderingMode(.hierarchical)
        }
    }
}

struct ContentView: View {
    @Environment(QuotaViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        
        NavigationSplitView {
            // Sidebar - automatically gets Liquid Glass
            List(selection: $vm.currentPage) {
                Section {
                    Label("nav.dashboard".localized(), systemImage: "gauge.with.dots.needle.33percent")
                        .tag(NavigationPage.dashboard)
                    
                    Label("nav.quota".localized(), systemImage: "chart.bar.fill")
                        .tag(NavigationPage.quota)
                    
                    Label("nav.providers".localized(), systemImage: "person.2.badge.key")
                        .tag(NavigationPage.providers)
                    
                    Label("nav.agents".localized(), systemImage: "terminal")
                        .tag(NavigationPage.agents)
                    
                    Label("nav.apiKeys".localized(), systemImage: "key.horizontal")
                        .tag(NavigationPage.apiKeys)
                    
                    Label("nav.logs".localized(), systemImage: "doc.text")
                        .tag(NavigationPage.logs)
                    
                    Label("nav.settings".localized(), systemImage: "gearshape")
                        .tag(NavigationPage.settings)
                    
                    Label("nav.about".localized(), systemImage: "info.circle")
                        .tag(NavigationPage.about)
                }
                
                Section {
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(viewModel.proxyManager.proxyStatus.running ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(viewModel.proxyManager.proxyStatus.running ? "status.running".localized() : "status.stopped".localized())
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(":\(viewModel.proxyManager.port)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Quotio")
            .toolbar {
                ToolbarItem {
                    if viewModel.proxyManager.isStarting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            Task { await viewModel.toggleProxy() }
                        } label: {
                            Image(systemName: viewModel.proxyManager.proxyStatus.running ? "stop.fill" : "play.fill")
                        }
                        .help(viewModel.proxyManager.proxyStatus.running ? "action.stopProxy".localized() : "action.startProxy".localized())
                    }
                }
            }
        } detail: {
            // Detail view - standard content area
            switch viewModel.currentPage {
            case .dashboard:
                DashboardScreen()
            case .quota:
                QuotaScreen()
            case .providers:
                ProvidersScreen()
            case .agents:
                AgentSetupScreen()
            case .apiKeys:
                APIKeysScreen()
            case .logs:
                LogsScreen()
            case .settings:
                SettingsScreen()
            case .about:
                AboutScreen()
            }
        }
    }
}
