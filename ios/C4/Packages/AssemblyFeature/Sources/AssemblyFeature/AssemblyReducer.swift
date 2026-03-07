import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct AssemblyReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var projectId: UUID?
        public var availableClips: [Asset] = []
        public var selectedClipIds: [UUID] = []
        public var aspectRatio: AspectRatio = .landscape
        public var transition: Transition = .crossfade
        public var enableCaptions: Bool = false
        public var assemblyStatus: AssemblyStatus = .idle
        public var isLoadingClips: Bool = false
        public var error: String?

        public init() {}

        public var isAssembling: Bool {
            if case .assembling = assemblyStatus { return true }
            if case .progress = assemblyStatus { return true }
            return false
        }

        public var canAssemble: Bool {
            selectedClipIds.count >= 2 && !isAssembling
        }

        public var selectedClips: [Asset] {
            selectedClipIds.compactMap { id in
                availableClips.first { $0.id == id }
            }
        }
    }

    public enum AspectRatio: String, CaseIterable, Codable, Sendable {
        case landscape = "16:9"
        case portrait = "9:16"
        case square = "1:1"
    }

    public enum Transition: String, CaseIterable, Codable, Sendable {
        case none
        case crossfade
        case fade

        public var displayName: String {
            switch self {
            case .none: "None"
            case .crossfade: "Crossfade"
            case .fade: "Fade"
            }
        }
    }

    public enum AssemblyStatus: Equatable, Sendable {
        case idle
        case assembling
        case progress(Double)
        case complete(Asset)
        case error(String)
    }

    public enum Action: Sendable {
        case onAppear
        case loadClips
        case clipsLoaded(Result<[Asset], Error>)
        case toggleClip(UUID)
        case moveClip(from: Int, to: Int)
        case setAspectRatio(AspectRatio)
        case setTransition(Transition)
        case toggleCaptions
        case assembleTapped
        case assembleResponse(Result<GenerationJob, Error>)
        case progressUpdate(WebSocketMessage)
        case assetLoaded(Result<Asset, Error>)
        case reset
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient

    private enum CancelID { case assembly, progress }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoadingClips, state.availableClips.isEmpty else { return .none }
                return .send(.loadClips)

            case .loadClips:
                guard let projectId = state.projectId else { return .none }
                state.isLoadingClips = true
                state.error = nil

                return .run { send in
                    let result = await Result {
                        let response = try await apiClient.get(
                            "/api/projects/\(projectId)/assets",
                            as: PaginatedAssets.self
                        )
                        return response.data
                    }
                    await send(.clipsLoaded(result))
                }

            case .clipsLoaded(.success(let assets)):
                state.isLoadingClips = false
                state.availableClips = assets.filter { $0.type == .video && $0.status == .complete }
                return .none

            case .clipsLoaded(.failure(let error)):
                state.isLoadingClips = false
                state.error = error.localizedDescription
                return .none

            case .toggleClip(let id):
                if let index = state.selectedClipIds.firstIndex(of: id) {
                    state.selectedClipIds.remove(at: index)
                } else {
                    state.selectedClipIds.append(id)
                }
                return .none

            case .moveClip(let from, let to):
                guard from >= 0, from < state.selectedClipIds.count,
                      to >= 0, to < state.selectedClipIds.count,
                      from != to else { return .none }
                let clip = state.selectedClipIds.remove(at: from)
                state.selectedClipIds.insert(clip, at: to)
                return .none

            case .setAspectRatio(let ratio):
                state.aspectRatio = ratio
                return .none

            case .setTransition(let transition):
                state.transition = transition
                return .none

            case .toggleCaptions:
                state.enableCaptions.toggle()
                return .none

            case .assembleTapped:
                guard state.canAssemble, let projectId = state.projectId else { return .none }
                state.assemblyStatus = .assembling

                let clips = state.selectedClips.map { asset in
                    AssembleClip(
                        assetId: asset.id,
                        filePath: asset.filePath ?? "",
                        startTime: 0,
                        endTime: 5
                    )
                }

                let request = AssembleRequest(
                    projectId: projectId,
                    clips: clips,
                    aspectRatio: state.aspectRatio.rawValue,
                    transition: state.transition.rawValue,
                    enableCaptions: state.enableCaptions
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/assemble",
                            body: request,
                            as: GenerationJob.self
                        )
                    }
                    await send(.assembleResponse(result))
                }
                .cancellable(id: CancelID.assembly)

            case .assembleResponse(.success(let job)):
                state.assemblyStatus = .progress(0)

                return .run { send in
                    for await message in await webSocketClient.progressUpdates(job.id) {
                        await send(.progressUpdate(message))
                    }
                }
                .cancellable(id: CancelID.progress)

            case .assembleResponse(.failure(let error)):
                state.assemblyStatus = .error(error.localizedDescription)
                return .none

            case .progressUpdate(let message):
                if let progress = message.progress {
                    state.assemblyStatus = .progress(progress)
                }

                if message.isComplete, let assetId = message.assetId {
                    return .run { send in
                        let result = await Result {
                            try await apiClient.get(
                                "/api/assets/\(assetId)",
                                as: Asset.self
                            )
                        }
                        await send(.assetLoaded(result))
                    }
                }

                if message.isFailed {
                    state.assemblyStatus = .error(message.error ?? "Assembly failed")
                    return .cancel(id: CancelID.progress)
                }

                return .none

            case .assetLoaded(.success(let asset)):
                state.assemblyStatus = .complete(asset)
                return .none

            case .assetLoaded(.failure(let error)):
                state.assemblyStatus = .error(error.localizedDescription)
                return .none

            case .reset:
                state.selectedClipIds = []
                state.assemblyStatus = .idle
                state.error = nil
                return .merge(
                    .cancel(id: CancelID.assembly),
                    .cancel(id: CancelID.progress)
                )
            }
        }
    }
}

// MARK: - API Request

struct AssembleClip: Codable, Sendable {
    let assetId: UUID
    let filePath: String
    let startTime: Double
    let endTime: Double
}

struct AssembleRequest: Codable, Sendable {
    let projectId: UUID
    let clips: [AssembleClip]
    let aspectRatio: String
    let transition: String
    let enableCaptions: Bool
}
