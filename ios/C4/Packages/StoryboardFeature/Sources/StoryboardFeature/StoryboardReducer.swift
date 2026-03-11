import ComposableArchitecture
import CoreKit
import Foundation

// MARK: - Storyboard List Reducer

@Reducer
public struct StoryboardListReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var projectId: UUID
        public var storyboards: [Storyboard] = []
        public var isLoading: Bool = false
        public var error: String?
        public var showCreateSheet: Bool = false
        public var newStoryboardTitle: String = ""
        public var selectedStoryboard: StoryboardReducer.State?

        public init(projectId: UUID) {
            self.projectId = projectId
        }
    }

    public enum Action: Sendable {
        case onAppear
        case loadStoryboards
        case storyboardsLoaded(Result<[Storyboard], Error>)
        case createTapped
        case dismissCreateSheet
        case setNewStoryboardTitle(String)
        case submitCreateStoryboard
        case storyboardCreated(Result<Storyboard, Error>)
        case deleteStoryboard(UUID)
        case storyboardDeleted(Result<UUID, Error>)
        case selectStoryboard(Storyboard)
        case clearSelection
        case timeline(StoryboardReducer.Action)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.storyboards.isEmpty else { return .none }
                return .send(.loadStoryboards)

            case .loadStoryboards:
                state.isLoading = true
                state.error = nil
                let projectId = state.projectId
                return .run { send in
                    let result = await Result {
                        try await apiClient.fetchStoryboards(projectId: projectId)
                    }
                    await send(.storyboardsLoaded(result))
                }

            case .storyboardsLoaded(.success(let storyboards)):
                state.isLoading = false
                state.storyboards = storyboards
                return .none

            case .storyboardsLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .createTapped:
                state.showCreateSheet = true
                state.newStoryboardTitle = ""
                return .none

            case .dismissCreateSheet:
                state.showCreateSheet = false
                return .none

            case .setNewStoryboardTitle(let title):
                state.newStoryboardTitle = title
                return .none

            case .submitCreateStoryboard:
                let title = state.newStoryboardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return .none }
                state.showCreateSheet = false
                let projectId = state.projectId
                return .run { send in
                    let result = await Result {
                        try await apiClient.createStoryboard(projectId: projectId, title: title)
                    }
                    await send(.storyboardCreated(result))
                }

            case .storyboardCreated(.success(let storyboard)):
                state.storyboards.insert(storyboard, at: 0)
                return .none

            case .storyboardCreated(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .deleteStoryboard(let id):
                return .run { send in
                    let result: Result<UUID, Error> = await Result {
                        try await apiClient.deleteStoryboard(id: id)
                        return id
                    }
                    await send(.storyboardDeleted(result))
                }

            case .storyboardDeleted(.success(let id)):
                state.storyboards.removeAll { $0.id == id }
                return .none

            case .storyboardDeleted(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .selectStoryboard(let storyboard):
                state.selectedStoryboard = StoryboardReducer.State(storyboard: storyboard)
                return .none

            case .clearSelection:
                state.selectedStoryboard = nil
                return .none

            case .timeline:
                return .none
            }
        }
        .ifLet(\.selectedStoryboard, action: \.timeline) {
            StoryboardReducer()
        }
    }
}

// MARK: - Storyboard Timeline Reducer

