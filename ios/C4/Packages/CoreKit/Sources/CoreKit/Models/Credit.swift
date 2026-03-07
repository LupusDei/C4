import Foundation

public struct CreditAccount: Codable, Equatable, Sendable {
    public var balance: Int
    public var transactions: [CreditTransaction]

    public init(balance: Int = 0, transactions: [CreditTransaction] = []) {
        self.balance = balance
        self.transactions = transactions
    }
}

public enum CreditTransactionType: String, Codable, Sendable {
    case debit
    case credit
    case refund
}

public struct CreditTransaction: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: CreditTransactionType
    public let amount: Int
    public var description: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        type: CreditTransactionType,
        amount: Int,
        description: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.description = description
        self.createdAt = createdAt
    }
}
