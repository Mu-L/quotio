import SwiftUI

struct PrivacySettingsSection: View {
    @Environment(MenuBarSettingsManager.self) private var settings

    private var hideSensitiveBinding: Binding<Bool> {
        Binding(
            get: { settings.hideSensitiveInfo },
            set: { settings.hideSensitiveInfo = $0 }
        )
    }

    var body: some View {
        Section {
            Toggle("settings.privacy.hideSensitive".localized(), isOn: hideSensitiveBinding)
        } header: {
            Label("settings.privacy".localized(), systemImage: "eye.slash")
        } footer: {
            Text("settings.privacy.help".localized())
                .font(.caption)
        }
    }
}
