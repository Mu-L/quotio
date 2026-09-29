import Foundation
import QuotioApplication
import QuotioDomain
import QuotioHostClient

@MainActor
public final class QuotioCompanionService: CompanionControlling {
    private var client: QuotioHostHTTPClient?
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func connect(_ connection: QuotioHostConnection) async throws {
        client = QuotioHostHTTPClient(connection: connection)
        if defaults.bool(forKey: "companion.enabled") {
            _ = try await configure(enabled: true, origin: defaults.string(forKey: "companion.origin") ?? "",
                                    port: defaults.integer(forKey: "companion.port"))
        }
    }
    public func status() async throws -> CompanionStatus {
        guard let client else { throw QuotioHostClientError.disconnected }
        return try await client.request("v2/sharing")
    }
    public func configure(enabled: Bool, origin: String, port: Int) async throws -> CompanionStatus {
        guard let client else { throw QuotioHostClientError.disconnected }
        if enabled { try validate(origin: origin); guard (1...65535).contains(port) else { throw QuotioHostClientError.incompatible } }
        let body = try JSONSerialization.data(withJSONObject: ["enabled": enabled, "listen": "127.0.0.1:\(port)", "public_url": origin])
        let status: CompanionStatus = try await client.request("v2/sharing", method: "PUT", body: body)
        defaults.set(enabled, forKey: "companion.enabled")
        defaults.set(origin, forKey: "companion.origin")
        defaults.set(port, forKey: "companion.port")
        return status
    }
    public func devices() async throws -> [CompanionDevice] {
        struct Response: Decodable, Sendable { let clients: [CompanionDevice] }
        guard let client else { throw QuotioHostClientError.disconnected }
        let response: Response = try await client.request("v2/clients")
        return response.clients
    }
    public func issue(label: String, origin: String) async throws -> String {
        struct Response: Decodable, Sendable { let schemaVersion: Int; let hostId: String; let client: CompanionDevice; let token: String }
        try validate(origin: origin)
        guard let client else { throw QuotioHostClientError.disconnected }
        let body = try JSONSerialization.data(withJSONObject: ["label": label, "scope": "read", "expires_in_seconds": 2592000] as [String: Any])
        let response: Response = try await client.request("v2/clients", method: "POST", body: body)
        guard response.schemaVersion == 2, response.client.scope == "read" else { throw QuotioHostClientError.incompatible }
        let data = try JSONSerialization.data(withJSONObject: ["pairing_version": 1, "origin": origin, "host_id": response.hostId,
                                                              "client_id": response.client.id, "expires_at": ISO8601DateFormatter().string(from: response.client.expiresAt),
                                                              "token": response.token], options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
    public func revoke(id: String) async throws {
        guard !id.isEmpty, id.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95 }), let client else {
            throw QuotioHostClientError.incompatible
        }
        try await client.delete("v2/clients/\(id)")
    }
    private func validate(origin: String) throws {
        guard let url = URLComponents(string: origin), url.scheme == "https", url.host?.isEmpty == false,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else { throw QuotioHostClientError.incompatible }
    }
}
