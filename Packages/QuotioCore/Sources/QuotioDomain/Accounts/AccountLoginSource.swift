public struct AccountLoginSource: Codable, Hashable, Identifiable, Sendable {
    public let accountID: String
    public let source: AccountSource
    public let credentialReference: String?
    public let status: AccountStatus

    public var id: String { accountID + ":" + source.rawValue + ":" + (credentialReference ?? "") }

    public init(accountID: String, source: AccountSource, credentialReference: String?, status: AccountStatus) {
        self.accountID = accountID
        self.source = source
        self.credentialReference = credentialReference
        self.status = status
    }
}
