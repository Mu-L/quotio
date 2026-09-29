import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct AppearanceSettingsSection: View {
    @Environment(AppearanceManager.self) private var appearanceManager

    private var appearanceModeBinding: Binding<AppearanceMode> {
        Binding(
            get: { appearanceManager.appearanceMode },
            set: { appearanceManager.appearanceMode = $0 }
        )
    }

    var body: some View {
        Section {
            Picker("settings.appearance.mode".localized(), selection: appearanceModeBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.localizationKey.localized(), systemImage: mode.icon)
                        .tag(mode)
                }
            }
        } header: {
            Label("settings.appearance.title".localized(), systemImage: "paintbrush")
        } footer: {
            Text("settings.appearance.help".localized())
                .font(.caption)
        }
    }
}
