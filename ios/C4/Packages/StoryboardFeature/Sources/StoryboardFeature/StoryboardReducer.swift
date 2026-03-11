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
        public var selectedStoryboard: StoryboardTimelineReducer.State?

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
        case timeline(StoryboardTimelineReducer.Action)
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
                state.selectedStoryboard = StoryboardTimelineReducer.State(storyboard: storyboard)
                return .none

            case .clearSelection:
                state.selectedStoryboard = nil
                return .none

            case .timeline:
                return .none
            }
        }
        .ifLet(\.selectedStoryboard, action: \.timeline) {
            StoryboardTimelineReducer()
        }
    }
}

// MARK: - Storyboard Timeline Reducer

@Reducer
public struct StoryboardTimelineReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var storyboard: Storyboard
        public var scenes: [Scene] = []
        public var isLoading: Bool = false
        public var error: String?
        public var editingScene: Scene?

        public init(storyboard: Storyboard) {
            self.storyboard = storyboard
            self.scenes = storyboard.scenes ?? []
        }

        public var totalDuration: Double {
            scenes.reduce(0) { $0 + $1.durationSeconds }
        }
    }

    public enum Action: Sendable {
        case onAppear
        case loadScenes
        case scenesLoaded(Result<[Scene], Error>)
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
        case generateAllTapped
        case assembleTapped
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.scenes.isEmpty else { return .none }
                return .send(.loadScenes)

            case .loadScenes:
                state.isLoading = true
                state.error = nil
                let storyboardId = state.storyboard.id
                return .run { send in
                    let result = await Result {
                        try await apiClient.fetchScenes(storyboardId: storyboardId)
                    }
                    await send(.scenesLoaded(result))
                }

            case .scenesLoaded(.success(let scenes)):
                state.isLoading = false
                state.scenes = scenes.sorted { $0.orderIndex < $1.orderIndex }
                return .none

            case .scenesLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

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

            case .generateAllTapped:
                // Placeholder for Phase 3 generation
                return .none

            case .assembleTapped:
                // Placeholder for assembly integration
                return .none
            }
        }
    }
}
