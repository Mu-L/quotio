import Foundation

/// Decoder for the resolved Rust contract. No provider policy belongs in these DTOs.
public struct QuotioHostSnapshot: Decodable, Sendable {
    public struct Availability: Decodable, Sendable {
        public let available: Bool
        public let reason: String?
    }
    public struct Host: Decodable, Sendable {
        public let id: String
        public let platform: String
        public let apiVersions: [Int]
        public let capabilities: [String: Availability]
    }
    public struct Action: Decodable, Sendable {
        public let kind: String
        public let available: Bool
        public let reason: String?
        public let interaction: String
    }
    public struct Issue: Decodable, Sendable {
        public let code: String
        public let retryable: Bool
        public let action: Action?
    }
    public struct Identity: Decodable, Sendable {
        public let evidence: String
        public let username: String?
        public let email: String?
    }
    public struct Source: Decodable, Sendable {
        public let id: String
        public let origin: String
        public let kind: String
        public let location: String?
        public let enabled: Bool
        public let selected: Bool
        public let state: String
        public let refreshOwner: String
        public let issue: Issue?
        public let actions: [Action]
    }
    public struct Account: Decodable, Sendable {
        public let id: String
        public let providerId: String
        public let displayName: String
        public let userLabel: String?
        public let identity: Identity
        public let enabled: Bool
        public let active: Bool
        public let state: String
        public let sources: [Source]
        public let actions: [Action]
    }
    public struct Quota: Decodable, Sendable {
        public let state: String
        public let remainingPercent: Double?
        public let amount: Double?
        public let unit: String?
    }
    public struct Amounts: Decodable, Sendable {
        public let remaining: Double
        public let limit: Double?
        public let unit: String
    }
    public struct Consumption: Decodable, Sendable {
        public let used: Double
        public let unit: String
    }
    public struct Metric: Decodable, Sendable {
        public let id: String
        public let displayName: String
        public let note: String?
        public let quota: Quota
        public let amounts: Amounts?
        public let consumption: Consumption?
        public let resetsAt: Date?
        public let resetDescription: String?
        public let fetchedAt: Date
    }
    public struct Usage: Decodable, Sendable {
        public let accountId: String
        public let freshness: String
        public let fetchedAt: Date?
        public let expiresAt: Date?
        public let plan: String?
        public let metrics: [Metric]
        public let issue: Issue?
    }
    public let schemaVersion: Int
    public let host: Host
    public let revision: UInt64
    public let generatedAt: Date
    public let accounts: [Account]
    public let usage: [Usage]

    public static func decode(_ data: Data) throws -> Self {
        let value = try makeQuotioHostDecoder().decode(Self.self, from: data)
        guard value.schemaVersion == 2, value.host.apiVersions.contains(2) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported host contract version"))
        }
        return value
    }
}

public struct QuotioHostAccountList: Decodable, Sendable {
    public let schemaVersion: Int
    public let host: QuotioHostSnapshot.Host
    public let revision: UInt64
    public let accounts: [QuotioHostSnapshot.Account]
}

/// Mutation scope comes from the resource the user selected, not a provider-specific rule.
public enum QuotioHostAccountTarget: Sendable {
    case account(String)
    case source(String)

    public var path: String {
        switch self {
        case .account(let id): "v2/accounts/\(id)"
        case .source(let id): "v2/sources/\(id)"
        }
    }
}
