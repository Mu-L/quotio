import SwiftUI

/// Status dot and Mac name shown in the top bar.
struct ConnectionChip: View {
    enum State {
        case healthy, connecting, degraded, offline

        var color: Color {
            switch self {
            case .healthy: DS.Palette.healthy
            case .connecting: DS.Palette.muted
            case .degraded: DS.Palette.low
            case .offline: DS.Palette.critical
            }
        }

        var spoken: LocalizedStringKey {
            switch self {
            case .healthy: "Connected"
            case .connecting: "Connecting"
            case .degraded: "Connection problem"
            case .offline: "Offline"
            }
        }
    }

    let name: String
    let state: State

    var body: some View {
        HStack(spacing: DS.Space.s - DS.Space.xxs) {
            Circle().fill(state.color).frame(width: DS.Size.statusDot, height: DS.Size.statusDot)
            Text(name).font(DS.Typography.chip).lineLimit(1)
            Image(systemName: "chevron.down").font(DS.Typography.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(state.spoken))
        .accessibilityHint(Text("Switch computer"))
    }
}

#if DEBUG
#Preview("States", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: DS.Space.m) {
        ConnectionChip(name: "MacBook Pro", state: .healthy)
        ConnectionChip(name: "MacBook Pro", state: .connecting)
        ConnectionChip(name: "MacBook Pro", state: .degraded)
        ConnectionChip(name: "A Mac with a very long computer name", state: .offline)
    }
    .padding()
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix { ConnectionChip(name: "MacBook Pro", state: .healthy) }
}
#endif
