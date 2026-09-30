import SwiftUI

/// The single connection-problem row. Shown only when the Mac cannot be read.
struct ConnectionBanner: View {
    let title: String
    let lastSync: Date?
    let actionTitle: LocalizedStringKey
    let action: () -> Void
    let showDetails: () -> Void

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Button(action: showDetails) {
                HStack(spacing: DS.Space.m) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DS.Palette.low)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: DS.Space.xxs) {
                        Text(title).font(DS.Typography.bannerTitle).foregroundStyle(.primary)
                        if let lastSync {
                            FreshnessLabel(date: lastSync, style: .wide)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Shows details"))
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(DS.Space.m)
        .cardSurface()
    }
}

#if DEBUG
#Preview("States", traits: .sizeThatFitsLayout) {
    VStack(spacing: DS.Space.m) {
        ConnectionBanner(title: "Can't reach your Mac", lastSync: .now.addingTimeInterval(-600), actionTitle: "Retry", action: {}, showDetails: {})
        ConnectionBanner(title: "Pair this Mac again", lastSync: nil, actionTitle: "Pair again", action: {}, showDetails: {})
    }
    .padding()
    .frame(width: 390)
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix {
        ConnectionBanner(title: "Can't reach your Mac", lastSync: .now.addingTimeInterval(-600), actionTitle: "Retry", action: {}, showDetails: {})
    }
    .frame(width: 390)
}
#endif
