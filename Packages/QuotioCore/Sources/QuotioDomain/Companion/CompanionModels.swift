import Foundation

public enum CompanionConnectionMode: String, Codable, Sendable, CaseIterable {
    case localNetwork = "local_network", tailscale, proxy
}

public struct CompanionNetworkAddress: Decodable, Sendable, Equatable {
    public let mode: CompanionConnectionMode
    public let address: String
    public let interface: String
    public init(mode: CompanionConnectionMode, address: String, interface: String) {
        self.mode = mode; self.address = address; self.interface = interface
    }
}

public struct CompanionStatus: Decodable, Sendable {
    public let enabled: Bool
    public let listen: String?
    public let publicUrl: String?
    public let mode: CompanionConnectionMode?
    public let addresses: [CompanionNetworkAddress]?
    public let certificate: String?

    public init(enabled: Bool, listen: String?, publicUrl: String?, mode: CompanionConnectionMode? = nil, addresses: [CompanionNetworkAddress]? = nil, certificate: String? = nil) {
        self.enabled = enabled
        self.listen = listen
        self.publicUrl = publicUrl
        self.mode = mode; self.addresses = addresses; self.certificate = certificate
    }
}

public struct CompanionDevice: Decodable, Sendable, Identifiable, Equatable {
    public let id: String
    public let label: String
    public let scope: String
    public let expiresAt: Date

    public init(id: String, label: String, scope: String, expiresAt: Date) {
        self.id = id
        self.label = label
        self.scope = scope
        self.expiresAt = expiresAt
    }
}

/// The credential payload stays in memory for the current presentation session.
public struct CompanionPairing: Sendable, Equatable {
    public let device: CompanionDevice
    public let origin: String
    public let token: String
    public let payload: String

    public init(device: CompanionDevice, origin: String, token: String, payload: String) {
        self.device = device
        self.origin = origin
        self.token = token
        self.payload = payload
    }
}

public enum CompanionFailure: Error, Equatable, Sendable {
    case invalidOrigin, invalidPort, invalidLabel
    case hostUnavailable, storageUnavailable, portInUse, mustDisable, permissionDenied
    case networkUnavailable
    case requestFailed
}
