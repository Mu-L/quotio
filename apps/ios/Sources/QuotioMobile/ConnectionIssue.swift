import Foundation
import QuotioHostClient

/// Why the selected Mac could not be read. One issue at a time drives the single
/// connection banner; the detail sheet carries troubleshooting steps.
public enum ConnectionIssue: Equatable, Sendable {
    case unreachable
    case untrusted
    case needsPairing
    case incompatible
    case busy
    case wrongHost
    case local(String)

    public init(_ error: any Error) {
        switch error {
        case MobileError.expiredCredential, QuotioHostClientError.response(401, _): self = .needsPairing
        case MobileError.wrongHost: self = .wrongHost
        case QuotioHostClientError.incompatible: self = .incompatible
        case QuotioHostClientError.response(503, _): self = .busy
        case let error as URLError where Self.tlsCodes.contains(error.code): self = .untrusted
        case is KeychainError: self = .local(String(localized: "Secure storage is locked", bundle: .main))
        default: self = .unreachable
        }
    }

    /// The host client cancels the TLS challenge when the paired certificate does not match,
    /// which URLSession reports as `.cancelled`. Task cancellation is filtered by HostStore
    /// before errors are mapped.
    private static let tlsCodes: Set<URLError.Code> = [
        .cancelled, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot,
        .serverCertificateNotYetValid, .secureConnectionFailed, .clientCertificateRejected,
        .clientCertificateRequired, .appTransportSecurityRequiresSecureConnection,
    ]

    public var title: String {
        switch self {
        case .unreachable: String(localized: "Can't reach your Mac", bundle: .main)
        case .untrusted: String(localized: "Certificate not trusted", bundle: .main)
        case .needsPairing: String(localized: "Pair this Mac again", bundle: .main)
        case .incompatible: String(localized: "Update Quotio on your Mac", bundle: .main)
        case .busy: String(localized: "Your Mac is busy", bundle: .main)
        case .wrongHost: String(localized: "Mac identity changed", bundle: .main)
        case .local(let message): message
        }
    }

    public var detail: String {
        switch self {
        case .unreachable: String(localized: "The last request to your Mac did not get a response.", bundle: .main)
        case .untrusted: String(localized: "The HTTPS certificate does not match the one saved when you paired.", bundle: .main)
        case .needsPairing: String(localized: "This iPhone's access was revoked or has expired.", bundle: .main)
        case .incompatible: String(localized: "Your Mac runs a Quotio version this app does not support.", bundle: .main)
        case .busy: String(localized: "Quotio on your Mac is busy or its credential storage is locked.", bundle: .main)
        case .wrongHost: String(localized: "This address now belongs to a different Mac.", bundle: .main)
        case .local: String(localized: "Unlock your iPhone and try again.", bundle: .main)
        }
    }

    public var steps: [String] {
        switch self {
        case .unreachable: [
            String(localized: "Make sure your Mac is awake and Quotio is running.", bundle: .main),
            String(localized: "Connect both devices to the same network or Tailscale.", bundle: .main),
            String(localized: "Check that iPhone sharing is on in Quotio on your Mac.", bundle: .main),
        ]
        case .untrusted, .wrongHost, .needsPairing: [
            String(localized: "On your Mac, open Quotio and choose Pair iPhone.", bundle: .main),
            String(localized: "Scan the new pairing code on this iPhone.", bundle: .main),
        ]
        case .incompatible: [String(localized: "Update Quotio on your Mac, then retry.", bundle: .main)]
        case .busy: [String(localized: "Unlock your Mac, then retry.", bundle: .main)]
        case .local: []
        }
    }

    /// Issues fixed by pairing again rather than retrying.
    public var needsPairing: Bool {
        switch self {
        case .needsPairing, .untrusted, .wrongHost: true
        default: false
        }
    }
}
