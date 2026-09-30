import Foundation
import QuotioHostClient

public struct MobileSnapshot: Codable, Sendable {
    public struct Amounts: Codable, Sendable, Equatable {
        public let remaining: Double
        public let limit: Double?
        public let unit: String

        public init(remaining: Double, limit: Double?, unit: String) {
            self.remaining = remaining; self.limit = limit; self.unit = unit
        }
    }
    /// New fields are optional so snapshots cached by older builds still decode.
    public struct Metric: Codable, Sendable, Identifiable {
        public let id: String
        public let name: String
        public let state: String
        public let remainingPercent: Double?
        public let amount: Double?
        public let unit: String?
        public let used: Double?
        public let resetsAt: Date?
        public let resetDescription: String?
        public let fetchedAt: Date
        public let group: String?
        public let note: String?
        public let amounts: Amounts?
        public let usedUnit: String?

        public init(id: String, name: String, state: String, remainingPercent: Double? = nil,
                    amount: Double? = nil, unit: String? = nil, used: Double? = nil, usedUnit: String? = nil,
                    resetsAt: Date? = nil, resetDescription: String? = nil, fetchedAt: Date,
                    group: String? = nil, note: String? = nil, amounts: Amounts? = nil) {
            self.id = id; self.name = name; self.state = state; self.remainingPercent = remainingPercent
            self.amount = amount; self.unit = unit; self.used = used; self.usedUnit = usedUnit
            self.resetsAt = resetsAt; self.resetDescription = resetDescription; self.fetchedAt = fetchedAt
            self.group = group; self.note = note; self.amounts = amounts
        }
    }
    public struct Day: Codable, Sendable, Identifiable {
        public let date: String
        public let tokens: UInt64
        public var id: String { date }
    }
    public struct Analytics: Codable, Sendable {
        public let days: [Day]
        public let latest30BucketsTokens: UInt64
        public let lifetimeTokens: UInt64?
        public let peakDailyTokens: UInt64?
        public let longestRunningTurnSeconds: UInt64?
        public let currentStreakDays: UInt64?
        public let longestStreakDays: UInt64?
        public let fetchedAt: Date
    }
    public struct Account: Codable, Sendable, Identifiable {
        public let id: String
        public let providerName: String
        public let providerID: String
        public let name: String
        public let enabled: Bool
        public let state: String
        public let freshness: String
        public let fetchedAt: Date?
        public let expiresAt: Date?
        public let plan: String?
        public let metrics: [Metric]
        public let analytics: Analytics?
        public let resetCount: UInt64?
        public let resetExpirations: [Date]
        public let issue: String?
        public let sourceStates: [String]
        /// Verified or local email/username; nil when the host has no identity for the account.
        public let identity: String?
        /// Subscription tier name for providers that report it separately from `plan`.
        public let tier: String?
        public let subscriptionStatus: String?

        public init(id: String, providerName: String, providerID: String, name: String, enabled: Bool = true,
                    state: String = "ready", freshness: String, fetchedAt: Date?, expiresAt: Date? = nil,
                    plan: String? = nil, metrics: [Metric], analytics: Analytics? = nil, resetCount: UInt64? = nil,
                    resetExpirations: [Date] = [], issue: String? = nil, sourceStates: [String] = [],
                    identity: String? = nil, tier: String? = nil, subscriptionStatus: String? = nil) {
            self.id = id; self.providerName = providerName; self.providerID = providerID; self.name = name
            self.enabled = enabled; self.state = state; self.freshness = freshness; self.fetchedAt = fetchedAt
            self.expiresAt = expiresAt; self.plan = plan; self.metrics = metrics; self.analytics = analytics
            self.resetCount = resetCount; self.resetExpirations = resetExpirations; self.issue = issue
            self.sourceStates = sourceStates; self.identity = identity; self.tier = tier
            self.subscriptionStatus = subscriptionStatus
        }

        public func availableResets(at now: Date) -> UInt64? {
            resetCount.map { count in count - min(count, UInt64(resetExpirations.filter { $0 <= now }.count)) }
        }

