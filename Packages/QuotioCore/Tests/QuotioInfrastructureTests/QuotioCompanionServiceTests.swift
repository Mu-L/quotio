import Foundation
import XCTest
import QuotioDomain
import QuotioHostClient
@testable import QuotioInfrastructure

@MainActor
final class QuotioCompanionServiceTests: XCTestCase {
    func testDirectSharingDiscoversAddressAndIncludesTrustInPairingCode() async throws {
        let suite = "quotio-direct-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CompanionHTTPStub.self]
        let service = QuotioCompanionService(defaults: defaults, session: URLSession(configuration: configuration))
        try await service.connect(.init(baseURL: URL(string: "http://127.0.0.1:6767")!, token: "synthetic-owner-token"))
        CompanionHTTPStub.state.reset(status: 200, body: #"{"enabled":true,"mode":"local_network","listen":"192.168.1.10:6768","public_url":"https://192.168.1.10:6768","certificate":"AQID","addresses":[{"mode":"local_network","address":"192.168.1.10","interface":"en0"}]}"#)
        let result = try await service.configure(enabled: true, origin: "", port: 6768, mode: .localNetwork, address: "192.168.1.10")
        XCTAssertEqual(result.publicUrl, "https://192.168.1.10:6768")
        let request = try XCTUnwrap(CompanionHTTPStub.state.requests().last)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertEqual(body["listen"] as? String, "192.168.1.10:6768")
        XCTAssertEqual(body["mode"] as? String, "local_network")
        XCTAssertEqual(defaults.string(forKey: "companion.local_network.address"), "192.168.1.10")
        CompanionHTTPStub.state.reset(status: 201, body: #"{"schema_version":2,"host_id":"fixture","client":{"id":"phone","label":"iPhone","scope":"read","expires_at":"2030-01-01T00:00:00Z"},"token":"synthetic-device-token"}"#)
        let pairing = try await service.issue(label: "iPhone", origin: result.publicUrl!)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(pairing.payload.utf8)) as? [String: Any])
        XCTAssertEqual(payload["pairing_version"] as? Int, 2)
        XCTAssertEqual(payload["certificate"] as? String, "AQID")
        XCTAssertFalse(try XCTUnwrap(payload["host_name"] as? String).isEmpty)
        CompanionHTTPStub.state.reset(status: 200, body: #"{"enabled":false,"addresses":[]}"#)
        do {
            _ = try await service.configure(enabled: true, origin: "", port: 6768, mode: .tailscale)
            XCTFail("No interface must not enable sharing")
        } catch let failure as CompanionFailure { XCTAssertEqual(failure, .networkUnavailable) }
        XCTAssertTrue(CompanionHTTPStub.state.requests().allSatisfy { $0.httpMethod == "GET" })
    }

    func testIndependentEndpointsRestoreLegacyAddressAndIssueTrustForSelectedOrigin() async throws {
        let suite = "quotio-multiple-endpoints-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "companion.enabled")
        defaults.set("local_network", forKey: "companion.mode")
        defaults.set("192.168.1.10", forKey: "companion.address")
        defaults.set(6768, forKey: "companion.port")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CompanionHTTPStub.self]
        let session = URLSession(configuration: configuration)
        let service = QuotioCompanionService(defaults: defaults, session: session)
        let connection = QuotioHostConnection(baseURL: URL(string: "http://127.0.0.1:6767")!, token: "synthetic-owner-token")
        let both = #"{"enabled":true,"mode":"local_network","listen":"192.168.1.10:6768","public_url":"https://192.168.1.10:6768","endpoints":[{"enabled":true,"mode":"local_network","listen":"192.168.1.10:6768","public_url":"https://192.168.1.10:6768","certificate":"AQID"},{"enabled":true,"mode":"tailscale","listen":"100.64.0.2:6768","public_url":"https://100.64.0.2:6768","certificate":"BAUG"}],"addresses":[{"mode":"local_network","address":"172.16.0.2","interface":"utun11"},{"mode":"local_network","address":"192.168.1.10","interface":"en0"},{"mode":"tailscale","address":"100.64.0.2","interface":"utun4"}]}"#
        CompanionHTTPStub.state.reset(status: 200, body: both)
        try await service.connect(connection)
        let restored = try XCTUnwrap(CompanionHTTPStub.state.requests().last?.httpBody)
        let input = try XCTUnwrap(JSONSerialization.jsonObject(with: restored) as? [String: Any])
        XCTAssertEqual(input["listen"] as? String, "192.168.1.10:6768")
        _ = try await service.configure(enabled: true, origin: "", port: 6768, mode: .tailscale, address: "100.64.0.2")
        XCTAssertTrue(defaults.bool(forKey: "companion.local_network.enabled"))
        XCTAssertTrue(defaults.bool(forKey: "companion.tailscale.enabled"))
        CompanionHTTPStub.state.reset(status: 201, body: #"{"schema_version":2,"host_id":"fixture","client":{"id":"phone","label":"iPhone","scope":"read","expires_at":"2030-01-01T00:00:00Z"},"token":"synthetic-device-token"}"#)
        let pairing = try await service.issue(label: "Tailscale phone", origin: "https://100.64.0.2:6768")
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(pairing.payload.utf8)) as? [String: Any])
        XCTAssertEqual(payload["certificate"] as? String, "BAUG")
        XCTAssertEqual(payload["origin"] as? String, "https://100.64.0.2:6768")
        CompanionHTTPStub.state.reset(status: 200, body: both)
        try await QuotioCompanionService(defaults: defaults, session: session).connect(connection)
        let bodies = try CompanionHTTPStub.state.requests().filter { $0.httpMethod == "PUT" }.map {
            try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap($0.httpBody)) as? [String: Any])
        }
        XCTAssertEqual(bodies.compactMap { $0["mode"] as? String }, ["local_network", "tailscale"])
        let lanOnly = #"{"enabled":true,"mode":"local_network","listen":"192.168.1.10:6768","public_url":"https://192.168.1.10:6768","endpoints":[{"enabled":true,"mode":"local_network","listen":"192.168.1.10:6768","public_url":"https://192.168.1.10:6768","certificate":"AQID"}],"addresses":[{"mode":"local_network","address":"192.168.1.10","interface":"en0"}]}"#
        CompanionHTTPStub.state.reset(status: 200, body: lanOnly)
        let result = try await service.configure(enabled: false, origin: "", port: 6768, mode: .tailscale)
        XCTAssertTrue(result.connections.first(where: { $0.mode == .localNetwork })!.enabled)
        XCTAssertFalse(result.connections.first(where: { $0.mode == .tailscale })!.enabled)
        XCTAssertTrue(defaults.bool(forKey: "companion.local_network.enabled"))
        XCTAssertFalse(defaults.bool(forKey: "companion.tailscale.enabled"))
        defaults.set(true, forKey: "companion.tailscale.enabled")
        CompanionHTTPStub.state.reset(status: 200, body: lanOnly)
        do { try await QuotioCompanionService(defaults: defaults, session: session).connect(connection); XCTFail("Unavailable Tailscale must report a failure") }
        catch let error as CompanionFailure { XCTAssertEqual(error, .networkUnavailable) }
        XCTAssertEqual(CompanionHTTPStub.state.requests().filter { $0.httpMethod == "PUT" }.count, 1)
        CompanionHTTPStub.state.reset(status: 200, body: lanOnly)
        do { _ = try await service.configure(enabled: true, origin: "", port: 6768, mode: .localNetwork, address: "192.168.1.99"); XCTFail("A saved address must not silently change") }
        catch let error as CompanionFailure { XCTAssertEqual(error, .networkUnavailable) }
        XCTAssertTrue(CompanionHTTPStub.state.requests().allSatisfy { $0.httpMethod == "GET" })
        CompanionHTTPStub.state.reset(status: 200, body: #"{"enabled":false,"listen":null,"public_url":null,"endpoints":[],"addresses":[]}"#)
        let disabled = try await service.status()
        XCTAssertEqual(disabled.listen, "192.168.1.10:6768")
        XCTAssertFalse(disabled.connections.first(where: { $0.mode == .localNetwork })!.enabled)
        XCTAssertEqual(disabled.connections.first(where: { $0.mode == .tailscale })!.listen, "100.64.0.2:6768")
    }

    func testDisabledSharingRestoresPreferencesAndFailedWritesDoNotReplaceThem() async throws {
        let suite = "quotio-companion-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("https://saved.example.test", forKey: "companion.origin")
        defaults.set(7878, forKey: "companion.port")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CompanionHTTPStub.self]
        let service = QuotioCompanionService(defaults: defaults, session: URLSession(configuration: configuration))
        try await service.connect(.init(baseURL: URL(string: "http://127.0.0.1:6767")!, token: "synthetic-owner-token"))
        CompanionHTTPStub.state.reset(status: 200, body: #"{"enabled":false,"listen":null,"public_url":null}"#)
        let status = try await service.status()
        XCTAssertFalse(status.enabled)
        XCTAssertEqual(status.publicUrl, "https://saved.example.test")
        XCTAssertEqual(status.listen, "127.0.0.1:7878")
        _ = try await service.configure(enabled: false, origin: "invalid draft", port: -1)
        XCTAssertEqual(defaults.string(forKey: "companion.origin"), "https://saved.example.test")
        XCTAssertEqual(defaults.integer(forKey: "companion.port"), 7878)
        let body = try XCTUnwrap(CompanionHTTPStub.state.requests().last?.httpBody)
        let disabled = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(disabled["enabled"] as? Bool, false)
        XCTAssertEqual(disabled["mode"] as? String, "proxy")

        for (code, expected) in [("share_port_unavailable", CompanionFailure.portInUse), ("credential_storage_unavailable", .storageUnavailable)] {
            CompanionHTTPStub.state.reset(status: 409, body: "{\"error\":\"\(code)\"}")
            do {
                _ = try await service.configure(enabled: true, origin: "https://new.example.test", port: 6768)
                XCTFail("Failed configuration must throw")
            } catch let failure as CompanionFailure { XCTAssertEqual(failure, expected) }
            XCTAssertEqual(defaults.string(forKey: "companion.origin"), "https://saved.example.test")
            XCTAssertFalse(defaults.bool(forKey: "companion.enabled"))
        }
        CompanionHTTPStub.state.reset(status: 200, body: #"{"enabled":true,"mode":"proxy","public_url":"https://saved.example.test"}"#)
        _ = try await service.status()
        CompanionHTTPStub.state.reset(status: 201, body: #"{"schema_version":2,"host_id":"host-fixture","client":{"id":"phone","label":"iPhone","scope":"read","expires_at":"2030-01-01T00:00:00Z"},"token":"synthetic-device-token"}"#)
        let pairing = try await service.issue(label: "iPhone", origin: "https://saved.example.test")
        XCTAssertEqual(pairing.device.id, "phone")
        XCTAssertEqual(pairing.token, "synthetic-device-token")
        XCTAssertEqual(CompanionHTTPStub.state.requests().count, 1)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(pairing.payload.utf8)) as? [String: Any])
        XCTAssertEqual(payload["client_id"] as? String, pairing.device.id)
        XCTAssertEqual(payload["origin"] as? String, pairing.origin)
        CompanionHTTPStub.state.cancelRequests()
        do { _ = try await service.status(); XCTFail("Cancelled view refresh must propagate cancellation") }
        catch is CancellationError { }
    }
}

private final class CompanionHTTPStub: URLProtocol, @unchecked Sendable {
    final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var status = 200
        private var body = Data()
        private var captured: [URLRequest] = []
        private var cancelled = false
        func cancelRequests() { lock.withLock { cancelled = true } }
        func reset(status: Int, body: String) { lock.withLock { self.status = status; self.body = Data(body.utf8); captured = []; cancelled = false } }
        func receive(_ request: URLRequest) -> (Int, Data, Bool) { lock.withLock { captured.append(request); return (status, body, cancelled) } }
        func requests() -> [URLRequest] { lock.withLock { captured } }
    }
    static let state = State()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        var captured = request
        if captured.httpBody == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                bytes.append(contentsOf: buffer.prefix(count))
            }
            captured.httpBody = bytes
        }
        let (status, body, cancelled) = Self.state.receive(captured)
        if cancelled {
            client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
            return
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
