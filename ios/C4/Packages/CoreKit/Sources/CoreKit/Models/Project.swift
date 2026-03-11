import Foundation

public struct Project: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var defaultStylePresetId: UUID?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        defaultStylePresetId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.defaultStylePresetId = defaultStylePresetId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