        /// Data the host marked stale, or fresh data whose host TTL has since passed.
        /// Accounts that never loaded are "no data", not stale.
        public func isStale(at now: Date) -> Bool {
            freshness == "stale" || (freshness == "fresh" && expiresAt.map { $0 <= now } == true)
        }
    }
    public let hostID: String
    public let platform: String
    public let revision: UInt64
    public let receivedAt: Date
    public let accounts: [Account]
    public let redirects: [String: String]

    public init(_ snapshot: QuotioHostSnapshot, receivedAt: Date = .now, providerNames: [String: String] = [:]) {
        hostID = snapshot.host.id
        platform = snapshot.host.platform
        revision = snapshot.revision
        self.receivedAt = receivedAt
        redirects = snapshot.accountRedirects ?? [:]
        accounts = snapshot.accounts.map { account in
            let usage = snapshot.usage.first { $0.accountId == account.id }
            return Account(
                id: account.id, providerName: providerNames[account.providerId] ?? DisplayNames.prettified(account.providerId), providerID: account.providerId, name: account.displayName,
                enabled: account.enabled, state: account.state,
                freshness: usage?.freshness ?? "not_loaded", fetchedAt: usage?.fetchedAt,
                expiresAt: usage?.expiresAt, plan: usage?.plan,
                metrics: (usage?.metrics ?? []).map {
                    Metric(id: $0.id, name: $0.displayName, state: $0.quota.state,
                           remainingPercent: $0.quota.remainingPercent,
                           amount: $0.quota.amount, unit: $0.quota.unit,
                           used: $0.consumption?.used, usedUnit: $0.consumption?.unit, resetsAt: $0.resetsAt,
                           resetDescription: $0.resetDescription, fetchedAt: $0.fetchedAt,
                           group: $0.group, note: $0.note,
                           amounts: $0.amounts.map { Amounts(remaining: $0.remaining, limit: $0.limit, unit: $0.unit) })
                },
                analytics: usage?.codexProfile.map {
                    Analytics(days: $0.dailyUsage.map { Day(date: $0.date, tokens: $0.tokens) },
                              latest30BucketsTokens: $0.latest30BucketsTokens,
                              lifetimeTokens: $0.lifetimeTokens, peakDailyTokens: $0.peakDailyTokens,
                              longestRunningTurnSeconds: $0.longestRunningTurnSeconds,
                              currentStreakDays: $0.currentStreakDays, longestStreakDays: $0.longestStreakDays,
                              fetchedAt: $0.fetchedAt)
                },
                resetCount: usage?.codexResetCredits?.availableCount ?? usage?.resetCredits?.availableCount,
                resetExpirations: usage?.codexResetCredits?.credits.compactMap(\.expiresAt) ?? [],
                issue: usage?.issue?.code,
                sourceStates: account.sources.map(\.state),
                identity: account.identity.email ?? account.identity.username,
                tier: usage?.antigravitySubscription.flatMap { ($0.paidTier ?? $0.currentTier)?.name },
                subscriptionStatus: usage?.subscriptionStatus)
        }
    }

    public func account(_ id: String) -> Account? {
        accounts.first { $0.id == (redirects[id] ?? id) }
    }
}

public struct HostProfile: Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var origin: URL
    public var clientID: String
    public var expiresAt: Date?
    public var snapshot: MobileSnapshot?
    public var certificate: Data?
    public var needsPairing: Bool = false
    public var pinnedAccountIDs: Set<String> = []

    public init(id: String, name: String, origin: URL, clientID: String, expiresAt: Date?, snapshot: MobileSnapshot?, certificate: Data? = nil) {
        self.id = id; self.name = name; self.origin = origin; self.clientID = clientID
        self.expiresAt = expiresAt; self.snapshot = snapshot
        self.certificate = certificate
    }

    public mutating func accept(_ snapshot: MobileSnapshot) throws {
        guard snapshot.hostID == id else { throw MobileError.wrongHost }
        guard self.snapshot.map({ snapshot.revision >= $0.revision }) ?? true else { return }
        self.snapshot = snapshot
        pinnedAccountIDs = Set(pinnedAccountIDs.map { snapshot.redirects[$0] ?? $0 })
    }
}
