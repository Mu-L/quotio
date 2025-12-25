//
//  SettingsScreen.swift
//  Quotio
//

import SwiftUI
import ServiceManagement

struct SettingsScreen: View {
    @Environment(QuotaViewModel.self) private var viewModel
    
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("autoStartProxy") private var autoStartProxy = false
    @AppStorage("routingStrategy") private var routingStrategy = "round-robin"
    @AppStorage("requestRetry") private var requestRetry = 3
    @AppStorage("switchProjectOnQuotaExceeded") private var switchProject = true
    @AppStorage("switchPreviewModelOnQuotaExceeded") private var switchPreviewModel = true
    
    @State private var portText: String = ""
    
    var body: some View {
        @Bindable var lang = LanguageManager.shared
        
        Form {
            // General Settings
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
                
                Toggle("settings.showInDock".localized(), isOn: $showInDock)
            } header: {
                Label("settings.general".localized(), systemImage: "gearshape")
            }
            
            // Language
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
                    Text("settings.language".localized())
                }
            } header: {
                Label("settings.language".localized(), systemImage: "globe")
            } footer: {
                Text("settings.restartForEffect".localized())
            }
            
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
            
            // Notifications
            NotificationSettingsSection()
            
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

struct NotificationSettingsSection: View {
    private let notificationManager = NotificationManager.shared
    
    var body: some View {
        @Bindable var manager = notificationManager
        
        Section {
            Toggle("settings.notifications.enabled".localized(), isOn: Binding(
                get: { manager.notificationsEnabled },
                set: { manager.notificationsEnabled = $0 }
            ))
            
            if manager.notificationsEnabled {
                Toggle("settings.notifications.quotaLow".localized(), isOn: Binding(
                    get: { manager.notifyOnQuotaLow },
                    set: { manager.notifyOnQuotaLow = $0 }
                ))
                
                Toggle("settings.notifications.cooling".localized(), isOn: Binding(
                    get: { manager.notifyOnCooling },
                    set: { manager.notifyOnCooling = $0 }
                ))
                
                Toggle("settings.notifications.proxyCrash".localized(), isOn: Binding(
                    get: { manager.notifyOnProxyCrash },
                    set: { manager.notifyOnProxyCrash = $0 }
                ))
                
                HStack {
                    Text("settings.notifications.threshold".localized())
                    Spacer()
                    Picker("", selection: Binding(
                        get: { Int(manager.quotaAlertThreshold) },
                        set: { manager.quotaAlertThreshold = Double($0) }
                    )) {
                        Text("10%").tag(10)
                        Text("20%").tag(20)
                        Text("30%").tag(30)
                        Text("50%").tag(50)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                }
            }
            
            if !manager.isAuthorized {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("settings.notifications.notAuthorized".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("settings.notifications".localized(), systemImage: "bell")
        } footer: {
            Text("settings.notifications.help".localized())
        }
    }
}

// MARK: - App Settings View (Legacy - kept for compatibility)

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

// MARK: - About Screen (New Full-Page Version)

struct AboutScreen: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon and Title
                VStack(spacing: 16) {
                    if let appIcon = NSApp.applicationIconImage {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 128, height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Quotio")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("about.tagline".localized())
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 40)
                
                // Description
                Text("about.description".localized())
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 500)
                    .padding(.horizontal)
                
                // Feature Badges
                HStack(spacing: 16) {
                    FeatureBadge(
                        icon: "person.2.fill",
                        title: "about.multiAccount".localized(),
                        color: .blue
                    )
                    
                    FeatureBadge(
                        icon: "chart.bar.fill",
                        title: "about.quotaTracking".localized(),
                        color: .green
                    )
                    
                    FeatureBadge(
                        icon: "terminal.fill",
                        title: "about.agentConfig".localized(),
                        color: .purple
                    )
                }
                .padding(.vertical, 8)
                
                Divider()
                    .frame(maxWidth: 400)
                
                // Links
                VStack(spacing: 12) {
                    Link(destination: URL(string: "https://github.com/nguyenphutrong/quotio")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub: Quotio")
                        }
                        .frame(width: 200)
                    }
                    .buttonStyle(.bordered)
                    
                    Link(destination: URL(string: "https://github.com/router-for-me/CLIProxyAPI")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub: CLIProxyAPI")
                        }
                        .frame(width: 200)
                    }
                    .buttonStyle(.bordered)
                    
                    Link(destination: URL(string: "https://buymeacoffee.com/trongnguyen")!) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                            Text("about.buyMeCoffee".localized())
                        }
                        .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                
                Spacer(minLength: 40)
                
                // Credits
                Text("about.madeWith".localized())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("nav.about".localized())
    }
}

// MARK: - Feature Badge

struct FeatureBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(width: 100)
    }
}
