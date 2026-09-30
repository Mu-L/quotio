import Foundation
import QuotioApplication
import QuotioDomain
import QuotioHostClient

@MainActor
public final class QuotioCompanionService: CompanionControlling {
    private var activeStatus: CompanionStatus?
    private var client: QuotioHostHTTPClient?
    private let defaults: UserDefaults
    private let session: URLSession?

    public init(defaults: UserDefaults = .standard, session: URLSession? = nil) {
        self.defaults = defaults
        self.session = session
    }

    public func connect(_ connection: QuotioHostConnection) async throws {
        client = QuotioHostHTTPClient(connection: connection, session: session)
        activeStatus = nil
        var failure: Error?
        for mode in CompanionConnectionMode.allCases {
            let settings = savedSettings(mode)
            guard settings.enabled else { continue }
            do {
                _ = try await configure(enabled: true, origin: settings.publicUrl ?? "",
                                        port: Int(settings.listen?.split(separator: ":").last ?? "") ?? 6768,
                                        mode: mode, address: String(settings.listen?.split(separator: ":", omittingEmptySubsequences: false).first ?? ""))
            } catch is CancellationError { throw CancellationError() }
            catch { if failure == nil { failure = error } }
        }
        if let failure { throw failure }
    }

    public func status() async throws -> CompanionStatus {
        let value: CompanionStatus = try await request("v2/sharing")
        let status = withSavedSettings(value)
        activeStatus = status
        return status
    }

    private var savedMode: CompanionConnectionMode {
        if let raw = defaults.string(forKey: "companion.mode"), let mode = CompanionConnectionMode(rawValue: raw) { return mode }
        return defaults.string(forKey: "companion.origin") == nil ? .localNetwork : .proxy
    }

    private func savedSettings(_ mode: CompanionConnectionMode) -> CompanionEndpoint {
        let prefix = "companion.\(mode.rawValue)."
        let legacy = mode == savedMode
        let port = defaults.object(forKey: prefix + "port") as? Int
            ?? (legacy ? defaults.object(forKey: "companion.port") as? Int : nil) ?? 6768
        let address = defaults.string(forKey: prefix + "address")
            ?? (legacy ? defaults.string(forKey: "companion.address") : nil)
            ?? (mode == .proxy ? "127.0.0.1" : "")
        let origin = defaults.string(forKey: prefix + "origin")
            ?? (legacy ? defaults.string(forKey: "companion.origin") : nil)
        let enabled = defaults.object(forKey: prefix + "enabled") as? Bool
            ?? (legacy && defaults.bool(forKey: "companion.enabled"))
        return CompanionEndpoint(enabled: enabled, listen: "\(address):\(port)", publicUrl: origin, mode: mode)
    }

    private func withSavedSettings(_ value: CompanionStatus) -> CompanionStatus {
        let connections = CompanionConnectionMode.allCases.map { mode in
            if let endpoint = value.connections.first(where: { $0.mode == mode && $0.enabled }) { return endpoint }
            let saved = savedSettings(mode)
            return CompanionEndpoint(enabled: false, listen: saved.listen, publicUrl: saved.publicUrl, mode: mode)
        }
        let selected = connections.first(where: { $0.mode == (value.enabled ? value.mode ?? .proxy : savedMode) })!
        return CompanionStatus(enabled: value.enabled, listen: selected.listen, publicUrl: selected.publicUrl,
                               mode: selected.mode, addresses: value.addresses ?? activeStatus?.addresses,
                               certificate: selected.certificate, endpoints: connections)
    }

    public func configure(enabled: Bool, origin: String, port: Int,
                          mode: CompanionConnectionMode = .proxy, address: String = "") async throws -> CompanionStatus {
        var input: [String: Any] = ["enabled": enabled, "mode": mode.rawValue]
        if enabled {
            guard (1...65535).contains(port) else { throw CompanionFailure.invalidPort }
            input["mode"] = mode.rawValue
            if mode == .proxy {
                try validate(origin: origin)
                input["listen"] = "127.0.0.1:\(port)"
                input["public_url"] = origin
            } else {
                let available = try await status().addresses ?? []
                guard let selected = available.first(where: { $0.mode == mode && (address.isEmpty || $0.address == address) }) else { throw CompanionFailure.networkUnavailable }
                input["listen"] = "\(selected.address):\(port)"
                input["public_url"] = NSNull()
            }
        }
        let body = try JSONSerialization.data(withJSONObject: input)
        let status: CompanionStatus = try await request("v2/sharing", method: "PUT", body: body)
        let endpoint = status.connections.first(where: { $0.mode == mode && $0.enabled })
        guard !enabled || endpoint != nil else { throw CompanionFailure.requestFailed }
        let prefix = "companion.\(mode.rawValue)."
        defaults.set(enabled, forKey: prefix + "enabled")
        if let endpoint, enabled {
            defaults.set(endpoint.publicUrl, forKey: prefix + "origin")
            defaults.set(port, forKey: prefix + "port")
            defaults.set(endpoint.listen?.split(separator: ":").first.map(String.init), forKey: prefix + "address")
        }
        let merged = withSavedSettings(status)
        activeStatus = merged
        return merged
    }

