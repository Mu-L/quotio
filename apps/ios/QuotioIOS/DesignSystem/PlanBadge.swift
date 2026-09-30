import SwiftUI

/// Small neutral pill for the account's plan or tier.
struct PlanBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.Typography.badge)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, DS.Space.s - DS.Space.xxs)
            .padding(.vertical, DS.Space.xxs)
            .background(DS.Palette.accent.opacity(0.1), in: Capsule())
            .overlay { Capsule().strokeBorder(DS.Palette.hairline, lineWidth: DS.Size.hairline) }
            .accessibilityLabel(Text("Plan \(text)"))
    }
}

#if DEBUG
#Preview("Plans", traits: .sizeThatFitsLayout) {
    HStack { ForEach(["Megawatt", "Pro 20x", "Free", "Individual", "Standard"], id: \.self) { PlanBadge(text: $0) } }
        .padding()
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix { HStack { PlanBadge(text: "Pro 20x"); PlanBadge(text: "Megawatt") } }
}
#endif
