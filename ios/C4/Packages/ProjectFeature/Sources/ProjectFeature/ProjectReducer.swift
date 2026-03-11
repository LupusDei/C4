import ComposableArchitecture
import CoreKit
import Foundation
import PromptFeature

// MARK: - Project List Reducer

@Reducer
public struct ProjectListReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var projects: [Project] = []
        public var isLoading: Bool = false
        public var error: String?
        public var showCreateSheet: Bool = false
        public var newProjectTitle: String = ""
        public var newProjectDescription: String = ""
        public var selectedProject: ProjectDetailReducer.State?

        public init() {}
    }

    public enum Action: Sendable {
        case onAppear
        case loadProjects
        case projectsLoaded(Result<[Project], Error>)
        case createTapped
        case dismissCreateSheet
        case setNewProjectTitle(String)
        case setNewProjectDescription(String)
        case submitCreateProject
        case projectCreated(Result<Project, Error>)
        case deleteProject(UUID)
        case projectDeleted(Result<UUID, Error>)
        case selectProject(Project)
        case clearSelection
        case projectDetail(ProjectDetailReducer.Action)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.projects.isEmpty else { return .none }
                return .send(.loadProjects)

            case .loadProjects:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    let result = await Result {
                        try await apiClient.get("/api/projects", as: [Project].self)
                    }
                    await send(.projectsLoaded(result))
                }

            case .projectsLoaded(.success(let projects)):
                state.isLoading = false
                state.projects = projects
                return .none

            case .projectsLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .createTapped:
                state.showCreateSheet = true
                state.newProjectTitle = ""
                state.newProjectDescription = ""
                return .none

            case .dismissCreateSheet:
                state.showCreateSheet = false
                return .none

            case .setNewProjectTitle(let title):
                state.newProjectTitle = title
                return .none

            case .setNewProjectDescription(let desc):
                state.newProjectDescription = desc
                return .none

            case .submitCreateProject:
                let title = state.newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return .none }
                state.showCreateSheet = false

                let request = CreateProjectRequest(
                    title: title,
                    description: state.newProjectDescription
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post("/api/projects", body: request, as: Project.self)
                    }
                    await send(.projectCreated(result))
                }

            case .projectCreated(.success(let project)):
                state.projects.insert(project, at: 0)
                return .none

            case .projectCreated(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .deleteProject(let id):
                return .run { send in
                    let result: Result<UUID, Error> = await Result {
                        _ = try await apiClient.delete("/api/projects/\(id)")
                        return id
                    }
                    await send(.projectDeleted(result))
                }

            case .projectDeleted(.success(let id)):
                state.projects.removeAll { $0.id == id }
                return .none

            case .projectDeleted(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .selectProject(let project):
                state.selectedProject = ProjectDetailReducer.State(project: project)
                return .none

            case .clearSelection:
                state.selectedProject = nil
                return .none

            case .projectDetail:
                return .none
            }
        }
        .ifLet(\.selectedProject, action: \.projectDetail) {
            ProjectDetailReducer()
        }
    }
}

// MARK: - Project Detail Reducer

