import Foundation

public struct CompanionStatus: Decodable, Sendable {
    public let enabled: Bool
    public let listen: String?
    public let publicUrl: String?

    public init(enabled: Bool, listen: String?, publicUrl: String?) {
        self.enabled = enabled
        self.listen = listen
        self.publicUrl = publicUrl
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
    case requestFailed
}
