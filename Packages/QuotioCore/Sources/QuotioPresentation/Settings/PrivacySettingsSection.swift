import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct PrivacySettingsSection: View {
    @Environment(MenuBarSettingsManager.self) private var settings
    @Environment(TelemetryConsentScreenModel.self) private var telemetryModel

    private var hideSensitiveBinding: Binding<Bool> {
        Binding(
            get: { settings.hideSensitiveInfo },
            set: { settings.hideSensitiveInfo = $0 }
        )
    }

    private var shareAnonymousUsageBinding: Binding<Bool> {
        Binding(
            get: { telemetryModel.preferences.shareAnonymousUsage },
            set: { telemetryModel.setConsent($0) }
        )
    }

    var body: some View {
        Section {
            Toggle("settings.privacy.hideSensitive".localized(), isOn: hideSensitiveBinding)
            Toggle("settings.privacy.shareAnonymousUsage".localized(), isOn: shareAnonymousUsageBinding)
        } header: {
            Label("settings.privacy".localized(), systemImage: "eye.slash")
        } footer: {
            Text("settings.privacy.help".localized())
                .font(.caption)
        }
    }
}
