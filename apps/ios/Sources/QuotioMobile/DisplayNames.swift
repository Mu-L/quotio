import Foundation

/// Maps provider-supplied labels and host status codes to user-facing copy.
/// Unknown values fall back to a prettified form, never a raw identifier.
public enum DisplayNames {
    /// "devin-desktop" -> "Devin Desktop", "gemini_2.5-pro" -> "Gemini 2.5 Pro".
    /// Words that already contain uppercase letters keep their casing.
    public static func prettified(_ raw: String) -> String {
        let words = raw.split(whereSeparator: { $0 == "-" || $0 == "_" || $0.isWhitespace })
        return words.map { word in
            word.contains(where: \.isUppercase) ? String(word) : word.prefix(1).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }

    // MARK: Metric labels

    enum Period: CaseIterable {
        case session, fiveHour, daily, weekly, monthly

        var title: String {
            switch self {
            case .session: String(localized: "Session", bundle: .main)
            case .fiveHour: String(localized: "5h window", bundle: .main)
            case .daily: String(localized: "Daily", bundle: .main)
            case .weekly: String(localized: "Weekly", bundle: .main)
            case .monthly: String(localized: "Monthly", bundle: .main)
            }
        }

        static func match(_ words: [String], at index: Int) -> (Period, length: Int)? {
            let word = words[index]
            if index + 1 < words.count, ["5", "five"].contains(word), ["hour", "hours"].contains(words[index + 1]) {
                return (.fiveHour, 2)
            }
            return switch word {
            case "session": (.session, 1)
            case "5h", "five-hour", "5-hour": (.fiveHour, 1)
            case "daily", "day": (.daily, 1)
            case "weekly", "week": (.weekly, 1)
            case "monthly", "month": (.monthly, 1)
            default: nil
            }
        }
    }

    private static let knownLabels: [String: String.LocalizationValue] = [
        "agent usage": "Agent usage",
        "orb usage": "Orb usage",
        "premium interactions": "Premium requests",
        "premium requests": "Premium requests",
        "chat": "Chat",
        "completions": "Completions",
        "individual credits": "Individual credits",
        "extra usage": "Extra usage",
        "extra usage credits": "Extra usage credits",
        "billing mode": "Billing mode",
    ]

    /// Words that add nothing once a period is shown: "Gemini Models gemini-weekly" -> "Gemini · Weekly".
    private static let filler: Set<String> = ["models", "model", "quota", "limit", "window", "usage"]

    public static func metricLabel(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        if let known = knownLabels[lower] { return String(localized: known, bundle: .main) }
        if lower.hasPrefix("workspace "), lower.hasSuffix(" credits") {
            let name = trimmed.dropFirst("workspace ".count).dropLast(" credits".count)
                .trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { return String(localized: "Workspace \(name) credits", bundle: .main) }
        }

        // Expand identifier tokens ("gemini-weekly") so their parts can match periods and duplicates.
        let original = trimmed.split(whereSeparator: \.isWhitespace).flatMap { token -> [Substring] in
            let isIdentifier = token.contains(where: { $0 == "-" || $0 == "_" }) && !token.contains(where: \.isUppercase)
            return isIdentifier ? token.split(whereSeparator: { $0 == "-" || $0 == "_" }) : [token]
        }.map(String.init)
        let words = original.map { $0.lowercased() }

        var period: Period?
        var subject: [String] = []
        var index = 0
        while index < words.count {
            if period == nil, let match = Period.match(words, at: index) {
                period = match.0
                index += match.length
                continue
            }
            subject.append(original[index])
            index += 1
        }
        guard let period else { return prettified(trimmed) }

        var seen = Set<String>()
        let cleaned = subject.filter { word in
            let key = word.lowercased()
            return !filler.contains(key) && seen.insert(key).inserted
        }
        guard !cleaned.isEmpty else { return period.title }
        let subjectText = cleaned.joined(separator: " ")
        return "\(subjectText.prefix(1).uppercased() + subjectText.dropFirst()) · \(period.title)"
    }

    public static func group(_ raw: String) -> String { prettified(raw) }

    // MARK: Account

    public static func plan(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed.lowercased() {
        case "free": return String(localized: "Free", bundle: .main)
        case "unknown", "": return ""
        default: return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
        }
    }

    public static func accountState(_ raw: String) -> String {
        switch raw {
        case "ready": String(localized: "Active", bundle: .main)
        case "not_checked": String(localized: "Not checked yet", bundle: .main)
        case "needs_authorization": String(localized: "Needs permission on your Mac", bundle: .main)
        case "needs_login": String(localized: "Signed out", bundle: .main)
        case "unavailable": String(localized: "Unavailable", bundle: .main)
        case "disabled": String(localized: "Disabled", bundle: .main)
        default: prettified(raw)
        }
    }

    public static func subscriptionStatus(_ raw: String) -> String {
        switch raw.lowercased() {
        case "active": String(localized: "Active", bundle: .main)
        case "canceled", "cancelled": String(localized: "Canceled", bundle: .main)
        case "past_due": String(localized: "Payment due", bundle: .main)
        case "trialing", "trial": String(localized: "Trial", bundle: .main)
        default: prettified(raw)
        }
    }

    /// Short reason for an account without quota data. `code` is the host issue code.
    public static func issue(_ code: String) -> String {
        switch code {
        case "authentication": String(localized: "Sign in again on your Mac", bundle: .main)
        case "owner_refresh_required": String(localized: "Open the provider app to refresh", bundle: .main)
        case "source_disabled": String(localized: "Source disabled", bundle: .main)
        case "timeout": String(localized: "Timed out", bundle: .main)
        case "transient", "cancelled", "internal": String(localized: "Refresh failed", bundle: .main)
        case "rate_limited": String(localized: "Rate limited by provider", bundle: .main)
        case "unavailable": String(localized: "Provider tool unavailable", bundle: .main)
        case "credential_storage", "local_credential_storage": String(localized: "Keychain access needed on your Mac", bundle: .main)
        case "quota_unavailable": String(localized: "Provider returned no quota", bundle: .main)
        case "invalid_data": String(localized: "Unreadable provider data", bundle: .main)
        default: prettified(code)
        }
    }

    // MARK: Reset descriptions

    /// Structured form of the host's `reset_description`, used when no exact reset time exists.
    public enum ResetHint: Equatable, Sendable {
        case renewal(DateComponents)
        case daily
        case periodEnds(DateComponents)
        case replenishes(rate: String)
        case other(String)
    }

    public static func resetHint(_ raw: String) -> ResetHint {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text == "daily" { return .daily }
        if text.hasPrefix("upon renewal in ") {
            let words = text.dropFirst("upon renewal in ".count).split(separator: " ")
            if words.count == 2, let count = Int(words[0]) {
                var components = DateComponents()
                switch words[1].hasSuffix("s") ? String(words[1].dropLast()) : String(words[1]) {
                case "minute": components.minute = count
                case "hour": components.hour = count
                case "day": components.day = count
                case "week": components.day = count * 7
                case "month": components.month = count
                case "year": components.year = count
                default: return .other(text)
                }
                return .renewal(components)
            }
        }
        if text.hasPrefix("billing period ends ") {
            let parts = text.dropFirst("billing period ends ".count).prefix(10).split(separator: "-").compactMap { Int($0) }
            if parts.count == 3 {
                return .periodEnds(DateComponents(year: parts[0], month: parts[1], day: parts[2]))
            }
        }
        if text.hasPrefix("replenishes ") {
            return .replenishes(rate: String(text.dropFirst("replenishes ".count)).replacingOccurrences(of: "/hour", with: ""))
        }
        return .other(text)
    }

    /// Short text for a quota tile's countdown slot, e.g. "18d" or "Daily".
    public static func shortReset(_ hint: ResetHint, locale: Locale = .autoupdatingCurrent) -> String? {
        switch hint {
        case .renewal(let components): durationText(components, style: .abbreviated, locale: locale)
        case .daily: String(localized: "Daily", bundle: .main)
        case .periodEnds(let components):
            Calendar.current.date(from: components)?.formatted(.dateTime.month(.abbreviated).day().locale(locale))
        case .replenishes(let rate): String(localized: "+\(rate)/h", bundle: .main)
        case .other: nil
        }
    }

    /// Full sentence for detail screens and VoiceOver.
    public static func longReset(_ hint: ResetHint, locale: Locale = .autoupdatingCurrent) -> String {
        switch hint {
        case .renewal(let components):
            let duration = durationText(components, style: .full, locale: locale) ?? ""
            return String(localized: "Resets on renewal in \(duration)", bundle: .main)
        case .daily: return String(localized: "Resets daily", bundle: .main)
        case .periodEnds(let components):
            let date = Calendar.current.date(from: components)?.formatted(.dateTime.year().month(.abbreviated).day().locale(locale)) ?? ""
            return String(localized: "Billing period ends \(date)", bundle: .main)
        case .replenishes(let rate): return String(localized: "Replenishes \(rate) per hour", bundle: .main)
        case .other(let text): return text.prefix(1).uppercased() + text.dropFirst()
        }
    }

    private static func durationText(_ components: DateComponents, style: DateComponentsFormatter.UnitsStyle, locale: Locale) -> String? {
        let formatter = DateComponentsFormatter()
        var calendar = Calendar.current
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = style
        formatter.maximumUnitCount = 1
        return formatter.string(from: components)
    }
}
