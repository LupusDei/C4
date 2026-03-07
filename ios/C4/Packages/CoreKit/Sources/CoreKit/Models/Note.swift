import Foundation

public struct Note: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let projectId: UUID
    public var content: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        projectId: UUID,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
