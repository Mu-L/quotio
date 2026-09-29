#if canImport(Security)
import Foundation
import Security
import XCTest
@testable import QuotioHostClient

final class QuotioHostTrustTests: XCTestCase {
    func testPairedRootStillRequiresMatchingHostValidDatesAndSignature() throws {
        func certificate(_ name: String) throws -> Data {
            try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "der", subdirectory: "Fixtures")))
        }
        let leaf = try XCTUnwrap(SecCertificateCreateWithData(nil, certificate("leaf") as CFData))
        func evaluate(root: Data, host: String, date: String = "2026-09-30T00:00:00Z") throws -> Bool {
            var trust: SecTrust?
            XCTAssertEqual(SecTrustCreateWithCertificates([leaf] as CFArray, SecPolicyCreateSSL(true, host as CFString), &trust), errSecSuccess)
            let value = try XCTUnwrap(trust)
            // Fixed time makes the public test certificates independent of the test runner's clock.
            SecTrustSetVerifyDate(value, try XCTUnwrap(ISO8601DateFormatter().date(from: date)) as CFDate)
            return QuotioCLINoRedirectDelegate.evaluate(value, certificate: root, host: host)
        }
        XCTAssertTrue(try evaluate(root: certificate("root"), host: "192.168.1.10"))
        XCTAssertFalse(try evaluate(root: certificate("root"), host: "192.168.1.11"))
        XCTAssertFalse(try evaluate(root: certificate("other"), host: "192.168.1.10"))
        XCTAssertFalse(try evaluate(root: Data("invalid".utf8), host: "192.168.1.10"))
        XCTAssertFalse(try evaluate(root: certificate("root"), host: "192.168.1.10", date: "2030-01-01T00:00:00Z"))
    }
}
#endif

extension QuotioHostClientTests {
    func testLiveRustTLS() async throws {
        guard let path = ProcessInfo.processInfo.environment["QUOTIO_TLS_SMOKE_FILE"] else {
            throw XCTSkip("Set QUOTIO_TLS_SMOKE_FILE to the synthetic Rust TLS fixture")
        }
        struct Fixture: Decodable { let origin: URL; let token: String; let certificate: Data }
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        let client = QuotioHostHTTPClient(connection: .init(baseURL: fixture.origin, token: fixture.token, trustedCertificate: fixture.certificate))
        let status = try await client.status()
        XCTAssertEqual(status.accessMode, "read_only")
        let unpaired = QuotioHostHTTPClient(connection: .init(baseURL: fixture.origin, token: fixture.token))
        do { _ = try await unpaired.status(); XCTFail("Unpaired CA must fail") } catch { }
    }
}
