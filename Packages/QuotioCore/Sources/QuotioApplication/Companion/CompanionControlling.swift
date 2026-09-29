import QuotioDomain

@MainActor
public protocol CompanionControlling: AnyObject {
    func status() async throws -> CompanionStatus
    func configure(enabled: Bool, origin: String, port: Int) async throws -> CompanionStatus
    func devices() async throws -> [CompanionDevice]
    func issue(label: String, origin: String) async throws -> CompanionPairing
    func revoke(id: String) async throws
}
