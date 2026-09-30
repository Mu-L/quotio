import Foundation

/// How one metric renders. Mirrors the macOS mapper: percentages become tiles; amounts,
/// spend and statuses become value rows; anything else is a tile without data.
public enum MetricContent: Equatable, Sendable {
    case percent(remaining: Double)
    case amount(String)
    case spent(String)
    case status(String)
    case noData

    public var isTile: Bool {
        switch self {
        case .percent, .noData: true
        case .amount, .spent, .status: false
        }
    }
}

public extension MobileSnapshot.Metric {
    var label: String { DisplayNames.metricLabel(name) }

    var content: MetricContent { content(locale: .autoupdatingCurrent) }

    func content(locale: Locale) -> MetricContent {
        switch state {
        case "available", "exhausted":
            if let remainingPercent, remainingPercent.isFinite, (0...100).contains(remainingPercent) {
                return .percent(remaining: remainingPercent)
            }
        case "unlimited": return .status(String(localized: "Unlimited", bundle: .main))
        case "disabled": return .status(String(localized: "Disabled", bundle: .main))
        case "limit":
            if let amount {
                let cap = unit.map { QuotaFormat.amount(amount, unit: $0, locale: locale) }
                    ?? amount.formatted(.number.locale(locale))
                return .status(String(localized: "\(cap) cap", bundle: .main))
            }
        case "unknown": break
        default: return .status(String(localized: "Unsupported", bundle: .main))
        }
        if let amounts { return .amount(QuotaFormat.amount(amounts.remaining, unit: amounts.unit, locale: locale)) }
        if let used, let usedUnit {
            return .spent(String(localized: "\(QuotaFormat.amount(used, unit: usedUnit, locale: locale)) spent", bundle: .main))
        }
        return .noData
    }

    var resetHint: DisplayNames.ResetHint? { resetDescription.map(DisplayNames.resetHint) }
}

public extension MobileSnapshot.Account {
    struct TileGroup: Identifiable, Sendable {
        public let name: String?
        public let metrics: [MobileSnapshot.Metric]
        public var id: String { name ?? "" }
    }

    /// Tiles grouped by the host's `group`, in first-appearance order.
    var tileGroups: [TileGroup] {
        metrics.filter(\.content.isTile).reduce(into: [TileGroup]()) { groups, metric in
            if let index = groups.firstIndex(where: { $0.name == metric.group }) {
                groups[index] = TileGroup(name: groups[index].name, metrics: groups[index].metrics + [metric])
            } else {
                groups.append(TileGroup(name: metric.group, metrics: [metric]))
            }
        }
    }

    var valueMetrics: [MobileSnapshot.Metric] { metrics.filter { !$0.content.isTile } }

    /// Lowest remaining percent across windows, used for "low first" sorting.
    var lowestRemaining: Double? {
        metrics.compactMap { if case .percent(let value) = $0.content { value } else { nil } }.min()
    }

    var planBadge: String? {
        [plan, tier].compactMap { $0.map(DisplayNames.plan) }.first { !$0.isEmpty }
    }

    var hasData: Bool { !metrics.isEmpty }

    /// Known reason for an account without metrics; nil when the host gave none.
    var emptyReason: String? {
        guard metrics.isEmpty else { return nil }
        if !enabled { return String(localized: "Disabled on your Mac", bundle: .main) }
        if state == "needs_login" || state == "needs_authorization" { return DisplayNames.accountState(state) }
        if let issue { return DisplayNames.issue(issue) }
        if freshness == "not_loaded" { return String(localized: "Not loaded yet", bundle: .main) }
        return nil
    }

    /// Data older than this is highlighted in the freshness footer.
    static var freshnessWarningAge: TimeInterval { 15 * 60 }

    func isOld(at now: Date) -> Bool {
        isStale(at: now) || fetchedAt.map { now.timeIntervalSince($0) > Self.freshnessWarningAge } == true
    }
}

public extension MobileSnapshot {
    struct ProviderSection: Identifiable, Sendable {
        public let providerID: String
        public let providerName: String
        public let accounts: [Account]
        public var id: String { providerID }
    }

    /// Accounts grouped by provider. `order` lists provider IDs the user arranged; others
    /// follow in host order. `lowFirst` sorts by the lowest remaining window instead.
    func sections(order: [String], lowFirst: Bool, pinned: Set<String>) -> [ProviderSection] {
        var sections: [ProviderSection] = []
        for account in accounts {
            if let index = sections.firstIndex(where: { $0.providerID == account.providerID }) {
                sections[index] = ProviderSection(providerID: account.providerID, providerName: sections[index].providerName,
                                                  accounts: sections[index].accounts + [account])
            } else {
                sections.append(ProviderSection(providerID: account.providerID, providerName: account.providerName, accounts: [account]))
            }
        }
        func lowKey(_ value: Double?) -> Double { value ?? .infinity }
        sections = sections.map { section in
            let sorted = section.accounts.enumerated().sorted { lhs, rhs in
                let (l, r) = (pinned.contains(lhs.element.id), pinned.contains(rhs.element.id))
                if l != r { return l }
                if lowFirst, lowKey(lhs.element.lowestRemaining) != lowKey(rhs.element.lowestRemaining) {
                    return lowKey(lhs.element.lowestRemaining) < lowKey(rhs.element.lowestRemaining)
                }
                return lhs.offset < rhs.offset
            }.map(\.element)
            return ProviderSection(providerID: section.providerID, providerName: section.providerName, accounts: sorted)
        }
        return sections.enumerated().sorted { lhs, rhs in
            if lowFirst {
                let l = lowKey(lhs.element.accounts.compactMap(\.lowestRemaining).min())
                let r = lowKey(rhs.element.accounts.compactMap(\.lowestRemaining).min())
                if l != r { return l < r }
            } else {
                let l = order.firstIndex(of: lhs.element.providerID) ?? Int.max
                let r = order.firstIndex(of: rhs.element.providerID) ?? Int.max
                if l != r { return l < r }
            }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }
}
