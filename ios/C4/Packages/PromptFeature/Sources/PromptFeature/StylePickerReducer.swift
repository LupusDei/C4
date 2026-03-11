import ComposableArchitecture
import CoreKit
import Foundation

@Reducer
public struct StylePickerReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var presets: [StylePreset] = []
        public var selectedPreset: StylePreset?
        public var selectedCategory: String?
        public var searchText: String = ""
        public var isLoading: Bool = false
        public var error: String?

        public init(selectedPreset: StylePreset? = nil) {
            self.selectedPreset = selectedPreset
        }

        public var filteredPresets: [StylePreset] {
            var result = presets

            if let category = selectedCategory {
                result = result.filter { $0.category == category }
            }

            if !searchText.isEmpty {
                let query = searchText.lowercased()
                result = result.filter { $0.name.lowercased().contains(query) }
            }

            return result
        }

        public var customPresets: [StylePreset] {
            filteredPresets.filter { $0.isCustom }
        }

        public var builtinPresets: [StylePreset] {
            filteredPresets.filter { !$0.isCustom }
        }
    }

    public static let categories = [
        "cinematic",
        "photography",
        "illustration",
        "digital-art",
        "retro",
        "abstract",
    ]

    public static func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "cinematic": return "Cinematic"
        case "photography": return "Photography"
        case "illustration": return "Illustration"
        case "digital-art": return "Digital Art"
        case "retro": return "Retro"
        case "abstract": return "Abstract"
        default: return category.capitalized
        }
    }

    public enum Action: Sendable {
        case onAppear
        case presetsLoaded(Result<[StylePreset], Error>)
        case presetSelected(StylePreset?)
        case categoryChanged(String?)
        case searchTextChanged(String)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.presets.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let result = await Result {
                        try await apiClient.get("/api/styles", as: [StylePreset].self)
                    }
                    await send(.presetsLoaded(result))
                }

            case .presetsLoaded(.success(let presets)):
                state.isLoading = false
                state.presets = presets
                return .none

            case .presetsLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .presetSelected(let preset):
                state.selectedPreset = preset
                return .none

            case .categoryChanged(let category):
                state.selectedCategory = category
                return .none

            case .searchTextChanged(let text):
                state.searchText = text
                return .none
            }
        }
    }
}
