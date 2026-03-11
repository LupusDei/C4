import Foundation

public enum StoryboardStatus: String, Codable, Sendable {
    case draft
    case generating
    case complete
    case assembled
}

public struct Storyboard: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let projectId: UUID
    public var title: String
    public var scriptText: String
    public var status: StoryboardStatus
    public var scenes: [Scene]?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        scriptText: String = "",
        status: StoryboardStatus = .draft,
        scenes: [Scene]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.scriptText = scriptText
        self.status = status
        self.scenes = scenes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, scenes
        case projectId = "project_id"
        case scriptText = "script_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
