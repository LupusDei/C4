import ComposableArchitecture
import CoreKit
import Foundation

/// Represents an item the user was recently editing (storyboard or prompt).
public struct LastEditedItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let type: LastEditedItemType
    public let title: String
    public let subtitle: String?
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        type: LastEditedItemType,
        title: String,
        subtitle: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.updatedAt = updatedAt
    }
}

public enum LastEditedItemType: String, Codable, Sendable {
    case storyboard
    case prompt
    case project
}

/// Quality preset tiers for quick generation from the Studio dashboard.
public enum QualityPreset: String, CaseIterable, Sendable {
    case quickDraft = "quick_draft"
    case standard = "standard"
    case maxQuality = "max_quality"

    public var displayName: String {
        switch self {
        case .quickDraft: "Quick Draft"
        case .standard: "Standard"
        case .maxQuality: "Max Quality"
        }
    }

    public var description: String {
        switch self {
        case .quickDraft: "Fast results, lower fidelity"
        case .standard: "Balanced quality and speed"
        case .maxQuality: "Highest quality, slower generation"
        }
    }

    public var iconName: String {
        switch self {
        case .quickDraft: "hare"
        case .standard: "circle.hexagongrid"
        case .maxQuality: "sparkles"
        }
    }
}

@Reducer
public struct StudioReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var currentProject: Project?
        public var recentGenerations: [Asset] = []
        public var creditBalance: Int = 0
        public var lastEditedItems: [LastEditedItem] = []
        public var isLoadingProject: Bool = false
        public var isLoadingGenerations: Bool = false
        public var isLoadingBalance: Bool = false
        public var isLoadingLastEdited: Bool = false
        public var error: String?

        public init() {}

        public var isLoading: Bool {
            isLoadingProject || isLoadingGenerations || isLoadingBalance || isLoadingLastEdited
        }
    }

    public enum Action: Sendable {
        case onAppear
        case refresh

        // Data loading
        case loadCurrentProject
        case loadRecentGenerations
        case loadCreditBalance
        case loadLastEditedItems

        // Results
        case currentProjectLoaded(Result<[Project], Error>)
        case recentGenerationsLoaded(Result<[Asset], Error>)
        case creditBalanceLoaded(Result<BalanceResponse, Error>)
        case lastEditedItemsLoaded(Result<[LastEditedItem], Error>)

        // Navigation
        case projectTapped
        case generationTapped(Asset)
        case lastEditedItemTapped(LastEditedItem)
        case qualityPresetTapped(QualityPreset)
        case creditBalanceTapped
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                return .merge(
                    .send(.loadCurrentProject),
                    .send(.loadRecentGenerations),
                    .send(.loadCreditBalance),
                    .send(.loadLastEditedItems)
                )

            case .refresh:
                return .merge(
                    .send(.loadCurrentProject),
                    .send(.loadRecentGenerations),
                    .send(.loadCreditBalance),
                    .send(.loadLastEditedItems)
                )

            // MARK: - Loading

            case .loadCurrentProject:
                state.isLoadingProject = true
                state.error = nil
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/projects?limit=1&sort=updatedAt&order=desc",
                            as: [Project].self
                        )
                    }
                    await send(.currentProjectLoaded(result))
                }

            case .loadRecentGenerations:
                state.isLoadingGenerations = true
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/assets?limit=10&sort=createdAt&order=desc&status=complete",
                            as: [Asset].self
                        )
                    }
                    await send(.recentGenerationsLoaded(result))
                }

            case .loadCreditBalance:
                state.isLoadingBalance = true
                return .run { send in
                    let result = await Result {
                        try await apiClient.get(
                            "/api/credits/balance",
                            as: BalanceResponse.self
                        )
                    }
                    await send(.creditBalanceLoaded(result))
                }

            case .loadLastEditedItems:
                state.isLoadingLastEdited = true
                return .run { send in
                    // For now, we derive last-edited from recent projects/storyboards
                    // This could be expanded to a dedicated endpoint later
                    let result = await Result {
                        try await apiClient.get(
                            "/api/projects?limit=5&sort=updatedAt&order=desc",
                            as: [Project].self
                        )
                    }
                    switch result {
                    case .success(let projects):
                        let items = projects.prefix(3).map { project in
                            LastEditedItem(
                                id: project.id,
                                type: .project,
                                title: project.title,
                                subtitle: project.description.isEmpty ? nil : project.description,
                                updatedAt: project.updatedAt
                            )
                        }
                        await send(.lastEditedItemsLoaded(.success(Array(items))))
                    case .failure(let error):
                        await send(.lastEditedItemsLoaded(.failure(error)))
                    }
                }

            // MARK: - Results

            case .currentProjectLoaded(.success(let projects)):
                state.isLoadingProject = false
                state.currentProject = projects.first
                return .none

            case .currentProjectLoaded(.failure(let error)):
                state.isLoadingProject = false
                state.error = error.localizedDescription
                return .none

            case .recentGenerationsLoaded(.success(let assets)):
                state.isLoadingGenerations = false
                state.recentGenerations = assets
                return .none

            case .recentGenerationsLoaded(.failure(let error)):
                state.isLoadingGenerations = false
                state.error = error.localizedDescription
                return .none

            case .creditBalanceLoaded(.success(let response)):
                state.isLoadingBalance = false
                state.creditBalance = response.balance
                return .none

            case .creditBalanceLoaded(.failure(let error)):
                state.isLoadingBalance = false
                state.error = error.localizedDescription
                return .none

            case .lastEditedItemsLoaded(.success(let items)):
                state.isLoadingLastEdited = false
                state.lastEditedItems = items
                return .none

            case .lastEditedItemsLoaded(.failure(let error)):
                state.isLoadingLastEdited = false
                state.error = error.localizedDescription
                return .none

            // MARK: - Navigation (handled by parent)

            case .projectTapped,
                 .generationTapped,
                 .lastEditedItemTapped,
                 .qualityPresetTapped,
                 .creditBalanceTapped:
                return .none
            }
        }
    }
}

// MARK: - API Response Types

struct BalanceResponse: Codable, Sendable {
    let balance: Int
}
