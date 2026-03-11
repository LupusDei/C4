import Foundation
import ComposableArchitecture

public struct APIClient: Sendable {
    public var get: @Sendable (_ path: String) async throws -> Data
    public var post: @Sendable (_ path: String, _ body: Data?) async throws -> Data
    public var put: @Sendable (_ path: String, _ body: Data?) async throws -> Data
    public var patch: @Sendable (_ path: String, _ body: Data?) async throws -> Data
    public var delete: @Sendable (_ path: String) async throws -> Data
}

public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
}

extension APIClient: DependencyKey {
    public static let liveValue = APIClient.live()
    public static let testValue = APIClient.mock()

    public static func live(baseURL: String = "http://localhost:3000") -> APIClient {
        let performRequest: @Sendable (String, String, Data?) async throws -> Data = { method, path, body in
            guard let url = URL(string: "\(baseURL)\(path)") else {
                throw APIError.invalidURL
            }

            var req = URLRequest(url: url)
            req.httpMethod = method
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: req)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
            }

            return data
        }

        return APIClient(
            get: { path in try await performRequest("GET", path, nil) },
            post: { path, body in try await performRequest("POST", path, body) },
            put: { path, body in try await performRequest("PUT", path, body) },
            patch: { path, body in try await performRequest("PATCH", path, body) },
            delete: { path in try await performRequest("DELETE", path, nil) }
        )
    }

    public static func mock() -> APIClient {
        APIClient(
            get: { _ in Data() },
            post: { _, _ in Data() },
            put: { _, _ in Data() },
            patch: { _, _ in Data() },
            delete: { _ in Data() }
        )
    }
}

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

// MARK: - Convenience Methods

extension APIClient {
    public func get<T: Decodable & Sendable>(_ path: String, as type: T.Type) async throws -> T {
        let data = try await get(path)
        return try decode(data, as: type)
    }

    public func post<T: Decodable & Sendable, U: Encodable & Sendable>(
        _ path: String,
        body: U,
        as type: T.Type
    ) async throws -> T {
        let data = try await post(path, encode(body))
        return try decode(data, as: type)
    }

    public func put<T: Decodable & Sendable, U: Encodable & Sendable>(
        _ path: String,
        body: U,
        as type: T.Type
    ) async throws -> T {
        let data = try await put(path, encode(body))
        return try decode(data, as: type)
    }

