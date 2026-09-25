import Foundation
import QuotioDomain

struct QuotioCLIAccountList: Decodable, Sendable {
    let schemaVersion: Int
    let accounts: [QuotioCLIAccount]
}

struct QuotioCLIProviderList: Decodable, Sendable {
    struct Provider: Decodable, Sendable {
        struct Capabilities: Decodable, Sendable {
            struct SourceReference: Decodable, Sendable {
                let kind: String
                let platforms: [String]
                let origin: String
            }

            let sourceReferences: [SourceReference]
        }

        let id: String
        let capabilities: Capabilities
    }

    let schemaVersion: Int
    let providers: [Provider]
}

struct QuotioCLISourceDiscovery: Decodable, Sendable {
    struct Candidate: Decodable, Sendable {
        struct Source: Codable, Hashable, Sendable {
            let kind: String
            let location: String?
            let discoveryRef: String?

            init(kind: String, location: String?, discoveryRef: String?) {
                self.kind = kind
                self.location = location
                self.discoveryRef = discoveryRef
            }
        }

        let status: String
        let source: Source
    }

    let schemaVersion: Int
    let status: String
    let candidates: [Candidate]
}

struct QuotioCLIAccount: Decodable, Sendable {
    let id: String
    let provider: String
    let label: String
    let origin: String
    let enabled: Bool
    let sourceKind: String?
    let sourceLocation: String?
    let sourceId: String?
}

struct QuotioCLIOperation: Decodable, Sendable {
    let id: String
    let status: String
    let error: String?
}

struct QuotioCLIOAuthSession: Decodable, Sendable {
    let provider: String
    let workflow: String
    let userCode: String?
    let id: String
    let url: String
    let expiresAt: Int64
    let status: String
    let accountId: String?
    let errorCode: String?
}

enum QuotioCLIWarpMirror {
    private static let prefix = "__quotio_local_warp__:"

    static func storageLabel(_ label: String) -> String { prefix + label }

    static func displayLabel(_ label: String, provider: String) -> String {
        guard provider == "warp", label.hasPrefix(prefix) else { return label }
        return String(label.dropFirst(prefix.count))
    }

    static func isMirror(_ account: QuotioCLIAccount) -> Bool {
        isMirror(provider: account.provider, origin: account.origin, label: account.label)
    }

    static func isMirror(provider: String, origin: String?, label: String?) -> Bool {
        provider == "warp" && origin == "owned" && label?.hasPrefix(prefix) == true
    }
}

enum QuotioCLIProviderMap {
    static func domain(_ id: String) -> QuotaProvider? {
        switch id {
        case "copilot": .copilot
        case "factory": .factoryDroid
        case "zai": .glm
        case "vertexai": .vertex
        case "devin-desktop": .devin
        default: QuotaProvider(rawValue: id)
        }
    }

    static func cli(_ provider: QuotaProvider) -> String? {
        switch provider {
        case .copilot: "copilot"
        case .factoryDroid: "factory"
        case .glm: "zai"
        case .vertex: "vertexai"
        case .devin: "devin-desktop"
        case .qwen, .iflow, .trae: nil
        default: provider.rawValue
        }
    }
}
