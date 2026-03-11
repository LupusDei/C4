import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct PromptHistoryReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var entries: [PromptHistory] = []
        public var isLoading: Bool = false
        public var searchText: String = ""
        public var total: Int = 0
        public var currentOffset: Int = 0
        public var selectedEntry: PromptHistory?
        public var isRemixing: Bool = false
        public var remixError: String?

        public init() {}

        public var hasMore: Bool {
            currentOffset + entries.count < total
        }

        static let pageSize = 20
    }

    public enum Action: Sendable {
        case onAppear
        case entriesLoaded(Result<PromptHistoryResponse, Error>)
        case searchTextChanged(String)
        case searchDebounced
        case loadMore
        case moreLoaded(Result<PromptHistoryResponse, Error>)
        case entryTapped(PromptHistory)
        case remixTapped(PromptHistory)
        case remixResponse(Result<RemixResult, Error>)
        case dismissRemixError
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case search }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.entries.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let result = await Result {
                        try await apiClient.fetchPromptHistory(limit: State.pageSize, offset: 0)
                    }
                    await send(.entriesLoaded(result))
                }

            case .entriesLoaded(.success(let response)):
                state.isLoading = false
                state.entries = response.items
                state.total = response.total
                state.currentOffset = 0
                return .none

            case .entriesLoaded(.failure):
                state.isLoading = false
                return .none

            case .searchTextChanged(let text):
                state.searchText = text
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchDebounced)
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .searchDebounced:
                state.isLoading = true
                let search = state.searchText
                return .run { send in
                    let result = await Result {
                        try await apiClient.fetchPromptHistory(
                            search: search.isEmpty ? nil : search,
                            limit: State.pageSize,
                            offset: 0
                        )
                    }
                    await send(.entriesLoaded(result))
                }

            case .loadMore:
                guard !state.isLoading, state.hasMore else { return .none }
                state.isLoading = true
                let nextOffset = state.currentOffset + State.pageSize
                let search = state.searchText
                return .run { send in
                    let result = await Result {
                        try await apiClient.fetchPromptHistory(
                            search: search.isEmpty ? nil : search,
                            limit: State.pageSize,
                            offset: nextOffset
                        )
                    }
                    await send(.moreLoaded(result))
                }

            case .moreLoaded(.success(let response)):
                state.isLoading = false
                state.entries.append(contentsOf: response.items)
                state.currentOffset += State.pageSize
                state.total = response.total
                return .none

            case .moreLoaded(.failure):
                state.isLoading = false
                return .none

            case .entryTapped(let entry):
                state.selectedEntry = entry
                return .none

            case .remixTapped(let entry):
                state.isRemixing = true
                state.remixError = nil
                let prompt = entry.enhancedPrompt ?? entry.originalPrompt
                return .run { send in
                    let result = await Result {
                        try await apiClient.remixPrompt(prompt: prompt)
                    }
                    await send(.remixResponse(result))
                }

            case .remixResponse(.success(let result)):
                state.isRemixing = false
                // Create a synthetic entry so the parent can pick up the remixed prompt
                state.selectedEntry = PromptHistory(
                    projectId: UUID(),
                    originalPrompt: result.remixed
                )
                return .none

            case .remixResponse(.failure(let error)):
                state.isRemixing = false
                state.remixError = error.localizedDescription
                return .none

            case .dismissRemixError:
                state.remixError = nil
                return .none
            }
        }
    }
}
