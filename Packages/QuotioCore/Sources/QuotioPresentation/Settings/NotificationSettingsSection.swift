import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct NotificationSettingsSection: View {
    @Environment(NotificationSettingsScreenModel.self) private var notificationModel

    var body: some View {
        let preferences = notificationModel.snapshot.preferences

        Section {
            Toggle("settings.notifications.enabled".localized(), isOn: Binding(
                get: { preferences.notificationsEnabled },
                set: { enabled in
                    notificationModel.update { $0.notificationsEnabled = enabled }
                }
            ))

            if preferences.notificationsEnabled {
                Toggle("settings.notifications.quotaLow".localized(), isOn: Binding(
                    get: { preferences.notifyOnQuotaLow },
                    set: { enabled in notificationModel.update { $0.notifyOnQuotaLow = enabled } }
                ))

                Toggle("settings.notifications.cooling".localized(), isOn: Binding(
                    get: { preferences.notifyOnCooling },
                    set: { enabled in notificationModel.update { $0.notifyOnCooling = enabled } }
                ))

                Toggle("settings.notifications.proxyCrash".localized(), isOn: Binding(
                    get: { preferences.notifyOnProxyCrash },
                    set: { enabled in notificationModel.update { $0.notifyOnProxyCrash = enabled } }
                ))

                Toggle("settings.notifications.upgradeAvailable".localized(), isOn: Binding(
                    get: { preferences.notifyOnUpgradeAvailable },
                    set: { enabled in
                        notificationModel.update { $0.notifyOnUpgradeAvailable = enabled }
                    }
                ))

                HStack {
                    Text("settings.notifications.threshold".localized())
                    Spacer()
                    Picker("", selection: Binding(
                        get: { Int(preferences.quotaAlertThreshold) },
                        set: { threshold in
                            notificationModel.update { $0.quotaAlertThreshold = Double(threshold) }
                        }
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

            if notificationModel.snapshot.authorizationStatus != .authorized {
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
                .font(.caption)
        }
        .task {
            await notificationModel.refreshAuthorizationStatus()
        }
    }
}
