import Foundation
import Observation
import QuotioApplication
import QuotioDomain

@MainActor @Observable
public final class CompanionScreenModel {
    public enum Presentation: Equatable { case settings, menuBar }
    public var mode: CompanionConnectionMode = .localNetwork
    public var address = ""
    public private(set) var addresses: [CompanionNetworkAddress] = []
    public var availableAddresses: [CompanionNetworkAddress] { addresses.filter { $0.mode == mode } }
    public var selectedAddress: String { availableAddresses.first(where: { $0.address == address })?.address ?? availableAddresses.first?.address ?? "" }
    public var canEnable: Bool { mode == .proxy ? !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !selectedAddress.isEmpty }
    public var origin = ""
    public var port = 6768
    public var label = "iPhone"
    public private(set) var enabled = false
    public private(set) var hasLoaded = false
    public private(set) var devices: [CompanionDevice] = []
    public private(set) var busy = false
    public private(set) var failure: CompanionFailure?
    public private(set) var pairing: CompanionPairing?
    public private(set) var presentation: Presentation?
    private let controller: any CompanionControlling

    public init(controller: any CompanionControlling) { self.controller = controller }

    public func presentPairing(in presentation: Presentation) {
        clearExpiredPairing()
        self.presentation = presentation
    }

    public func hidePairing(in presentation: Presentation) {
        if self.presentation == presentation { self.presentation = nil }
    }

    public func finishPairing() {
        guard !busy else { return }
        pairing = nil
        presentation = nil
    }

    public func clearExpiredPairing(now: Date = .now) {
        if let pairing, pairing.device.expiresAt <= now || pairing.origin != origin || !enabled {
            self.pairing = nil
        }
    }

    public func reload() async {
        await perform {
            let status = try await controller.status()
            let devices = try await controller.devices()
            addresses = status.addresses ?? []
            if status.enabled || !hasLoaded {
                mode = status.mode ?? .proxy
                if let listen = status.listen { address = String(listen.split(separator: ":").first ?? "") }
                if let value = status.publicUrl { origin = value }
                if let value = status.listen?.split(separator: ":").last, let port = Int(value) { self.port = port }
            }
            enabled = status.enabled
            self.devices = devices
            hasLoaded = true
            clearExpiredPairing()
            if let pairing, !devices.contains(where: { $0.id == pairing.device.id }) { self.pairing = nil }
        }
    }

    public func configure(enabled: Bool) async {
        await perform {
            let status = try await controller.configure(enabled: enabled, origin: origin.trimmingCharacters(in: .whitespacesAndNewlines), port: port, mode: mode, address: selectedAddress)
            self.enabled = status.enabled
            if let value = status.publicUrl { origin = value }
            hasLoaded = true
            clearExpiredPairing()
        }
    }

    public func issue() async {
        guard !busy else { return }
        clearExpiredPairing()
        guard pairing == nil else { return }
        guard enabled else { failure = .hostUnavailable; return }
        await perform {
            let created = try await controller.issue(label: label.trimmingCharacters(in: .whitespacesAndNewlines), origin: origin)
            pairing = created
            devices.removeAll { $0.id == created.device.id }
            devices.append(created.device)
        }
    }

    public func revoke(_ id: String) async {
        await perform {
            try await controller.revoke(id: id)
            devices.removeAll { $0.id == id }
            if pairing?.device.id == id { pairing = nil }
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        failure = nil
        defer { busy = false }
        do { try await operation() }
        catch is CancellationError { }
        catch { failure = (error as? CompanionFailure) ?? .requestFailed }
    }
}

extension CompanionFailure {
    @MainActor var message: String {
        let key: String = switch self {
        case .invalidOrigin: "companion.error.address"
        case .invalidPort: "companion.error.port"
        case .invalidLabel: "companion.error.name"
        case .hostUnavailable: "companion.error.host"
        case .storageUnavailable: "companion.error.storage"
        case .portInUse: "companion.error.portBusy"
        case .mustDisable: "companion.error.disable"
        case .permissionDenied: "companion.error.permission"
        case .networkUnavailable: "companion.error.network"
        case .requestFailed: "companion.error"
        }
        return key.localized()
    }
}
