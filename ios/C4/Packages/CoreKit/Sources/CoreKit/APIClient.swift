import Foundation
import ComposableArchitecture

public struct APIClient: Sendable {
    public var get: @Sendable (_ path: String) async throws -> Data
    public var post: @Sendable (_ path: String, _ body: Data?) async throws -> Data
    public var put: @Sendable (_ path: String, _ body: Data?) async throws -> Data
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
            delete: { path in try await performRequest("DELETE", path, nil) }
        )
    }

    public static func mock() -> APIClient {
        APIClient(
            get: { _ in Data() },
            post: { _, _ in Data() },
            put: { _, _ in Data() },
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

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
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
