import Foundation
import QuotioDomain

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
