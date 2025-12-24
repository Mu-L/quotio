//
//  SettingsScreen.swift
//  Quotio
//

import SwiftUI
import ServiceManagement

struct SettingsScreen: View {
    @Environment(QuotaViewModel.self) private var viewModel
    
    @AppStorage("autoStartProxy") private var autoStartProxy = false
    @AppStorage("routingStrategy") private var routingStrategy = "round-robin"
    @AppStorage("requestRetry") private var requestRetry = 3
    @AppStorage("switchProjectOnQuotaExceeded") private var switchProject = true
    @AppStorage("switchPreviewModelOnQuotaExceeded") private var switchPreviewModel = true
    
    @State private var portText: String = ""
    
    var body: some View {
        Form {
            // Proxy Server
            Section {
                HStack {
                    Text("settings.port".localized())
                    Spacer()
                    TextField("settings.port".localized(), text: $portText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: portText) { _, newValue in
                            if let port = UInt16(newValue), port > 0 {
                                viewModel.proxyManager.port = port
                            }
                        }
                }
                
                LabeledContent("settings.status".localized()) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.proxyManager.proxyStatus.running ? .green : .gray)
                            .frame(width: 8, height: 8)
                        Text(viewModel.proxyManager.proxyStatus.running ? "status.running".localized() : "status.stopped".localized())
                    }
                }
                
                LabeledContent("settings.endpoint".localized()) {
                    HStack {
                        Text(viewModel.proxyManager.proxyStatus.endpoint)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        
                        Button {
                            viewModel.proxyManager.copyEndpointToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                Toggle("settings.autoStartProxy".localized(), isOn: $autoStartProxy)
            } header: {
                Label("settings.proxyServer".localized(), systemImage: "server.rack")
            } footer: {
                Text("settings.restartProxy".localized())
            }
            
            // Routing Strategy
            Section {
                Picker("settings.routingStrategy".localized(), selection: $routingStrategy) {
                    Text("settings.roundRobin".localized()).tag("round-robin")
                    Text("settings.fillFirst".localized()).tag("fill-first")
                }
                .pickerStyle(.segmented)
            } header: {
                Label("settings.routingStrategy".localized(), systemImage: "arrow.triangle.branch")
            } footer: {
                Text(routingStrategy == "round-robin"
                     ? "settings.roundRobinDesc".localized()
                     : "settings.fillFirstDesc".localized())
            }
            
            // Quota Exceeded Behavior
            Section {
                Toggle("settings.autoSwitchAccount".localized(), isOn: $switchProject)
                Toggle("settings.autoSwitchPreview".localized(), isOn: $switchPreviewModel)
            } header: {
                Label("settings.quotaExceededBehavior".localized(), systemImage: "exclamationmark.triangle")
            } footer: {
                Text("settings.quotaExceededHelp".localized())
            }
            
            // Retry Configuration
            Section {
                Stepper("settings.maxRetries".localized() + ": \(requestRetry)", value: $requestRetry, in: 0...10)
            } header: {
                Label("settings.retryConfiguration".localized(), systemImage: "arrow.clockwise")
            } footer: {
                Text("settings.retryHelp".localized())
            }
            
            // Paths
            Section {
                LabeledContent("settings.binary".localized()) {
                    PathLabel(path: viewModel.proxyManager.binaryPath)
                }
                
                LabeledContent("settings.config".localized()) {
                    PathLabel(path: viewModel.proxyManager.configPath)
                }
                
                LabeledContent("settings.authDir".localized()) {
                    PathLabel(path: viewModel.proxyManager.authDir)
                }
            } header: {
                Label("settings.paths".localized(), systemImage: "folder")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("nav.settings".localized())
        .onAppear {
            portText = String(viewModel.proxyManager.port)
        }
    }
}

// MARK: - Path Label

struct PathLabel: View {
    let path: String
    
    var body: some View {
        HStack {
            Text(path)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            
            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("settings.general".localized(), systemImage: "gearshape")
                }
            
            AboutTab()
                .tabItem {
                    Label("settings.about".localized(), systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("autoStartProxy") private var autoStartProxy = false
    
    var body: some View {
        @Bindable var lang = LanguageManager.shared
        
        Form {
            Section {
                Toggle("settings.launchAtLogin".localized(), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
                
                Toggle("settings.autoStartProxy".localized(), isOn: $autoStartProxy)
            } header: {
                Label("settings.startup".localized(), systemImage: "power")
            }
            
            Section {
                Toggle("settings.showInDock".localized(), isOn: $showInDock)
            } header: {
                Label("settings.appearance".localized(), systemImage: "macwindow")
            }
            
            Section {
                Picker(selection: Binding(
                    get: { lang.currentLanguage },
                    set: { lang.currentLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                } label: {
                    Label("settings.language".localized(), systemImage: "globe")
                }
            } header: {
                Label("settings.language".localized(), systemImage: "globe")
            } footer: {
                Text("settings.restartForEffect".localized())
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Quotio")
                .font(.title)
                .fontWeight(.bold)
            
            Text("CLIProxyAPI GUI Wrapper")
                .foregroundStyle(.secondary)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            Link("GitHub: CLIProxyAPI", destination: URL(string: "https://github.com/router-for-me/CLIProxyAPI")!)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
