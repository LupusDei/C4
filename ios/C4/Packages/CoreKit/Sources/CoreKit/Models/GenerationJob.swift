import Foundation

public enum GenerationJobStatus: String, Codable, Sendable {
    case queued
    case processing
    case complete
    case failed
}

public enum GenerationType: String, Codable, Sendable {
    case image
    case video
    case `extension`
}

public struct GenerationJob: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var status: GenerationJobStatus
    public var progress: Double
    public var provider: String?
    public var type: GenerationType?
    public var assetId: UUID?

    enum CodingKeys: String, CodingKey {
        case id = "jobId"
        case status
        case progress
        case provider
        case type
        case assetId
    }

    public init(
        id: UUID = UUID(),
        status: GenerationJobStatus = .queued,
        progress: Double = 0,
        provider: String? = nil,
        type: GenerationType? = nil,
        assetId: UUID? = nil
    ) {
        self.id = id
        self.status = status
        self.progress = progress
        self.provider = provider
        self.type = type
        self.assetId = assetId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.status = try container.decodeIfPresent(GenerationJobStatus.self, forKey: .status) ?? .queued
        self.progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        self.provider = try container.decodeIfPresent(String.self, forKey: .provider)
        self.type = try container.decodeIfPresent(GenerationType.self, forKey: .type)
        self.assetId = try container.decodeIfPresent(UUID.self, forKey: .assetId)
    }
}