@Reducer
public struct ProjectDetailReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var project: Project
        public var assets: [Asset] = []
        public var notes: [Note] = []
        public var isLoadingAssets: Bool = false
        public var isLoadingNotes: Bool = false
        public var newNoteContent: String = ""
        public var editingNoteId: UUID?
        public var editingNoteContent: String = ""
        public var error: String?
        public var defaultStyle: StylePreset?
        public var showStylePicker: Bool = false
        @Presents public var stylePicker: StylePickerReducer.State?

        public init(project: Project) {
            self.project = project
        }
    }

    public enum Action: Sendable {
        case onAppear
        case loadAssets
        case assetsLoaded(Result<[Asset], Error>)
        case deleteAsset(UUID)
        case assetDeleted(Result<UUID, Error>)
        case loadNotes
        case notesLoaded(Result<[Note], Error>)
        case setNewNoteContent(String)
        case addNote
        case noteAdded(Result<Note, Error>)
        case startEditingNote(Note)
        case setEditingNoteContent(String)
        case saveEditingNote
        case noteUpdated(Result<Note, Error>)
        case cancelEditingNote
        case deleteNote(UUID)
        case noteDeleted(Result<UUID, Error>)
        case styleButtonTapped
        case dismissStylePicker
        case stylePicker(PresentationAction<StylePickerReducer.Action>)
        case defaultStyleLoaded(Result<StylePreset, Error>)
        case projectStyleUpdated(Result<Project, Error>)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let styleId = state.project.defaultStylePresetId
                return .merge(
                    .send(.loadAssets),
                    .send(.loadNotes),
                    styleId.map { id in
                        .run { send in
                            let result = await Result {
                                try await apiClient.get("/api/styles/\(id)", as: StylePreset.self)
                            }
                            await send(.defaultStyleLoaded(result))
                        }
                    } ?? .none
                )

            case .loadAssets:
                state.isLoadingAssets = true
                let projectId = state.project.id
                return .run { send in
                    let result = await Result {
                        let response = try await apiClient.get(
                            "/api/projects/\(projectId)/assets",
                            as: PaginatedAssets.self
                        )
                        return response.data
                    }
                    await send(.assetsLoaded(result))
                }

            case .assetsLoaded(.success(let assets)):
                state.isLoadingAssets = false
                state.assets = assets
                return .none

            case .assetsLoaded(.failure(let error)):
                state.isLoadingAssets = false
                state.error = error.localizedDescription
                return .none

            case .deleteAsset(let id):
                return .run { send in
                    let result: Result<UUID, Error> = await Result {
                        _ = try await apiClient.delete("/api/assets/\(id)")
                        return id
                    }
                    await send(.assetDeleted(result))
                }

            case .assetDeleted(.success(let id)):
                state.assets.removeAll { $0.id == id }
                return .none

            case .assetDeleted(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .loadNotes:
                state.isLoadingNotes = true
                let projectId = state.project.id
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/projects/\(projectId)/notes",
                            as: [Note].self
                        )
                    }
                    await send(.notesLoaded(result))
                }

            case .notesLoaded(.success(let notes)):
                state.isLoadingNotes = false
                state.notes = notes
                return .none

            case .notesLoaded(.failure(let error)):
                state.isLoadingNotes = false
                state.error = error.localizedDescription
                return .none

            case .setNewNoteContent(let content):
                state.newNoteContent = content
                return .none

            case .addNote:
                let content = state.newNoteContent.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return .none }
                state.newNoteContent = ""

                let projectId = state.project.id
                let request = CreateNoteRequest(content: content)

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/projects/\(projectId)/notes",
                            body: request,
                            as: Note.self
                        )
                    }
                    await send(.noteAdded(result))
                }

            case .noteAdded(.success(let note)):
                state.notes.insert(note, at: 0)
                return .none

            case .noteAdded(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .startEditingNote(let note):
                state.editingNoteId = note.id
                state.editingNoteContent = note.content
                return .none

            case .setEditingNoteContent(let content):
                state.editingNoteContent = content
                return .none

            case .saveEditingNote:
                guard let noteId = state.editingNoteId else { return .none }
                let content = state.editingNoteContent.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return .none }
                state.editingNoteId = nil

                let projectId = state.project.id
                let request = UpdateNoteRequest(content: content)

                return .run { send in
                    let result = await Result {
                        try await apiClient.put(
                            "/api/projects/\(projectId)/notes/\(noteId)",
                            body: request,
                            as: Note.self
                        )
                    }
                    await send(.noteUpdated(result))
                }

            case .noteUpdated(.success(let note)):
                if let idx = state.notes.firstIndex(where: { $0.id == note.id }) {
                    state.notes[idx] = note
                }
                return .none

            case .noteUpdated(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .cancelEditingNote:
                state.editingNoteId = nil
                state.editingNoteContent = ""
                return .none

            case .deleteNote(let id):
                let projectId = state.project.id
                return .run { send in
                    let result: Result<UUID, Error> = await Result {
                        _ = try await apiClient.delete("/api/projects/\(projectId)/notes/\(id)")
                        return id
                    }
                    await send(.noteDeleted(result))
                }

            case .noteDeleted(.success(let id)):
                state.notes.removeAll { $0.id == id }
                return .none

            case .noteDeleted(.failure(let error)):
                state.error = error.localizedDescription
                return .none

            case .styleButtonTapped:
                state.stylePicker = StylePickerReducer.State(selectedPreset: state.defaultStyle)
                return .none

            case .dismissStylePicker:
                state.stylePicker = nil
                return .none

            case .stylePicker(.presented(.presetSelected(let preset))):
                state.defaultStyle = preset
                let projectId = state.project.id
                let presetId = preset?.id

                return .run { send in
                    let result = await Result {
                        try await apiClient.put(
                            "/api/projects/\(projectId)",
                            body: UpdateProjectStyleRequest(defaultStylePresetId: presetId),
                            as: Project.self
                        )
                    }
                    await send(.projectStyleUpdated(result))
                }

            case .stylePicker:
                return .none

            case .defaultStyleLoaded(.success(let style)):
                state.defaultStyle = style
                return .none

            case .defaultStyleLoaded(.failure):
                // Style might have been deleted; clear the reference
                state.defaultStyle = nil
                return .none

            case .projectStyleUpdated(.success(let project)):
                state.project = project
                return .none

            case .projectStyleUpdated(.failure(let error)):
                state.error = error.localizedDescription
                return .none
            }
        }
        .ifLet(\.$stylePicker, action: \.stylePicker) {
            StylePickerReducer()
        }
    }
}

// MARK: - API Requests

struct CreateProjectRequest: Codable, Sendable {
    let title: String
    let description: String
}

struct CreateNoteRequest: Codable, Sendable {
    let content: String
}

struct UpdateNoteRequest: Codable, Sendable {
    let content: String
}

struct UpdateProjectStyleRequest: Codable, Sendable {
    let defaultStylePresetId: UUID?
}
