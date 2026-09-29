import XCTest

final class QuotioIOSUITests: XCTestCase {
    @MainActor func testFirstLaunchHasWorkingSharedStorage() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["Explore demo"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Saved connections could not be loaded."].exists)
    }

    @MainActor func testDemoNavigationPrivacyAndConnectionForm() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Demo data"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["39%"].exists)
        app.buttons["Hide values"].tap()
        XCTAssertFalse(app.staticTexts["39%"].exists)
        app.tabBars.buttons["Widgets"].tap()
        XCTAssertTrue(app.staticTexts["Home Screen"].exists)
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Add computer"].tap()
        XCTAssertTrue(app.buttons["Scan pairing code"].waitForExistence(timeout: 3))
        app.buttons["Advanced: HTTPS proxy"].tap()
        XCTAssertTrue(app.secureTextFields["Read-only device token"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Connect"].isEnabled)
        app.buttons["Cancel"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
