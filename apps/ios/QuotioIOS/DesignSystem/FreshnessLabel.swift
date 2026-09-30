import SwiftUI

/// Relative age of an account's data ("5m ago"). Highlighted once the data is old.
struct FreshnessLabel: View {
    let date: Date?
    var isOld = false
    var style: Date.RelativeFormatStyle.UnitsStyle = .narrow
    @Environment(\.locale) private var locale

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            if let date {
                let text = min(date, context.date).formatted(Date.RelativeFormatStyle(presentation: .named, unitsStyle: style, locale: locale))
                Label {
                    Text(text)
                } icon: {
                    if isOld { Image(systemName: "clock") }
                }
                .labelStyle(.titleAndIcon)
                .font(DS.Typography.caption)
                .foregroundStyle(isOld ? AnyShapeStyle(DS.Palette.low) : AnyShapeStyle(.secondary))
                .lineLimit(1)
                .accessibilityLabel(isOld ? Text("Outdated, updated \(text)") : Text("Updated \(text)"))
            }
        }
    }
}

#if DEBUG
#Preview("States", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: DS.Space.s) {
        FreshnessLabel(date: .now.addingTimeInterval(-5))
        FreshnessLabel(date: .now.addingTimeInterval(-300))
        FreshnessLabel(date: .now.addingTimeInterval(-40 * 60), isOld: true)
        FreshnessLabel(date: .now.addingTimeInterval(-300), style: .wide)
        FreshnessLabel(date: nil)
    }
    .padding()
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix { FreshnessLabel(date: .now.addingTimeInterval(-40 * 60), isOld: true) }
}
#endif
