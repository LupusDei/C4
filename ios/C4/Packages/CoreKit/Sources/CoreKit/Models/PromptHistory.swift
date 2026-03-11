import Foundation

public struct PromptHistory: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let projectId: UUID?
    public let originalPrompt: String
    public let enhancedPrompt: String?
    public let provider: String?
    public let generationType: String
    public let stylePresetId: UUID?
    public let assetId: UUID?
    public let kept: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        projectId: UUID? = nil,
        originalPrompt: String,
        enhancedPrompt: String? = nil,
        provider: String? = nil,
        generationType: String = "image",
        stylePresetId: UUID? = nil,
        assetId: UUID? = nil,
        kept: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.originalPrompt = originalPrompt
        self.enhancedPrompt = enhancedPrompt
        self.provider = provider
        self.generationType = generationType
        self.stylePresetId = stylePresetId
        self.assetId = assetId
        self.kept = kept
        self.createdAt = createdAt
    }
}

/// Paginated response for prompt history list endpoint.
public struct PromptHistoryResponse: Codable, Equatable, Sendable {
    public let items: [PromptHistory]
    public let total: Int
    public let limit: Int
    public let offset: Int
}

/// Response from the remix endpoint.
public struct RemixResult: Codable, Equatable, Sendable {
    public let original: String
    public let remixed: String
}
