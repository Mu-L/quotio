import SwiftUI

/// Monochrome provider mark, matching the macOS menu bar's icon choices.
struct ProviderIcon: View {
    let providerID: String
    var size: CGFloat = DS.Size.providerIcon
    @ScaledMetric(relativeTo: .subheadline) private var scale: CGFloat = 1

    var body: some View {
        Group {
            if let asset = Self.asset(for: providerID) {
                Image(asset).renderingMode(.template).resizable().scaledToFit()
            } else {
                Image(systemName: Self.symbol(for: providerID)).resizable().scaledToFit()
            }
        }
        .frame(width: size * scale, height: size * scale)
        .accessibilityHidden(true)
    }

    static func asset(for providerID: String) -> String? {
        switch providerID {
        case "claude": "claude-menubar"
        case "codex": "openai-menubar"
        case "qwen": "qwen-menubar"
        case "copilot": "copilot-menubar"
        case "antigravity": "antigravity-menubar"
        case "kiro": "kiro-menubar"
        case "iflow": "iflow-menubar"
        case "vertexai": "vertex-menubar"
        case "cursor": "cursor-menubar"
        case "factory": "factory-droid"
        case "amp": "amp-menubar"
        case "trae": "trae-menubar"
        case "zai": "glm-menubar"
        case "warp": "warp-menubar"
        case "clinepass": "clinepass-menubar"
        default: nil
        }
    }

    static func symbol(for providerID: String) -> String {
        switch providerID {
        case "devin-desktop", "devin": "bolt.horizontal.circle"
        case "grok": "xmark.circle"
        case "openrouter": "point.3.connected.trianglepath.dotted"
        default: "square.stack"
        }
    }
}

#if DEBUG
#Preview("All providers", traits: .sizeThatFitsLayout) {
    let ids = ["amp", "antigravity", "claude", "codex", "copilot", "cursor", "devin-desktop", "factory", "grok", "kiro", "openrouter", "qwen", "trae", "warp", "zai", "clinepass", "unknown"]
    LazyVGrid(columns: Array(repeating: GridItem(.fixed(DS.Space.xxl * 2)), count: 6), spacing: DS.Space.m) {
        ForEach(ids, id: \.self) { ProviderIcon(providerID: $0, size: DS.Space.xxl) }
    }
    .padding()
}

#Preview("Largest Dynamic Type · Dark", traits: .sizeThatFitsLayout) {
    HStack { ProviderIcon(providerID: "amp"); ProviderIcon(providerID: "grok") }
        .padding()
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}
#endif
