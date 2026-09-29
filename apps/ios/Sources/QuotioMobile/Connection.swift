import Foundation
import QuotioHostClient

public enum MobileError: Error, Sendable {
    case invalidConnection, expiredCredential, wrongHost, readCredentialRequired, invalidCache
}

/// The QR is a credential, not a one-use authorization code. Never log its contents.
public struct Pairing: Codable, Sendable {
    public var pairingVersion: Int
    public var origin: String
    public var hostName: String
    public var hostID: String
    public var clientID: String
    public var expiresAt: Date
    public var token: String
    public var certificate: Data?

    enum CodingKeys: String, CodingKey {
        case pairingVersion = "pairing_version", origin, token, certificate
        case hostName = "host_name"
        case hostID = "host_id", clientID = "client_id", expiresAt = "expires_at"
    }

    public static func decode(_ data: Data, now: Date = .now) throws -> Self {
        guard data.count <= 16_384 else { throw MobileError.invalidConnection }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let value = try decoder.decode(Self.self, from: data)
        guard value.pairingVersion == 2,
              value.certificate.map({ !$0.isEmpty && $0.count <= 4096 }) ?? true else {
            throw MobileError.invalidConnection
        }
        guard !value.hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              value.hostName.utf8.count <= 255,
              !value.hostID.isEmpty,
              value.clientID == (try Connection.clientID(value.token)) else {
            throw MobileError.invalidConnection
        }
        _ = try Connection.origin(value.origin)
        guard value.expiresAt > now else { throw MobileError.expiredCredential }
        return value
    }
}

public enum Connection {
    public static func origin(_ text: String) throws -> URL {
        guard let components = URLComponents(string: text), components.scheme == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              components.path.isEmpty || components.path == "/",
              components.port.map({ (1...65_535).contains($0) }) ?? true,
              let url = components.url else { throw MobileError.invalidConnection }
        return url
    }

    public static func clientID(_ token: String) throws -> String {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "qclient",
              parts.dropFirst().allSatisfy({ part in
                  part.utf8.count == 43 && part.utf8.allSatisfy {
                      (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95
                  }
              }) else { throw MobileError.readCredentialRequired }
        return String(parts[1])
    }

    public static func verify(status: QuotioHostStatus, snapshot: QuotioHostSnapshot,
                              token: String, expectedHostID: String?) throws {
        guard status.accessMode == "read_only", status.clientId == (try clientID(token)) else {
            throw MobileError.readCredentialRequired
        }
        guard expectedHostID == nil || expectedHostID == snapshot.host.id else { throw MobileError.wrongHost }
    }
}
