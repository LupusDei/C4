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

    public init(
        id: UUID = UUID(),
        storyboardId: UUID,
        orderIndex: Int,
        narrationText: String = "",
        visualPrompt: String = "",
        durationSeconds: Double = 5.0,
        assetId: UUID? = nil,
        variations: [UUID] = []
    ) {
        self.id = id
        self.storyboardId = storyboardId
        self.orderIndex = orderIndex
        self.narrationText = narrationText
        self.visualPrompt = visualPrompt
        self.durationSeconds = durationSeconds
        self.assetId = assetId
        self.variations = variations
    }
}