    public func patch<T: Decodable & Sendable, U: Encodable & Sendable>(
        _ path: String,
        body: U,
        as type: T.Type
    ) async throws -> T {
        let data = try await patch(path, encode(body))
        return try decode(data, as: type)
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    public func deleteAndDiscard(_ path: String) async throws {
        _ = try await delete(path)
    }

    private func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - Storyboard API

extension APIClient {
    public func createStoryboard(projectId: UUID, title: String) async throws -> Storyboard {
        struct Request: Codable, Sendable { let title: String }
        return try await post(
            "/api/projects/\(projectId)/storyboards",
            body: Request(title: title),
            as: Storyboard.self
        )
    }

    public func fetchStoryboards(projectId: UUID) async throws -> [Storyboard] {
        try await get("/api/projects/\(projectId)/storyboards", as: [Storyboard].self)
    }

    public func fetchStoryboard(id: UUID) async throws -> Storyboard {
        try await get("/api/storyboards/\(id)", as: Storyboard.self)
    }

    public func updateStoryboard(id: UUID, title: String? = nil, status: String? = nil) async throws -> Storyboard {
        struct Request: Codable, Sendable {
            let title: String?
            let status: String?
        }
        return try await put(
            "/api/storyboards/\(id)",
            body: Request(title: title, status: status),
            as: Storyboard.self
        )
    }

    public func deleteStoryboard(id: UUID) async throws {
        _ = try await delete("/api/storyboards/\(id)")
    }

    public func createScene(
        storyboardId: UUID,
        narrationText: String,
        visualPrompt: String,
        durationSeconds: Double
    ) async throws -> Scene {
        struct Request: Codable, Sendable {
            let narrationText: String
            let visualPrompt: String
            let durationSeconds: Double
        }
        return try await post(
            "/api/storyboards/\(storyboardId)/scenes",
            body: Request(
                narrationText: narrationText,
                visualPrompt: visualPrompt,
                durationSeconds: durationSeconds
            ),
            as: Scene.self
        )
    }

    public func fetchScenes(storyboardId: UUID) async throws -> [Scene] {
        try await get("/api/storyboards/\(storyboardId)/scenes", as: [Scene].self)
    }

    public func updateScene(
        id: UUID,
        narrationText: String? = nil,
        visualPrompt: String? = nil,
        durationSeconds: Double? = nil
    ) async throws -> Scene {
        struct Request: Codable, Sendable {
            let narrationText: String?
            let visualPrompt: String?
            let durationSeconds: Double?
        }
        return try await put(
            "/api/scenes/\(id)",
            body: Request(
                narrationText: narrationText,
                visualPrompt: visualPrompt,
                durationSeconds: durationSeconds
            ),
            as: Scene.self
        )
    }

    public func deleteScene(id: UUID) async throws {
        _ = try await delete("/api/scenes/\(id)")
    }

    public func reorderScenes(storyboardId: UUID, order: [UUID]) async throws {
        struct Request: Codable, Sendable { let order: [UUID] }
        _ = try await patch(
            "/api/storyboards/\(storyboardId)/scenes/reorder",
            body: Request(order: order),
            as: [Scene].self
        )
    }

    public struct SplitScriptResponse: Codable, Sendable {
        public let storyboard: Storyboard
        public let scenes: [Scene]
    }

    public func splitScript(storyboardId: UUID, scriptText: String) async throws -> SplitScriptResponse {
        struct Request: Codable, Sendable { let scriptText: String }
        return try await post(
            "/api/storyboards/\(storyboardId)/split",
            body: Request(scriptText: scriptText),
            as: SplitScriptResponse.self
        )
    }
}

// MARK: - Style Presets

public struct CreateStyleRequest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let promptModifier: String
    public let category: String
    public let thumbnailUrl: String?

    public init(name: String, description: String? = nil, promptModifier: String, category: String, thumbnailUrl: String? = nil) {
        self.name = name
        self.description = description
        self.promptModifier = promptModifier
        self.category = category
        self.thumbnailUrl = thumbnailUrl
    }
}

public struct UpdateStyleRequest: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let promptModifier: String?
    public let category: String?
    public let thumbnailUrl: String?

    public init(name: String? = nil, description: String? = nil, promptModifier: String? = nil, category: String? = nil, thumbnailUrl: String? = nil) {
        self.name = name
        self.description = description
        self.promptModifier = promptModifier
        self.category = category
        self.thumbnailUrl = thumbnailUrl
    }
}

extension APIClient {
    public func fetchStylePresets(category: String? = nil) async throws -> [StylePreset] {
        var path = "/api/styles"
        if let category {
            path += "?category=\(category)"
        }
        return try await get(path, as: [StylePreset].self)
    }

    public func fetchStylePreset(id: UUID) async throws -> StylePreset {
        return try await get("/api/styles/\(id.uuidString)", as: StylePreset.self)
    }

    public func createCustomStyle(_ style: CreateStyleRequest) async throws -> StylePreset {
        return try await post("/api/styles", body: style, as: StylePreset.self)
    }

    public func updateCustomStyle(id: UUID, _ style: UpdateStyleRequest) async throws -> StylePreset {
        return try await put("/api/styles/\(id.uuidString)", body: style, as: StylePreset.self)
    }

    public func deleteCustomStyle(id: UUID) async throws {
        _ = try await delete("/api/styles/\(id.uuidString)")
    }

    public func fetchPromptHistory(limit: Int = 20, offset: Int = 0, search: String? = nil) async throws -> [PromptHistory] {
        var path = "/api/prompts/history?limit=\(limit)&offset=\(offset)"
        if let search {
            let encoded = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search
            path += "&search=\(encoded)"
        }
        return try await get(path, as: [PromptHistory].self)
    }

    public func deletePromptHistory(id: UUID) async throws {
        _ = try await delete("/api/prompts/history/\(id.uuidString)")
    }
}
