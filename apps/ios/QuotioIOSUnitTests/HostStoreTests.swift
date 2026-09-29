import Foundation
import Synchronization
import Testing
import QuotioMobile
import QuotioHostClient
@testable import QuotioIOS

private final class HostProtocol: URLProtocol, @unchecked Sendable {
    static let replies = Mutex<[String: (Int, Data)]>([:])
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let reply = Self.replies.withLock { $0[request.url!.path] ?? (404, Data()) }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: reply.0, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.1)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Test @MainActor func pairingPersistsInKeychainAndRevocationClearsSensitiveCache() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let storage = MobileStorage(directory: directory)
    let group = try #require(Bundle.main.object(forInfoDictionaryKey: "QuotioKeychainGroup") as? String)
    let keychain = MobileKeychain(accessGroup: group, service: "app.quotio.ios.tests.\(UUID().uuidString)")
    let fixtureURL = try #require(Bundle.main.url(forResource: "demo-snapshot", withExtension: "json"))
    let fixture = try Data(contentsOf: fixtureURL)
    let hostID = try QuotioHostSnapshot.decode(fixture).host.id
    defer { try? keychain.delete(hostID); try? FileManager.default.removeItem(at: directory) }
    let clientID = String(repeating: "a", count: 43)
    let token = "qclient.\(clientID).\(String(repeating: "b", count: 43))"
    let status = try JSONSerialization.data(withJSONObject: ["schema_version":2,"api_version":2,"client_id":clientID,"access_mode":"read_only","ready":true,"refreshing":false])
    HostProtocol.replies.withLock { $0 = ["/v2/status":(200,status),"/v2/snapshot":(200,fixture),"/v2/providers":(200,Data(#"{"schema_version":2,"providers":[]}"#.utf8))] }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [HostProtocol.self]
    let session = URLSession(configuration: configuration)
    let store = HostStore(storage: storage, keychain: keychain, makeClient: { QuotioHostHTTPClient(connection: $0, session: session) })
    try await store.pair(name: "Synthetic host", origin: "https://host.example.test", token: token, pairing: nil)
    #expect(store.selected?.id == hostID)
    #expect(try keychain.read(hostID) == token)
    #expect(try storage.load().hosts.first?.snapshot != nil)
    let persisted = try String(contentsOf: directory.appendingPathComponent("state.json"), encoding: .utf8)
    #expect(!persisted.contains(token))
    HostProtocol.replies.withLock { $0["/v2/snapshot"] = (401,Data(#"{"error":"unauthorized"}"#.utf8)) }
    await store.refresh()
    #expect(store.selected?.needsPairing == true)
    #expect(store.selected?.snapshot == nil)
    #expect(try storage.load().hosts.first?.snapshot == nil)
    store.remove(hostID)
    #expect(try keychain.read(hostID) == nil)
    #expect(try storage.load().hosts.isEmpty)
}
