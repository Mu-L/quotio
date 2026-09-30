import SwiftUI

/// Provider icon and name above that provider's accounts.
struct ProviderSectionHeader: View {
    let providerID: String
    let name: String

    var body: some View {
        HStack(spacing: DS.Space.s - DS.Space.xxs) {
            ProviderIcon(providerID: providerID, size: DS.Size.sectionIcon)
            Text(name).font(DS.Typography.sectionTitle)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, DS.Space.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
#Preview("Providers", traits: .sizeThatFitsLayout) {
    VStack(spacing: DS.Space.m) {
        ProviderSectionHeader(providerID: "amp", name: "Amp")
        ProviderSectionHeader(providerID: "factory", name: "Factory Droid")
        ProviderSectionHeader(providerID: "devin-desktop", name: "Devin Desktop")
    }
    .padding()
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix { ProviderSectionHeader(providerID: "codex", name: "Codex") }
}
#endif
