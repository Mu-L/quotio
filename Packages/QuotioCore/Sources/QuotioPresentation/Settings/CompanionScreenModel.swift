import Foundation
import Observation
import QuotioApplication
import QuotioDomain

@MainActor @Observable
public final class CompanionScreenModel {
    public var origin = ""
    public var port = 6768
    public var label = "iPhone"
    public private(set) var enabled = false
    public private(set) var devices: [CompanionDevice] = []
    public private(set) var busy = false
    public private(set) var failure = false
    public var pairing: String?
    private let controller: any CompanionControlling
    public init(controller: any CompanionControlling) { self.controller = controller }
    public func reload() async {
        await perform {
            let status = try await controller.status()
            enabled = status.enabled
            if let value = status.publicUrl { origin = value }
            if let value = status.listen?.split(separator: ":").last, let port = Int(value) { self.port = port }
            devices = try await controller.devices()
        }
    }
    public func configure(enabled: Bool) async {
        await perform {
            let status = try await controller.configure(enabled: enabled, origin: origin, port: port)
            self.enabled = status.enabled
        }
    }
    public func issue() async {
        pairing = nil
        await perform {
            pairing = try await controller.issue(label: label, origin: origin)
            devices = try await controller.devices()
        }
    }
    public func revoke(_ id: String) async {
        await perform { try await controller.revoke(id: id); pairing = nil; devices = try await controller.devices() }
    }
    private func perform(_ operation: () async throws -> Void) async {
        guard !busy else { return }
        busy = true; failure = false
        defer { busy = false }
        do { try await operation() } catch { failure = true }
    }
}
