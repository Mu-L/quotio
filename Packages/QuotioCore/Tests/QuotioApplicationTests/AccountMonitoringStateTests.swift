import XCTest
import QuotioDomain
@testable import QuotioApplication

final class AccountMonitoringStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    func testQuotaIsStaleOnlyAfterTwoRefreshIntervals() {
        XCTAssertEqual(state(age: 120).quota, .fresh)
        XCTAssertEqual(state(age: 121).quota, .stale)
        XCTAssertEqual(state(age: 121).connection, .connected)
    }

    func testFailureAndRefreshingTakePrecedenceOverAge() {
        let issue = QuotaRefreshIssue(kind: .failed, occurredAt: now, reason: .timeout)
        XCTAssertEqual(state(age: 300, issue: issue).quota, .failed(.timeout))
        XCTAssertEqual(state(age: 300, issue: issue).connection, .connected)
        XCTAssertEqual(state(age: 300, issue: issue, refreshing: true).quota, .refreshing)
        XCTAssertEqual(state(age: 300, issue: .init(kind: .failed, occurredAt: now)).quota, .failed(nil))
    }

    func testSuccessfulRefreshSupersedesOldAuthenticationFailure() {
        let issue = QuotaRefreshIssue(kind: .failed, occurredAt: now.addingTimeInterval(-100), reason: .authentication)
        XCTAssertEqual(state(age: 10, issue: issue).connection, .connected)
        XCTAssertEqual(state(age: 10, issue: issue).quota, .fresh)
        XCTAssertEqual(state(age: 200, issue: issue).connection, .reauthenticationRequired)
    }

    func testNoQuotaAndManualRefreshDoNotInventFreshness() {
        let empty = AccountMonitoringState.resolve(
            isTracked: true, hasSource: false, needsPermission: false,
            lastUpdated: nil, issue: nil, isRefreshing: false, cadence: .manual, now: now
        )
        XCTAssertEqual(empty.connection, .notConnected)
        XCTAssertEqual(empty.quota, .notLoaded)
        XCTAssertEqual(state(age: 100_000, cadence: .manual).quota, .fresh)
    }

    func testOnlyVerifiedPermissionAndAuthenticationChangeConnection() {
        XCTAssertEqual(state(age: 10, needsPermission: true).connection, .permissionRequired)
        XCTAssertEqual(state(age: 10, needsPermission: true, isTracked: false).connection, .disabled)
        let storage = QuotaRefreshIssue(kind: .failed, occurredAt: now, reason: .credentialStorage)
        XCTAssertEqual(state(age: 10, issue: storage).connection, .connected)
        XCTAssertEqual(QuotaRefreshFailureReason.authentication.recoveryAction, .signIn)
        XCTAssertEqual(QuotaRefreshFailureReason.ownerRefreshRequired.recoveryAction, .refreshInSourceApp)
        XCTAssertEqual(QuotaRefreshFailureReason.credentialStorage.recoveryAction, .authorize)
        XCTAssertEqual(QuotaRefreshFailureReason.timeout.recoveryAction, .retry)
        XCTAssertNil(QuotaRefreshFailureReason.quotaUnavailable.recoveryAction)
        XCTAssertNil(QuotaRefreshFailureReason.rateLimited.recoveryAction)
        XCTAssertNil(QuotaRefreshFailureReason.sourceDisabled.recoveryAction)
    }

    private func state(
        age: TimeInterval, issue: QuotaRefreshIssue? = nil, refreshing: Bool = false,
        needsPermission: Bool = false, isTracked: Bool = true, cadence: RefreshCadence = .oneMinute
    ) -> AccountMonitoringState {
        .resolve(
            isTracked: isTracked, hasSource: true, needsPermission: needsPermission,
            lastUpdated: now.addingTimeInterval(-age), issue: issue,
            isRefreshing: refreshing, cadence: cadence, now: now
        )
    }
}
