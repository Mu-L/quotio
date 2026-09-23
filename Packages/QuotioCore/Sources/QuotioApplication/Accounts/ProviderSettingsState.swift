import Foundation
import QuotioDomain

public struct ProviderSettingsState: Sendable {
    public let provider: QuotaProvider
    public let accounts: [Account]
    public let permissions: [NativeSourcePermission]
    public let connection: ConnectionState
    public let accountStates: [String: AccountMonitoringState]
    public let latestIssue: QuotaRefreshIssue?
    public let latestIssueAccountID: String?
    public let latestIssueSourceID: String?
    public let sourceIssues: [String: QuotaRefreshIssue]

    public var needsAttention: Bool {
        connection != .disabled && (!permissions.isEmpty || latestIssue != nil)
    }

    public var isUnconnected: Bool { accounts.isEmpty && permissions.isEmpty }

    public init(
        provider: QuotaProvider, accounts: [Account], permissions: [NativeSourcePermission],
        quota: QuotaSnapshot, tracking: ProviderTrackingPreferences, cadence: RefreshCadence, now: Date
    ) {
        self.provider = provider
        self.accounts = accounts.filter { $0.providerID.rawValue == provider.rawValue }
        self.permissions = permissions.filter { $0.provider == provider }
        let tracked = tracking.isEnabled(provider)
        var states: [String: AccountMonitoringState] = [:]
        var currentIssues: [(accountID: String?, sourceID: String?, issue: QuotaRefreshIssue)] = []
        sourceIssues = quota.sourceIssues[provider] ?? [:]
        for account in self.accounts {
            let id = QuotaAccountID(provider: provider, accountKey: account.accountKey)
            let updated = quota.quotas[provider]?[account.accountKey]?.lastUpdated
            let issue = quota.accountIssues[id]
            let state = AccountMonitoringState.resolve(
                isTracked: tracked && !account.isDisabled, hasSource: !account.sources.isEmpty,
                needsPermission: false, lastUpdated: updated, issue: issue,
                isRefreshing: quota.refreshingProviders.contains(provider), cadence: cadence, now: now
            )
            states[account.id] = state
            if !account.isDisabled {
                if case .failed = state.quota, let issue { currentIssues.append((account.id, quota.accountIDs[provider]?[account.accountKey], issue)) }
                for source in account.sources {
                    if let issue = sourceIssues[source.accountID] { currentIssues.append((account.id, source.accountID, issue)) }
                }
            }
        }
        accountStates = states
        if !self.accounts.isEmpty || !self.permissions.isEmpty, let issue = quota.issues[provider] {
            currentIssues.append((nil, nil, issue))
        }
        let latest = currentIssues.max { $0.issue.occurredAt < $1.issue.occurredAt }
        latestIssue = latest?.issue
        latestIssueAccountID = latest?.accountID
        latestIssueSourceID = latest?.sourceID
        if !tracked {
            connection = .disabled
        } else if states.values.contains(where: { $0.connection == .connected }) {
            connection = .connected
        } else if !self.permissions.isEmpty {
            connection = .permissionRequired
        } else if states.values.contains(where: { $0.connection == .reauthenticationRequired }) {
            connection = .reauthenticationRequired
        } else {
            connection = .notConnected
        }
    }
}
