import Foundation
import QuotioDomain

public struct AccountMonitoringState: Equatable, Sendable {
    public let connection: ConnectionState
    public let quota: QuotaRefreshState

    public static func resolve(
        isTracked: Bool,
        hasSource: Bool,
        needsPermission: Bool,
        lastUpdated: Date?,
        issue: QuotaRefreshIssue?,
        isRefreshing: Bool,
        cadence: RefreshCadence,
        now: Date
    ) -> Self {
        let currentIssue = issue.flatMap { issue in
            lastUpdated.map { $0 > issue.occurredAt } == true ? nil : issue
        }
        let connection: ConnectionState
        if !isTracked {
            connection = .disabled
        } else if needsPermission {
            connection = .permissionRequired
        } else if currentIssue?.reason == .authentication || currentIssue?.reason == .ownerRefreshRequired {
            connection = .reauthenticationRequired
        } else {
            connection = hasSource ? .connected : .notConnected
        }

        let quota: QuotaRefreshState
        if isRefreshing {
            quota = .refreshing
        } else if let currentIssue {
            quota = .failed(currentIssue.reason)
        } else if let lastUpdated {
            quota = cadence.intervalSeconds.map { now.timeIntervalSince(lastUpdated) > 2 * $0 } == true
                ? .stale : .fresh
        } else {
            quota = .notLoaded
        }
        return Self(connection: connection, quota: quota)
    }
}

public enum QuotaRecoveryAction: Equatable, Sendable {
    case signIn
    case refreshInSourceApp
    case authorize
    case retry
}

extension QuotaRefreshFailureReason {
    public var recoveryAction: QuotaRecoveryAction? {
        switch self {
        case .authentication: .signIn
        case .ownerRefreshRequired: .refreshInSourceApp
        case .credentialStorage, .localCredentialStorage: .authorize
        case .timeout, .transient, .unavailable, .invalidData: .retry
        case .rateLimited, .quotaUnavailable, .sourceDisabled: nil
        }
    }
}
