#if DEBUG
import SwiftUI
import QuotioMobile

/// Preview data with dates relative to now, covering every component state.
enum PreviewFixtures {
    static let now = Date()

    static func metric(_ id: String, _ name: String, _ remaining: Double?, resetIn hours: Double? = nil,
                       group: String? = nil, reset: String? = nil, amounts: MobileSnapshot.Amounts? = nil) -> MobileSnapshot.Metric {
        MobileSnapshot.Metric(id: id, name: name, state: remaining == nil ? "unknown" : (remaining == 0 ? "exhausted" : "available"),
                              remainingPercent: remaining, resetsAt: hours.map { now.addingTimeInterval($0 * 3600) },
                              resetDescription: reset, fetchedAt: now, group: group, amounts: amounts)
    }

    static func account(_ id: String, provider: String, providerName: String, name: String, identity: String? = nil,
                        plan: String? = nil, freshness: String = "fresh", age: TimeInterval = 300,
                        metrics: [MobileSnapshot.Metric], issue: String? = nil, state: String = "ready") -> MobileSnapshot.Account {
        let fetched = freshness == "not_loaded" ? nil : now.addingTimeInterval(-age)
        return MobileSnapshot.Account(id: id, providerName: providerName, providerID: provider, name: name, state: state,
                                      freshness: freshness, fetchedAt: fetched, expiresAt: fetched?.addingTimeInterval(freshness == "stale" ? -1 : 3600),
                                      plan: plan, metrics: metrics, issue: issue, identity: identity)
    }

    static let codex = account("codex", provider: "codex", providerName: "Codex", name: "phutrong.it@gmail.com", identity: "phutrong.it@gmail.com",
                               plan: "Pro 20x", metrics: [metric("weekly", "Weekly", 74, resetIn: 75),
                                                          metric("extra", "Extra Usage", nil, amounts: .init(remaining: 62_500, limit: nil, unit: "credits"))])
    static let low = account("codex-low", provider: "codex", providerName: "Codex", name: "techlead.posapp@gmail.com", identity: "techlead.posapp@gmail.com",
                             plan: "Pro 20x", metrics: [metric("weekly", "Weekly", 45, resetIn: 75), metric("session", "Session", 12, resetIn: 3.2)])
    static let amp = account("amp", provider: "amp", providerName: "Amp", name: "nguyenphutrong.dev@gmail.com", identity: "nguyenphutrong.dev@gmail.com",
                             plan: "Megawatt", metrics: [
                                metric("agent", "Agent Usage", 100, reset: "upon renewal in 18 days"),
                                metric("orb", "Orb Usage", 47.6, reset: "upon renewal in 18 days"),
                                metric("individual", "Individual credits", nil, amounts: .init(remaining: 136.57, limit: nil, unit: "USD")),
                                metric("workspace", "Workspace bytrong credits", nil, amounts: .init(remaining: 0, limit: nil, unit: "USD")),
                             ])
    static let factory = account("factory", provider: "factory", providerName: "Factory Droid", name: "nguyenphutrong.dev@gmail.com",
                                 identity: "nguyenphutrong.dev@gmail.com", metrics: [
                                    metric("s5", "5 hours", 100, group: "Standard"), metric("sw", "Weekly", 100, group: "Standard"),
                                    metric("sm", "Monthly", 74, resetIn: 551, group: "Standard"),
                                    metric("c5", "5 hours", 100, group: "Core"), metric("cw", "Weekly", 0, resetIn: 27, group: "Core"),
                                    metric("cm", "Monthly", 69, resetIn: 646, group: "Core"),
                                    metric("extra", "Extra usage credits", nil, amounts: .init(remaining: 0, limit: nil, unit: "USD")),
                                 ])
    static let antigravity = account("antigravity", provider: "antigravity", providerName: "Antigravity", name: "nguyenphutrong.dev@gmail.com",
                                     identity: "nguyenphutrong.dev@gmail.com", metrics: [
                                        metric("gw", "Gemini Models gemini-weekly", 95, resetIn: 25), metric("gs", "Gemini Models gemini-session", 80, resetIn: 4.4),
                                        metric("cw", "Claude and GPT Models claude-weekly", 100, resetIn: 167), metric("cs", "Claude and GPT Models claude-session", 100, resetIn: 4.9),
                                     ])
    static let stale = account("stale", provider: "copilot", providerName: "GitHub Copilot", name: "nguyenphutrong", identity: "nguyenphutrong",
                               plan: "individual", freshness: "stale", age: 40 * 60, metrics: [metric("premium", "Premium interactions", 100, resetIn: 30)])
    static let noData = account("kiro", provider: "kiro", providerName: "Kiro", name: "Kiro native account", freshness: "not_loaded", metrics: [])
    static let signedOut = account("grok", provider: "grok", providerName: "Grok", name: "person@example.test", identity: "person@example.test",
                                   freshness: "unavailable", metrics: [], issue: "authentication", state: "needs_login")
    static let longEmail = account("long", provider: "devin-desktop", providerName: "Devin Desktop",
                                   name: "a.really.long.email.address.for.testing@some-company-domain.example.com",
                                   identity: "a.really.long.email.address.for.testing@some-company-domain.example.com",
                                   plan: "Free", metrics: [metric("daily", "Daily", 100, resetIn: 18.2), metric("weekly", "Weekly", 100, resetIn: 90)])
}

/// Renders content in the locale, appearance and Dynamic Type combinations the
/// design system supports, stacked so one canvas shows them all.
struct PreviewMatrix<Content: View>: View {
    @ViewBuilder let content: () -> Content

    private let variants: [(String, Locale, ColorScheme, DynamicTypeSize)] = [
        ("EN · Light", Locale(identifier: "en"), .light, .large),
        ("VI · Dark", Locale(identifier: "vi"), .dark, .large),
        ("zh-Hans · Light", Locale(identifier: "zh-Hans"), .light, .large),
        ("EN · Dark · AX5", Locale(identifier: "en"), .dark, .accessibility5),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) {
                ForEach(variants, id: \.0) { name, locale, scheme, size in
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text(verbatim: name).font(.caption.monospaced()).foregroundStyle(.secondary)
                        content()
                            .padding(DS.Space.m)
                            .background(DS.Palette.background)
                            .environment(\.locale, locale)
                            .environment(\.colorScheme, scheme)
                            .dynamicTypeSize(size)
                    }
                }
            }
            .padding()
        }
    }
}
#endif
