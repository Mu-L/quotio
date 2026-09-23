import XCTest
import QuotioDomain
@testable import QuotioPresentation

@MainActor
final class ConnectionPresentationTests: XCTestCase {
    func testDisabledProviderStaysDisabledDespiteOldErrorsAndPendingPermission() {
        let state = ProviderConnectionState.resolve(
            hasAccounts: true, hasEnabledAccounts: false, needsPermission: true, hasIssue: true
        )
        XCTAssertEqual(state, .disabled)
        XCTAssertEqual(ProviderConnectionState.resolve(
            hasAccounts: false, hasEnabledAccounts: false, needsPermission: false, hasIssue: true
        ), .available)
    }

    func testNavigationDoesNotLeakProviderSelectionIntoOtherPages() {
        let navigation = NavigationScreenModel()
        navigation.selectProvider(.amp)
        XCTAssertEqual(navigation.currentPage, .providers)
        XCTAssertEqual(navigation.selectedProvider, .amp)
        navigation.currentPage = .quota
        XCTAssertNil(navigation.selectedProvider)
        navigation.selectProvider(.kiro)
        navigation.showProviders()
        XCTAssertNil(navigation.selectedProvider)
        XCTAssertEqual(navigation.currentPage, .providers)
    }
}
