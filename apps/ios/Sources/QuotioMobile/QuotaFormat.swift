import Foundation

/// Semantic quota level. Colors are assigned by the app's design tokens.
public enum QuotaLevel: Sendable, Equatable {
    case healthy, low, critical, unknown
}

/// Number and time formatting shared by the app and widgets.
///
/// Percent rule (matches the macOS menu bar): remaining percent is truncated toward
/// zero and clamped to 0...100, so 47.9 % remaining displays as 47 %. Truncation never
/// overstates what is left. Used percent is `100 - displayed remaining`, so the two
/// modes always add up to 100.
public enum QuotaFormat {
    public static func displayRemaining(_ remaining: Double) -> Int {
        guard remaining.isFinite else { return 0 }
        return Int(min(max(remaining, 0), 100))
    }

    public static func displayPercent(remaining: Double, showUsed: Bool) -> Int {
        let value = displayRemaining(remaining)
        return showUsed ? 100 - value : value
    }

    public static func percentText(remaining: Double, showUsed: Bool, locale: Locale = .autoupdatingCurrent) -> String {
        (Double(displayPercent(remaining: remaining, showUsed: showUsed)) / 100)
            .formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    /// Thresholds use the displayed (truncated) remaining value so color and text agree:
    /// healthy > 50, low 20...50, critical < 20.
    public static func level(remaining: Double?) -> QuotaLevel {
        guard let remaining, remaining.isFinite else { return .unknown }
        let value = displayRemaining(remaining)
        if value > 50 { return .healthy }
        if value >= 20 { return .low }
        return .critical
    }

    /// Compact countdown such as "1d 1h", "4h 22m" or "12m" with localized units.
    /// Returns nil once the date has passed.
    public static func countdown(to date: Date, from now: Date, locale: Locale = .autoupdatingCurrent) -> String? {
        let seconds = date.timeIntervalSince(now)
        guard seconds > 0 else { return nil }
        let minutes = max(1, Int(seconds / 60))
        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 2).locale(locale))
    }

    /// Spoken countdown for VoiceOver, e.g. "3 days, 3 hours".
    public static func spokenCountdown(to date: Date, from now: Date, locale: Locale = .autoupdatingCurrent) -> String? {
        let seconds = date.timeIntervalSince(now)
        guard seconds > 0 else { return nil }
        let minutes = max(1, Int(seconds / 60))
        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .wide, maximumUnitCount: 2).locale(locale))
    }

    /// Formats a provider amount with locale separators. USD uses the locale's currency
    /// style (US$136.57, 136,57 US$); other known units get a localized suffix.
    public static func amount(_ value: Double, unit: String, locale: Locale = .autoupdatingCurrent) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
        switch unit.lowercased() {
        case "usd":
            return value.formatted(.currency(code: "USD").precision(.fractionLength(0...2)).locale(locale))
        case "credits":
            return String(localized: "\(number) credits", bundle: .main)
        case "requests":
            return String(localized: "\(number) requests", bundle: .main)
        case "searches":
            return String(localized: "\(number) searches", bundle: .main)
        case "hours", "hour", "h":
            return Measurement(value: value, unit: UnitDuration.hours)
                .formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0...1))).locale(locale))
        default:
            return "\(number) \(DisplayNames.prettified(unit))"
        }
    }
}
