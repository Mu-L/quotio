import Foundation
import XCTest
import QuotioApplication
import QuotioDomain
@testable import QuotioPresentation

@MainActor
final class CompanionScreenModelTests: XCTestCase {
    func testPairingFailureClearsOldCodeAndFailedConfigurationPreservesState() async throws {
        let controller = CompanionStub()
        let model = CompanionScreenModel(controller: controller)
        await model.reload()
        XCTAssertTrue(model.enabled)
        XCTAssertEqual(model.origin, "https://host.example.test")
        XCTAssertEqual(model.port, 6768)
        await model.issue()
        XCTAssertEqual(model.pairing, "synthetic-pairing-payload")
        XCTAssertEqual(controller.issueCount, 1)

        controller.fail = true
        await model.issue()
        XCTAssertNil(model.pairing)
        XCTAssertTrue(model.failure)
        XCTAssertFalse(model.busy)
        await model.configure(enabled: false)
        XCTAssertTrue(model.enabled)
        XCTAssertTrue(model.failure)

        controller.fail = false
        await model.configure(enabled: false)
        XCTAssertFalse(model.enabled)
        XCTAssertFalse(model.failure)
        await model.revoke("phone")
        XCTAssertEqual(controller.revokedID, "phone")
    }
}

@MainActor
private final class CompanionStub: CompanionControlling {
    var fail = false
    var issueCount = 0
    var revokedID: String?
    private var enabled = true
    private enum Failure: Error { case unavailable }

    func status() async throws -> CompanionStatus {
        try JSONDecoder().decode(CompanionStatus.self, from: JSONSerialization.data(withJSONObject: [
            "enabled": enabled, "listen": "127.0.0.1:6768", "publicUrl": "https://host.example.test",
        ]))
    }
    func configure(enabled: Bool, origin: String, port: Int) async throws -> CompanionStatus {
        if fail { throw Failure.unavailable }
        self.enabled = enabled
        return try await status()
    }
    func devices() async throws -> [CompanionDevice] { [] }
    func issue(label: String, origin: String) async throws -> String {
        issueCount += 1
        if fail { throw Failure.unavailable }
        return "synthetic-pairing-payload"
    }
    func revoke(id: String) async throws { revokedID = id }
}
