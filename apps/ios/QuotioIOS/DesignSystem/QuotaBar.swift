import SwiftUI
import QuotioMobile

/// Thin progress bar. An empty critical bar tints its track so 0 % still reads as red.
struct QuotaBar: View {
    /// Filled share in 0...1, or nil when the window has no value.
    let fraction: Double?
    let color: Color

    var body: some View {
        Capsule()
            .fill(fraction == 0 && color == DS.Palette.critical ? color.opacity(0.25) : DS.Palette.track)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule().fill(color)
                        .frame(width: proxy.size.width * min(max(fraction ?? 0, 0), 1))
                }
            }
            .frame(height: DS.Size.bar)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("States", traits: .sizeThatFitsLayout) {
    VStack(spacing: DS.Space.m) {
        QuotaBar(fraction: 0.74, color: DS.Palette.healthy)
        QuotaBar(fraction: 0.45, color: DS.Palette.low)
        QuotaBar(fraction: 0.12, color: DS.Palette.critical)
        QuotaBar(fraction: 0, color: DS.Palette.critical)
        QuotaBar(fraction: 0.6, color: DS.Palette.muted)
        QuotaBar(fraction: nil, color: DS.Palette.muted)
    }
    .frame(width: 200)
    .padding()
}

#Preview("Dark", traits: .sizeThatFitsLayout) {
    VStack(spacing: DS.Space.m) {
        QuotaBar(fraction: 0.74, color: DS.Palette.healthy)
        QuotaBar(fraction: 0, color: DS.Palette.critical)
    }
    .frame(width: 200)
    .padding()
    .preferredColorScheme(.dark)
}
#endif
