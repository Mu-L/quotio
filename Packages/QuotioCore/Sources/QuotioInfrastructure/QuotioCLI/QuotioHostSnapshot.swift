import Foundation

/// Decoder for the resolved Rust contract. No provider policy belongs in these DTOs.
/// Production transport remains v1 until the host's v2 service is available.
struct QuotioHostSnapshot: Decodable, Sendable {
    struct Availability: Decodable, Sendable {
        let available: Bool
        let reason: String?
    }
    struct Host: Decodable, Sendable {
        let id: String
        let platform: String
        let apiVersions: [Int]
        let capabilities: [String: Availability]
    }
    struct Action: Decodable, Sendable {
        let kind: String
        let available: Bool
        let reason: String?
        let interaction: String
    }
    struct Issue: Decodable, Sendable {
        let code: String
        let retryable: Bool
        let action: Action?
    }
    struct Identity: Decodable, Sendable {
        let evidence: String
        let username: String?
        let email: String?
    }
    struct Source: Decodable, Sendable {
        let id: String
        let origin: String
        let kind: String
        let location: String?
        let enabled: Bool
        let selected: Bool
        let state: String
        let refreshOwner: String
        let issue: Issue?
        let actions: [Action]
    }
    struct Account: Decodable, Sendable {
        let id: String
        let providerId: String
        let displayName: String
        let userLabel: String?
        let identity: Identity
        let enabled: Bool
        let active: Bool
        let state: String
        let sources: [Source]
        let actions: [Action]
    }
    struct Metric: Decodable, Sendable {
        let id: String
        let displayName: String
        let quota: QuotioCLIUsageWindow.Quota
        let amounts: QuotioCLIUsageWindow.Amounts?
        let consumption: QuotioCLIUsageWindow.Consumption?
        let resetsAt: Date?
        let resetDescription: String?
        let fetchedAt: Date
    }
    struct Usage: Decodable, Sendable {
        let accountId: String
        let freshness: String
        let fetchedAt: Date?
        let expiresAt: Date?
        let plan: String?
        let metrics: [Metric]
        let issue: Issue?
    }
    let schemaVersion: Int
    let host: Host
    let revision: UInt64
    let generatedAt: Date
    let accounts: [Account]
    let usage: [Usage]

    static func decode(_ data: Data) throws -> Self {
        let value = try makeQuotioCLIDecoder().decode(Self.self, from: data)
        guard value.schemaVersion == 2, value.host.apiVersions.contains(2) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported host contract version"))
        }
        return value
    }
}

struct QuotioHostAccountList: Decodable, Sendable {
    let schemaVersion: Int
    let host: QuotioHostSnapshot.Host
    let revision: UInt64
    let accounts: [QuotioHostSnapshot.Account]
}

/// Mutation scope comes from the resource the user selected, not a provider-specific rule.
enum QuotioHostAccountTarget: Sendable {
    case account(String)
    case source(String)

    var path: String {
        switch self {
        case .account(let id): "v2/accounts/\(id)"
        case .source(let id): "v2/sources/\(id)"
        }
    }
}
