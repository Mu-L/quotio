import SwiftUI

/// Horizontally scrolling provider chips: All plus one chip per provider present.
struct ProviderFilterBar: View {
    struct Option: Identifiable, Hashable {
        let id: String
        let name: String
    }

    let options: [Option]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: DS.Space.s) {
                HStack(spacing: DS.Space.s) {
                    chip(id: nil) {
                        Label { Text("All") } icon: { Image(systemName: "square.grid.2x2") }
                    }
                    ForEach(options) { option in
                        chip(id: option.id) {
                            Label { Text(option.name) } icon: { ProviderIcon(providerID: option.id, size: DS.Size.sectionIcon) }
                        }
                    }
                }
                .padding(.horizontal, DS.Space.l)
                .padding(.vertical, DS.Space.xs)
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func chip(id: String?, @ViewBuilder label: () -> some View) -> some View {
        let selected = selection == id
        Button { selection = id } label: { label().font(DS.Typography.chip).lineLimit(1) }
            .buttonStyle(.glass)
            .tint(selected ? DS.Palette.accent : nil)
            .foregroundStyle(selected ? AnyShapeStyle(DS.Palette.accent) : AnyShapeStyle(.primary))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#if DEBUG
private struct FilterBarPreview: View {
    @State var selection: String? = "codex"
    var body: some View {
        ProviderFilterBar(options: [.init(id: "amp", name: "Amp"), .init(id: "antigravity", name: "Antigravity"),
                                    .init(id: "codex", name: "Codex"), .init(id: "devin-desktop", name: "Devin Desktop"),
                                    .init(id: "factory", name: "Factory Droid"), .init(id: "copilot", name: "GitHub Copilot")],
                          selection: $selection)
    }
}

#Preview("Selection", traits: .sizeThatFitsLayout) { FilterBarPreview().frame(width: 390) }

#Preview("Variants", traits: .sizeThatFitsLayout) { PreviewMatrix { FilterBarPreview() }.frame(width: 390) }
#endif
