import Foundation

public struct CompanionStatus: Decodable, Sendable {
    public let enabled: Bool
    public let listen: String?
    public let publicUrl: String?
}
public struct CompanionDevice: Decodable, Sendable, Identifiable {
    public let id: String
    public let label: String
    public let scope: String
    public let expiresAt: Date
}
