import XCTest
import QuotioDomain
@testable import QuotioApplication

final class ProviderSettingsStateTests: XCTestCase {
    func testConnectionIsIndependentOfProviderQuotaFailureAndDisabledAccountsRemainVisible() {
        let account = Account.make(providerID: .init(rawValue: "claude"), accountKey: "fixture", source: .nativeCredential)
        let quota = QuotaSnapshot(issues: [.claude: .init(kind: .failed, occurredAt: Date(), reason: .timeout)])
        let state = ProviderSettingsState(provider: .claude, accounts: [account], permissions: [], quota: quota,
            tracking: .init(), cadence: .oneMinute, now: Date())
        XCTAssertEqual(state.connection, .connected)
        XCTAssertEqual(state.accountStates[account.id]?.quota, .notLoaded)
        XCTAssertTrue(state.needsAttention)
        let disabled = ProviderSettingsState(provider: .claude, accounts: [account], permissions: [], quota: quota,
            tracking: .init(disabledProviders: [.claude]), cadence: .oneMinute, now: Date())
        XCTAssertEqual(disabled.connection, .disabled)
        XCTAssertEqual(disabled.accounts, [account])
        XCTAssertFalse(disabled.needsAttention)
    }

    func testUnconnectedProviderDoesNotInheritGlobalRefreshFailure() {
        let quota = QuotaSnapshot(issues: [.claude: .init(kind: .failed, occurredAt: Date(), reason: .timeout)])
        let state = ProviderSettingsState(provider: .claude, accounts: [], permissions: [], quota: quota,
            tracking: .init(), cadence: .oneMinute, now: Date())
        XCTAssertTrue(state.isUnconnected)
        XCTAssertFalse(state.needsAttention)
        XCTAssertNil(state.latestIssue)
    }

    func testPendingSourceDoesNotCountAsAnAccount() {
        let state = ProviderSettingsState(provider: .claude, accounts: [],
            permissions: [.init(provider: .claude, kind: "claude_native", location: "code_keychain")],
            quota: .init(), tracking: .init(), cadence: .oneMinute, now: Date())
        XCTAssertEqual(state.connection, .permissionRequired)
        XCTAssertTrue(state.accounts.isEmpty)
        XCTAssertFalse(state.isUnconnected)
    }
}
