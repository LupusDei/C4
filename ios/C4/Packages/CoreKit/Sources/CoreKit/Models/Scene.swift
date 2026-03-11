import Foundation

public struct Scene: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let storyboardId: UUID
    public var orderIndex: Int
    public var narrationText: String
    public var visualPrompt: String
    public var durationSeconds: Double
    public var assetId: UUID?
    public var variations: [UUID]
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        storyboardId: UUID,
        orderIndex: Int = 0,
        narrationText: String = "",
        visualPrompt: String = "",
        durationSeconds: Double = 5.0,
        assetId: UUID? = nil,
        variations: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.storyboardId = storyboardId
        self.orderIndex = orderIndex
        self.narrationText = narrationText
        self.visualPrompt = visualPrompt
        self.durationSeconds = durationSeconds
        self.assetId = assetId
        self.variations = variations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, variations
        case storyboardId = "storyboard_id"
        case orderIndex = "order_index"
        case narrationText = "narration_text"
        case visualPrompt = "visual_prompt"
        case durationSeconds = "duration_seconds"
        case assetId = "asset_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
