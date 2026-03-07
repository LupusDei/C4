import Foundation

public enum AssetType: String, Codable, Sendable {
    case image
    case video
}

public enum AssetStatus: String, Codable, Sendable {
    case pending
    case processing
    case complete
    case failed
}

public struct Asset: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let projectId: UUID
    public let type: AssetType
    public var prompt: String
    public var provider: String
    public var qualityTier: String
    public var filePath: String?
    public var thumbnailPath: String?
    public var creditCost: Int
    public var status: AssetStatus
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        projectId: UUID,
        type: AssetType,
        prompt: String,
        provider: String,
        qualityTier: String = "standard",
        filePath: String? = nil,
        thumbnailPath: String? = nil,
        creditCost: Int = 0,
        status: AssetStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.type = type
        self.prompt = prompt
        self.provider = provider
        self.qualityTier = qualityTier
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.creditCost = creditCost
        self.status = status
        self.createdAt = createdAt
    }
}

/// Paginated response wrapper for asset list endpoints.
public struct PaginatedAssets: Codable, Equatable, Sendable {
    public let data: [Asset]
    public let total: Int
    public let limit: Int
    public let offset: Int
}
