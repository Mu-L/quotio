//
//  QuotioApp.swift
//  Quotio - CLIProxyAPI GUI Wrapper
//

import QuotioPresentation
import SwiftUI

@main
struct QuotioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var showOnboarding = false
    @Environment(\.openWindow) private var openWindow

    private var runtime: AppRuntime { appDelegate.runtime }
    private var proxyManagement: ProxyManagementScreenModel { runtime.proxyManagement }
    private var quotaScreenModel: QuotaScreenModel { runtime.quotaScreenModel }
    private var menuBarSettings: MenuBarSettingsManager { runtime.menuBarSettings }
    private var statusBarManager: StatusBarManager { runtime.statusBarManager }
    private var modeManager: OperatingModeManager { runtime.modeManager }
    private var appearanceManager: AppearanceManager { runtime.appearanceManager }
    private var languageManager: LanguageManager { runtime.languageManager }

    var body: some Scene {
        Window("Quotio", id: "main") {
            if AppEnvironment.isRunningUnitTests {
                EmptyView()
            } else {
                configured(RootNavigationView(logsScreenModel: runtime.logsScreenModel))
                    .task {
                        await runtime.initializeIfNeeded()
                        showOnboarding = runtime.needsOnboarding
                    }
                    .onChange(of: proxyManagement.directAuthFiles.count) {
                        runtime.updateStatusBar()
                        statusBarManager.rebuildMenuInPlace()
                    }
                    .sheet(isPresented: $showOnboarding) {
                        OnboardingFlow { mode in
                            Task {
                                await runtime.completeOnboarding(mode: mode)
                            }
                        }
                        .environment(runtime.providerImageModel)
                        .environment(runtime.accountsScreenModel)
                    }
            }
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("nav.about".localized()) { openWindow(id: "about") }
            }

            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    runtime.checkForUpdates()
                }
                .disabled(!runtime.canCheckForUpdates)
            }
        }
        Settings {
            if !AppEnvironment.isRunningUnitTests {
                configured(SettingsScreen())
                    .frame(width: 640, height: 600)
            }
        }
        Window("nav.about".localized(), id: "about") {
            if !AppEnvironment.isRunningUnitTests {
                configured(AboutScreen())
                    .frame(minWidth: 520, minHeight: 480)
            }
        }
        .defaultSize(width: 600, height: 650)
    }
    private func configured<Content: View>(_ content: Content) -> some View {
        content
            .id(runtime.languageManager.currentLanguage)
            .environment(runtime.proxyManagement)
            .environment(runtime.quotaController)
            .environment(runtime.quotaScreenModel)
            .environment(runtime.accountsScreenModel)
            .environment(runtime.dashboardScreenModel)
            .environment(runtime.providersScreenModel)
            .environment(runtime.warpTokenScreenModel)
            .environment(runtime.navigationScreenModel)
            .environment(runtime.warmupScreenModel)
            .environment(runtime.ideImportScreenModel)
            .environment(runtime.antigravityAccountScreenModel)
            .environment(runtime.modeManager)
            .environment(runtime.menuBarSettings)
            .environment(runtime.appearanceManager)
            .environment(runtime.languageManager)
            .environment(runtime.settingsScreenModel)
            .environment(runtime.refreshSettings)
            .environment(runtime.warmupSettings)
            .environment(runtime.ideScanSettings)
            .environment(runtime.launchAtLoginModel)
            .environment(runtime.applicationUpdateModel)
            .environment(runtime.notificationSettingsModel)
            .environment(runtime.telemetryConsentModel)
            .environment(runtime.credentialMigrationModel)
            .environment(runtime.providerImageModel)
            .environment(runtime.platformActions)
            .environment(runtime.pasteboard)
            .environment(\.locale, runtime.languageManager.locale)
    }

}
