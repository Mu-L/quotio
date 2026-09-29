import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct UsageDisplaySettingsSection: View {
    @Environment(MenuBarSettingsManager.self) private var settings

    private var totalUsageModeBinding: Binding<TotalUsageMode> {
        Binding(
            get: { settings.totalUsageMode },
            set: { settings.totalUsageMode = $0 }
        )
    }

    private var modelAggregationModeBinding: Binding<ModelAggregationMode> {
        Binding(
            get: { settings.modelAggregationMode },
            set: { settings.modelAggregationMode = $0 }
        )
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("settings.usageDisplay.totalMode.title".localized())
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("", selection: totalUsageModeBinding) {
                    ForEach(TotalUsageMode.allCases) { mode in
                        Text(mode.localizationKey.localized()).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text("settings.usageDisplay.totalMode.description".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("settings.usageDisplay.modelAggregation.title".localized())
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("", selection: modelAggregationModeBinding) {
                    ForEach(ModelAggregationMode.allCases) { mode in
                        Text(mode.localizationKey.localized()).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text("settings.usageDisplay.modelAggregation.description".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Label("settings.usageDisplay.title".localized(), systemImage: "chart.bar.doc.horizontal")
        } footer: {
            Text("settings.usageDisplay.description".localized())
                .font(.caption)
        }
    }
}