@Reducer
public struct StoryboardReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        // MARK: - Core State

        public var storyboard: Storyboard
        public var scenes: [Scene] = []
        public var isLoading: Bool = false
        public var error: String?
        public var editingScene: Scene?

        // MARK: - Script Input

        public var scriptText: String = ""
        public var isSplittingScript: Bool = false
        public var scriptError: String?
        public var showScriptInput: Bool = false

        // MARK: - Per-Scene Generation Status

        public var sceneGenerationStatuses: [UUID: SceneGenerationStatus] = [:]
        public var sceneProgressValues: [UUID: Double] = [:]

        // MARK: - Batch Generation

        public var showGenerateAllSheet: Bool = false
        public var batchProvider: Provider = .standard
        public var batchAssetType: BatchAssetType = .image
        public var isBatchGenerating: Bool = false

        // MARK: - Assembly

        public var showAssembleSheet: Bool = false
        public var assemblyTransition: Transition = .crossfade
        public var assemblyCaptions: Bool = true
        public var assemblyStatus: AssemblyStatus = .idle

        // MARK: - Variations

        public var showVariationsSheet: Bool = false
        public var variationsSceneId: UUID?
        public var variationAssets: [UUID: [Asset]] = [:]
        public var isGeneratingVariations: Bool = false

        public init(storyboard: Storyboard) {
            self.storyboard = storyboard
            self.scriptText = storyboard.scriptText
            if let scenes = storyboard.scenes {
                self.scenes = scenes
            }
        }

        // MARK: - Computed

        public var totalDuration: Double {
            scenes.reduce(0) { $0 + $1.durationSeconds }
        }

        public var wordCount: Int {
            scriptText.split(separator: " ").count
        }

        public var characterCount: Int {
            scriptText.count
        }

        public var canSplitScript: Bool {
            wordCount >= 10 && !isSplittingScript
        }

        public var canGenerateAll: Bool {
            !scenes.isEmpty
                && !isBatchGenerating
                && scenes.contains(where: { sceneGenerationStatuses[$0.id] != .complete })
        }

        public var canAssemble: Bool {
            !scenes.isEmpty
                && scenes.allSatisfy { $0.assetId != nil }
                && !isAssembling
        }

        public var isAssembling: Bool {
            if case .assembling = assemblyStatus { return true }
            if case .progress = assemblyStatus { return true }
            return false
        }

        public var estimatedBatchCost: Int {
            let pendingScenes = scenes.filter { sceneGenerationStatuses[$0.id] != .complete }
            let costPerItem: Int
            switch batchProvider {
            case .budget: costPerItem = batchAssetType == .image ? 2 : 5
            case .standard: costPerItem = batchAssetType == .image ? 5 : 10
            case .premium: costPerItem = batchAssetType == .image ? 10 : 20
            }
            return pendingScenes.count * costPerItem
        }
    }

    // MARK: - Supporting Types

    public enum SceneGenerationStatus: Equatable, Sendable {
        case idle
        case generating
        case complete
        case failed(String)
    }

    public enum Provider: String, CaseIterable, Codable, Sendable {
        case budget
        case standard
        case premium

        public var displayName: String {
            switch self {
            case .budget: "Budget"
            case .standard: "Standard"
            case .premium: "Premium"
            }
        }
    }

    public enum BatchAssetType: String, CaseIterable, Codable, Sendable {
        case image
        case video

        public var displayName: String {
            switch self {
            case .image: "Image"
            case .video: "Video"
            }
        }
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

    // MARK: - Actions

    public enum Action: Sendable {
        // Scene CRUD (from ios-1)
        case moveScene(from: Int, to: Int)
        case scenesReordered(Result<Void, Error>)
        case addScene
        case sceneAdded(Result<Scene, Error>)
        case deleteScene(UUID)
        case sceneDeleted(Result<UUID, Error>)
        case selectScene(Scene)
        case dismissSceneEditor
        case updateScene(id: UUID, narrationText: String, visualPrompt: String, durationSeconds: Double)
        case sceneUpdated(Result<Scene, Error>)

        // Script Input
        case setScriptText(String)
        case splitScript
        case splitScriptResponse(Result<[Scene], Error>)
        case showScriptInput(Bool)

        // Batch Generation
        case showGenerateAllSheet(Bool)
        case setBatchProvider(Provider)
        case setBatchAssetType(BatchAssetType)
        case generateAll
        case generateAllResponse(Result<BatchGenerateResponse, Error>)
        case sceneProgress(sceneId: UUID, progress: Double)
        case sceneComplete(sceneId: UUID, assetId: UUID)
        case sceneFailed(sceneId: UUID, error: String)
        case regenerateScene(sceneId: UUID)
        case regenerateSceneResponse(sceneId: UUID, Result<GenerationJob, Error>)

        // Assembly
        case showAssembleSheet(Bool)
        case setTransition(Transition)
        case toggleCaptions
        case assemble
        case assembleResponse(Result<GenerationJob, Error>)
        case assemblyProgress(Double)
        case assemblyComplete(assetId: UUID)
        case assemblyFailed(String)
        case assemblyAssetLoaded(Result<Asset, Error>)

        // Variations
        case showVariationsForScene(UUID)
        case dismissVariations
        case generateVariations(sceneId: UUID, count: Int, provider: Provider)
        case generateVariationsResponse(sceneId: UUID, Result<[GenerationJob], Error>)
        case variationComplete(sceneId: UUID, asset: Asset)
        case selectWinner(sceneId: UUID, assetId: UUID)
        case selectWinnerResponse(sceneId: UUID, Result<Scene, Error>)

        // WebSocket
        case webSocketMessage(WebSocketMessage)

        // General
        case onAppear
        case loadScenes
        case scenesLoaded(Result<[Scene], Error>)
        case dismissError
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient

    private enum CancelID {
        case scriptSplit
        case batchGeneration
        case webSocket
        case assembly
        case assemblyProgress
        case variations
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: - Scene CRUD (from ios-1)

            case .moveScene(let from, let to):
                guard from >= 0, from < state.scenes.count,
                      to >= 0, to < state.scenes.count,
                      from != to else { return .none }

                let scene = state.scenes.remove(at: from)
                state.scenes.insert(scene, at: to)

                // Update order indices
                for i in state.scenes.indices {
                    state.scenes[i].orderIndex = i
                }

                let storyboardId = state.storyboard.id
                let order = state.scenes.map(\.id)
                return .run { send in
                    let result: Result<Void, Error> = await Result {
                        try await apiClient.reorderScenes(storyboardId: storyboardId, order: order)
                    }
                    await send(.scenesReordered(result))
                }

            case .scenesReordered(.success):
                return .none

            case .scenesReordered(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .addScene:
                let storyboardId = state.storyboard.id
                return .run { send in
                    let result = await Result {
                        try await apiClient.createScene(
                            storyboardId: storyboardId,
                            narrationText: "",
                            visualPrompt: "",
                            durationSeconds: 5.0
                        )
                    }
                    await send(.sceneAdded(result))
                }

            case .sceneAdded(.success(let scene)):
                state.scenes.append(scene)
                state.sceneGenerationStatuses[scene.id] = .idle
                return .none

            case .sceneAdded(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .deleteScene(let id):
                return .run { send in
                    let result: Result<UUID, Error> = await Result {
                        try await apiClient.deleteScene(id: id)
                        return id
                    }
                    await send(.sceneDeleted(result))
                }

            case .sceneDeleted(.success(let id)):
                state.scenes.removeAll { $0.id == id }
                state.sceneGenerationStatuses.removeValue(forKey: id)
                state.sceneProgressValues.removeValue(forKey: id)
                // Re-index
                for i in state.scenes.indices {
                    state.scenes[i].orderIndex = i
                }
                return .none

            case .sceneDeleted(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .selectScene(let scene):
                state.editingScene = scene
                return .none

            case .dismissSceneEditor:
                state.editingScene = nil
                return .none

            case .updateScene(let id, let narrationText, let visualPrompt, let durationSeconds):
                state.editingScene = nil
                return .run { send in
                    let result = await Result {
                        try await apiClient.updateScene(
                            id: id,
                            narrationText: narrationText,
                            visualPrompt: visualPrompt,
                            durationSeconds: durationSeconds
                        )
                    }
                    await send(.sceneUpdated(result))
                }

            case .sceneUpdated(.success(let scene)):
                if let idx = state.scenes.firstIndex(where: { $0.id == scene.id }) {
                    state.scenes[idx] = scene
                }
                return .none

            case .sceneUpdated(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            // MARK: - Script Input

            case .setScriptText(let text):
                state.scriptText = text
                return .none

            case .splitScript:
                guard state.canSplitScript else { return .none }
                state.isSplittingScript = true
                state.scriptError = nil

                let storyboardId = state.storyboard.id
                let scriptText = state.scriptText

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/storyboards/\(storyboardId)/split",
                            body: SplitScriptRequest(scriptText: scriptText),
                            as: SplitScriptResponse.self
                        )
                    }
                    await send(.splitScriptResponse(result.map(\.scenes)))
                }
                .cancellable(id: CancelID.scriptSplit)

            case .splitScriptResponse(.success(let scenes)):
                state.isSplittingScript = false
                state.scenes = scenes
                state.showScriptInput = false
                state.storyboard.scriptText = state.scriptText
                // Initialize generation statuses
                for scene in scenes {
                    state.sceneGenerationStatuses[scene.id] = scene.assetId != nil ? .complete : .idle
                }
                return .none

            case .splitScriptResponse(.failure(let error)):
                state.isSplittingScript = false
                state.scriptError = error.localizedDescription
                return .none

            case .showScriptInput(let show):
                state.showScriptInput = show
                return .none

            // MARK: - Batch Generation

            case .showGenerateAllSheet(let show):
                state.showGenerateAllSheet = show
                return .none

            case .setBatchProvider(let provider):
                state.batchProvider = provider
                return .none

            case .setBatchAssetType(let type):
                state.batchAssetType = type
                return .none

            case .generateAll:
                guard state.canGenerateAll else { return .none }
                state.isBatchGenerating = true
                state.showGenerateAllSheet = false

                // Mark all pending scenes as generating
                for scene in state.scenes where state.sceneGenerationStatuses[scene.id] != .complete {
                    state.sceneGenerationStatuses[scene.id] = .generating
                    state.sceneProgressValues[scene.id] = 0
                }

                let storyboardId = state.storyboard.id
                let provider = state.batchProvider.rawValue
                let assetType = state.batchAssetType.rawValue

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/storyboards/\(storyboardId)/generate",
                            body: BatchGenerateRequest(
                                qualityTier: provider,
                                type: assetType
                            ),
                            as: BatchGenerateResponse.self
                        )
                    }
                    await send(.generateAllResponse(result))
                }
                .cancellable(id: CancelID.batchGeneration)

            case .generateAllResponse(.success):
                // Subscribe to WebSocket for scene-level progress
                let storyboardId = state.storyboard.id

                return .run { send in
                    for await message in await webSocketClient.storyboardUpdates(storyboardId) {
                        await send(.webSocketMessage(message))
                    }
                }
                .cancellable(id: CancelID.webSocket)

            case .generateAllResponse(.failure(let error)):
                state.isBatchGenerating = false
                state.error = error.localizedDescription
                // Reset all generating scenes back to idle
                for scene in state.scenes where state.sceneGenerationStatuses[scene.id] == .generating {
                    state.sceneGenerationStatuses[scene.id] = .idle
                }
                return .none

            case .sceneProgress(let sceneId, let progress):
                state.sceneProgressValues[sceneId] = progress
                return .none

            case .sceneComplete(let sceneId, let assetId):
                state.sceneGenerationStatuses[sceneId] = .complete
                state.sceneProgressValues[sceneId] = 100
                if let index = state.scenes.firstIndex(where: { $0.id == sceneId }) {
                    state.scenes[index].assetId = assetId
                }
                // Check if all scenes are done
                let allDone = state.scenes.allSatisfy {
                    state.sceneGenerationStatuses[$0.id] == .complete
                        || state.sceneGenerationStatuses[$0.id]?.isFailed == true
                }
                if allDone {
                    state.isBatchGenerating = false
                }
                return .none

            case .sceneFailed(let sceneId, let error):
                state.sceneGenerationStatuses[sceneId] = .failed(error)
                // Check if all scenes are done
                let allDone = state.scenes.allSatisfy {
                    state.sceneGenerationStatuses[$0.id] == .complete
                        || state.sceneGenerationStatuses[$0.id]?.isFailed == true
                }
                if allDone {
                    state.isBatchGenerating = false
                }
                return .none

            case .regenerateScene(let sceneId):
                state.sceneGenerationStatuses[sceneId] = .generating
                state.sceneProgressValues[sceneId] = 0

                let storyboardId = state.storyboard.id

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/storyboards/\(storyboardId)/scenes/\(sceneId)/regenerate",
                            body: EmptyBody(),
                            as: GenerationJob.self
                        )
                    }
                    await send(.regenerateSceneResponse(sceneId: sceneId, result))
                }

            case .regenerateSceneResponse(_, .success):
                // WebSocket subscription already active or needs to be started
                let storyboardId = state.storyboard.id
                return .run { send in
                    for await message in await webSocketClient.storyboardUpdates(storyboardId) {
                        await send(.webSocketMessage(message))
                    }
                }
                .cancellable(id: CancelID.webSocket)

            case .regenerateSceneResponse(let sceneId, .failure(let error)):
                state.sceneGenerationStatuses[sceneId] = .failed(error.localizedDescription)
                return .none

            // MARK: - Assembly

            case .showAssembleSheet(let show):
                state.showAssembleSheet = show
                return .none

            case .setTransition(let transition):
                state.assemblyTransition = transition
                return .none

            case .toggleCaptions:
                state.assemblyCaptions.toggle()
                return .none

            case .assemble:
                guard state.canAssemble else { return .none }
                state.assemblyStatus = .assembling
                state.showAssembleSheet = false

                let storyboardId = state.storyboard.id
                let transition = state.assemblyTransition.rawValue
                let captions = state.assemblyCaptions

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/storyboards/\(storyboardId)/assemble",
                            body: StoryboardAssembleRequest(
                                transition: transition,
                                enableCaptions: captions
                            ),
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
                        if let progress = message.progress {
                            await send(.assemblyProgress(progress))
                        }
                        if message.isComplete, let assetId = message.assetId {
                            await send(.assemblyComplete(assetId: assetId))
                            return
                        }
                        if message.isFailed {
                            await send(.assemblyFailed(message.error ?? "Assembly failed"))
                            return
                        }
                    }
                }
                .cancellable(id: CancelID.assemblyProgress)

            case .assembleResponse(.failure(let error)):
                state.assemblyStatus = .error(error.localizedDescription)
                return .none

            case .assemblyProgress(let progress):
                state.assemblyStatus = .progress(progress)
                return .none

            case .assemblyComplete(let assetId):
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/assets/\(assetId)",
                            as: Asset.self
                        )
                    }
                    await send(.assemblyAssetLoaded(result))
                }

            case .assemblyFailed(let error):
                state.assemblyStatus = .error(error)
                return .cancel(id: CancelID.assemblyProgress)

            case .assemblyAssetLoaded(.success(let asset)):
                state.assemblyStatus = .complete(asset)
                state.storyboard.status = .assembled
                return .none

            case .assemblyAssetLoaded(.failure(let error)):
                state.assemblyStatus = .error(error.localizedDescription)
                return .none

            // MARK: - Variations

            case .showVariationsForScene(let sceneId):
                state.variationsSceneId = sceneId
                state.showVariationsSheet = true
                return .none

            case .dismissVariations:
                state.showVariationsSheet = false
                state.variationsSceneId = nil
                return .none

            case .generateVariations(let sceneId, let count, let provider):
                state.isGeneratingVariations = true

                let storyboardId = state.storyboard.id

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/storyboards/\(storyboardId)/scenes/\(sceneId)/variations",
                            body: VariationsRequest(count: count, qualityTier: provider.rawValue),
                            as: VariationsResponse.self
                        )
                    }
                    await send(.generateVariationsResponse(sceneId: sceneId, result.map(\.jobs)))
                }
                .cancellable(id: CancelID.variations)

            case .generateVariationsResponse(_, .success):
                // Subscribe to WebSocket for variation progress
                let storyboardId = state.storyboard.id
                return .run { send in
                    for await message in await webSocketClient.storyboardUpdates(storyboardId) {
                        await send(.webSocketMessage(message))
                    }
                }
                .cancellable(id: CancelID.webSocket)

            case .generateVariationsResponse(_, .failure(let error)):
                state.isGeneratingVariations = false
                state.error = error.localizedDescription
                return .none

            case .variationComplete(let sceneId, let asset):
                var existing = state.variationAssets[sceneId] ?? []
                existing.append(asset)
                state.variationAssets[sceneId] = existing
                // Check if we're done generating variations
                state.isGeneratingVariations = false
                return .none

            case .selectWinner(let sceneId, let assetId):
                let storyboardId = state.storyboard.id

                return .run { send in
                    let result = await Result {
                        try await apiClient.put(
                            "/api/storyboards/\(storyboardId)/scenes/\(sceneId)",
                            body: SelectWinnerRequest(assetId: assetId),
                            as: Scene.self
                        )
                    }
                    await send(.selectWinnerResponse(sceneId: sceneId, result))
                }

            case .selectWinnerResponse(let sceneId, .success(let scene)):
                if let index = state.scenes.firstIndex(where: { $0.id == sceneId }) {
                    state.scenes[index] = scene
                    state.sceneGenerationStatuses[sceneId] = .complete
                }
                state.showVariationsSheet = false
                state.variationsSceneId = nil
                return .none

            case .selectWinnerResponse(_, .failure(let error)):
                state.error = error.localizedDescription
                return .none

            // MARK: - WebSocket

            case .webSocketMessage(let message):
                guard let sceneId = message.sceneId else { return .none }

                if let progress = message.progress {
                    state.sceneProgressValues[sceneId] = progress
                }

                if message.isComplete, let assetId = message.assetId {
                    return .send(.sceneComplete(sceneId: sceneId, assetId: assetId))
                }

                if message.isFailed {
                    return .send(.sceneFailed(
                        sceneId: sceneId,
                        error: message.error ?? "Generation failed"
                    ))
                }

                return .send(.sceneProgress(sceneId: sceneId, progress: message.progress ?? 0))

            // MARK: - General

            case .onAppear:
                guard state.scenes.isEmpty else { return .none }
                return .send(.loadScenes)

            case .loadScenes:
                state.isLoading = true
                state.error = nil
                let storyboardId = state.storyboard.id

                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/storyboards/\(storyboardId)/scenes",
                            as: [Scene].self
                        )
                    }
                    await send(.scenesLoaded(result))
                }

            case .scenesLoaded(.success(let scenes)):
                state.isLoading = false
                state.scenes = scenes.sorted(by: { $0.orderIndex < $1.orderIndex })
                for scene in scenes {
                    state.sceneGenerationStatuses[scene.id] = scene.assetId != nil ? .complete : .idle
                }
                return .none

            case .scenesLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .dismissError:
                state.error = nil
                state.scriptError = nil
                return .none
            }
        }
    }
}

// MARK: - SceneGenerationStatus Extension

extension StoryboardReducer.SceneGenerationStatus {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

// MARK: - API Request/Response Types

public struct SplitScriptRequest: Codable, Sendable {
    let scriptText: String
}

public struct SplitScriptResponse: Codable, Sendable {
    let scenes: [Scene]
}

public struct BatchGenerateRequest: Codable, Sendable {
    let qualityTier: String
    let type: String
}

public struct BatchGenerateResponse: Codable, Sendable {
    let jobs: [GenerationJob]
}

public struct StoryboardAssembleRequest: Codable, Sendable {
    let transition: String
    let enableCaptions: Bool
}

public struct VariationsRequest: Codable, Sendable {
    let count: Int
    let qualityTier: String
}

public struct VariationsResponse: Codable, Sendable {
    let jobs: [GenerationJob]
}

public struct SelectWinnerRequest: Codable, Sendable {
    let assetId: UUID
}

public struct EmptyBody: Codable, Sendable {}
