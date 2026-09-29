import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct QuotaDisplaySettingsSection: View {
    @Environment(MenuBarSettingsManager.self) private var settings

    private var displayModeBinding: Binding<QuotaDisplayMode> {
        Binding(
            get: { settings.quotaDisplayMode },
            set: { settings.quotaDisplayMode = $0 }
        )
    }

    private var displayStyleBinding: Binding<QuotaDisplayStyle> {
        Binding(
            get: { settings.quotaDisplayStyle },
            set: { settings.quotaDisplayStyle = $0 }
        )
    }

    var body: some View {
        Section {
            Picker("settings.quota.displayMode".localized(), selection: displayModeBinding) {
                Text("settings.quota.displayMode.used".localized()).tag(QuotaDisplayMode.used)
                Text("settings.quota.displayMode.remaining".localized()).tag(QuotaDisplayMode.remaining)
            }
            .pickerStyle(.segmented)

            Picker("settings.quota.displayStyle".localized(), selection: displayStyleBinding) {
                ForEach(QuotaDisplayStyle.allCases) { style in
                    Text(style.localizationKey.localized()).tag(style)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Label("settings.quota.display".localized(), systemImage: "percent")
        } footer: {
            Text("settings.quota.display.help".localized())
                .font(.caption)
        }
    }
}
