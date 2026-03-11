import Foundation

public struct PromptHistory: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let originalPrompt: String
    public let enhancedPrompt: String?
    public let provider: String
    public let stylePresetId: UUID?
    public let assetId: UUID?
    public let kept: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        originalPrompt: String,
        enhancedPrompt: String? = nil,
        provider: String,
        stylePresetId: UUID? = nil,
        assetId: UUID? = nil,
        kept: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalPrompt = originalPrompt
        self.enhancedPrompt = enhancedPrompt
        self.provider = provider
        self.stylePresetId = stylePresetId
        self.assetId = assetId
        self.kept = kept
        self.createdAt = createdAt
    }
}
