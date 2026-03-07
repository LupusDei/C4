import Foundation
import ComposableArchitecture

/// Parsed WebSocket message from backend.
/// Backend sends `{ event: "generation:progress", data: { jobId, progress, status, ... } }`.
public struct WebSocketMessage: Equatable, Sendable {
    public let event: String
    public let jobId: UUID?
    public let progress: Double?
    public let status: String?
    public let assetId: UUID?
    public let error: String?

    public init(
        event: String,
        jobId: UUID? = nil,
        progress: Double? = nil,
        status: String? = nil,
        assetId: UUID? = nil,
        error: String? = nil
    ) {
        self.event = event
        self.jobId = jobId
        self.progress = progress
        self.status = status
        self.assetId = assetId
        self.error = error
    }

    /// Decode from backend's `{ event, data }` wire format.
    static func decode(from data: Data) -> WebSocketMessage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return nil }

        let inner = json["data"] as? [String: Any] ?? [:]
        return WebSocketMessage(
            event: event,
            jobId: (inner["jobId"] as? String).flatMap(UUID.init(uuidString:)),
            progress: inner["progress"] as? Double,
            status: inner["status"] as? String,
            assetId: (inner["assetId"] as? String).flatMap(UUID.init(uuidString:)),
            error: inner["error"] as? String
        )
    }

    public var isComplete: Bool { event == "generation:complete" }
    public var isFailed: Bool { event == "generation:error" }
}

public struct WebSocketClient: Sendable {
    public var connect: @Sendable () async -> AsyncStream<WebSocketMessage>
    public var disconnect: @Sendable () async -> Void
    public var progressUpdates: @Sendable (_ jobId: UUID) async -> AsyncStream<WebSocketMessage>
}

extension WebSocketClient: DependencyKey {
    public static let liveValue = WebSocketClient.live()
    public static let testValue = WebSocketClient.mock()

    public static func live(url: String = "ws://localhost:3000/ws") -> WebSocketClient {
        let connection = WebSocketConnection(url: url)
        return WebSocketClient(
            connect: { await connection.connect() },
            disconnect: { await connection.disconnect() },
            progressUpdates: { jobId in
                let stream = await connection.connect()
                return AsyncStream { continuation in
                    let task = Task {
                        for await message in stream {
                            if message.jobId == jobId {
                                continuation.yield(message)
                                if message.isComplete || message.isFailed {
                                    continuation.finish()
                                    return
                                }
                            }
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }

    public static func mock() -> WebSocketClient {
        WebSocketClient(
            connect: { AsyncStream { $0.finish() } },
            disconnect: {},
            progressUpdates: { _ in AsyncStream { $0.finish() } }
        )
    }
}

extension DependencyValues {
    public var webSocketClient: WebSocketClient {
        get { self[WebSocketClient.self] }
        set { self[WebSocketClient.self] = newValue }
    }
}

// MARK: - WebSocket Connection Actor

private actor WebSocketConnection {
    private let url: String
    private var task: URLSessionWebSocketTask?
    private var isConnected = false
    private let maxReconnectAttempts = 5
    private var reconnectAttempt = 0

    init(url: String) {
        self.url = url
    }

    func connect() -> AsyncStream<WebSocketMessage> {
        AsyncStream { continuation in
            let streamTask = Task {
                while !Task.isCancelled && reconnectAttempt < maxReconnectAttempts {
                    do {
                        try await connectWebSocket()
                        reconnectAttempt = 0

                        while isConnected && !Task.isCancelled {
                            guard let task else { break }
                            let message = try await task.receive()
                            switch message {
                            case .string(let text):
                                if let data = text.data(using: .utf8),
                                   let wsMessage = WebSocketMessage.decode(from: data) {
                                    continuation.yield(wsMessage)
                                }
                            case .data(let data):
                                if let wsMessage = WebSocketMessage.decode(from: data) {
                                    continuation.yield(wsMessage)
                                }
                            @unknown default:
                                break
                            }
                        }
                    } catch {
                        isConnected = false
                        reconnectAttempt += 1

                        if reconnectAttempt < maxReconnectAttempts {
                            let delay = UInt64(pow(2.0, Double(reconnectAttempt))) * 1_000_000_000
                            try? await Task.sleep(nanoseconds: delay)
                        }
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                streamTask.cancel()
            }
        }
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
        reconnectAttempt = maxReconnectAttempts
    }

    private func connectWebSocket() async throws {
        guard let wsURL = URL(string: url) else { return }
        let session = URLSession(configuration: .default)
        task = session.webSocketTask(with: wsURL)
        task?.resume()
        isConnected = true
    }
}