    public func devices() async throws -> [CompanionDevice] {
        struct Response: Decodable, Sendable { let clients: [CompanionDevice] }
        let response: Response = try await request("v2/clients")
        return response.clients
    }

    public func issue(label: String, origin: String) async throws -> CompanionPairing {
        struct Response: Decodable, Sendable {
            let schemaVersion: Int
            let hostId: String
            let client: CompanionDevice
            let token: String
        }
        try validate(origin: origin)
        guard let current = activeStatus?.connections.first(where: { $0.enabled && $0.publicUrl == origin }) else { throw CompanionFailure.hostUnavailable }
        guard current.mode == .proxy || current.certificate != nil else { throw CompanionFailure.requestFailed }
        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CompanionFailure.invalidLabel }
        let body = try JSONSerialization.data(withJSONObject: ["label": label, "scope": "read", "expires_in_seconds": 2592000] as [String: Any])
        let response: Response = try await request("v2/clients", method: "POST", body: body)
        guard response.schemaVersion == 2, response.client.scope == "read" else { throw CompanionFailure.requestFailed }
        var payload: [String: Any] = ["pairing_version": 2, "origin": origin,
                                      "host_name": Host.current().localizedName ?? ProcessInfo.processInfo.hostName, "host_id": response.hostId,
                                                              "client_id": response.client.id, "expires_at": ISO8601DateFormatter().string(from: response.client.expiresAt),
                                                              "token": response.token]
        if let certificate = current.certificate { payload["certificate"] = certificate }
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        return CompanionPairing(device: response.client, origin: origin, token: response.token, payload: String(decoding: data, as: UTF8.self))
    }

    public func revoke(id: String) async throws {
        guard !id.isEmpty, id.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95 }) else {
            throw CompanionFailure.requestFailed
        }
        guard let client else { throw CompanionFailure.hostUnavailable }
        do { try await client.delete("v2/clients/\(id)") }
        catch { throw Self.failure(error) }
    }

    private func request<T: Decodable & Sendable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let client else { throw CompanionFailure.hostUnavailable }
        do { return try await client.request(path, method: method, body: body) }
        catch {
            if error is CancellationError || (error as? URLError)?.code == .cancelled { throw CancellationError() }
            throw Self.failure(error)
        }
    }

    private func validate(origin: String) throws {
        guard let url = URLComponents(string: origin), url.scheme == "https", url.host?.isEmpty == false,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/", url.port.map({ (1...65535).contains($0) }) ?? true else {
            throw CompanionFailure.invalidOrigin
        }
    }

    private static func failure(_ error: Error) -> CompanionFailure {
        switch error {
        case QuotioHostClientError.response(_, "network_address_unavailable"),
             QuotioHostClientError.response(_, "network_discovery_failed"): .networkUnavailable
        case QuotioHostClientError.response(_, "share_port_unavailable"): .portInUse
        case QuotioHostClientError.response(_, "disable_sharing_before_changing_origin"): .mustDisable
        case QuotioHostClientError.response(_, "invalid_public_url"): .invalidOrigin
        case QuotioHostClientError.response(_, "invalid_share_address"): .invalidPort
        case QuotioHostClientError.response(_, "credential_storage_unavailable"),
             QuotioHostClientError.response(_, "account_storage_disabled"),
             QuotioHostClientError.response(_, "account_storage_unavailable"): .storageUnavailable
        case QuotioHostClientError.response(401, _), QuotioHostClientError.response(403, _): .permissionDenied
        case QuotioHostClientError.disconnected, QuotioHostClientError.timeout, is URLError: .hostUnavailable
        default: .requestFailed
        }
    }
}
