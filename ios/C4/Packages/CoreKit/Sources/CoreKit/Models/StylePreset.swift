import Foundation

public struct StylePreset: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let promptModifier: String
    public let category: String
    public let thumbnailUrl: String?
    public let isCustom: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        promptModifier: String,
        category: String,
        thumbnailUrl: String? = nil,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.promptModifier = promptModifier
        self.category = category
        self.thumbnailUrl = thumbnailUrl
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
