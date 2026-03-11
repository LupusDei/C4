import ComposableArchitecture
import CoreKit
import Foundation

// MARK: - EnhanceResult

public struct EnhanceResult: Codable, Equatable, Sendable {
    public let original: String
    public let enhanced: String
    public let providerHints: [String]

    public init(original: String, enhanced: String, providerHints: [String]) {
        self.original = original
        self.enhanced = enhanced
        self.providerHints = providerHints
    }
}

// MARK: - Reducer

@Reducer
public struct PromptEnhancerReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var prompt: String = ""
        public var enhancedPrompt: String?
        public var isEnhancing: Bool = false
        public var selectedProvider: String = "auto"
        public var showEnhanced: Bool = false

        public init() {}

        public var canEnhance: Bool {
            prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
                && !isEnhancing
        }

        /// The effective prompt to use for generation — enhanced if available and shown, otherwise original.
        public var effectivePrompt: String {
            if showEnhanced, let enhanced = enhancedPrompt {
                return enhanced
            }
            return prompt
        }
    }

    public enum Action: Sendable {
        case promptChanged(String)
        case enhanceTapped
        case enhanceResponse(Result<EnhanceResult, Error>)
        case useOriginalTapped
        case useEnhancedTapped
        case providerChanged(String)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .promptChanged(let newPrompt):
                state.prompt = newPrompt
                // Reset enhanced state when user changes the original prompt
                if state.showEnhanced {
                    state.enhancedPrompt = nil
                    state.showEnhanced = false
                }
                return .none

            case .enhanceTapped:
                guard state.canEnhance else { return .none }
                state.isEnhancing = true

                let prompt = state.prompt
                let provider = state.selectedProvider

                let request = EnhanceRequest(prompt: prompt, provider: provider)

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/prompts/enhance",
                            body: request,
                            as: EnhanceResult.self
                        )
                    }
                    await send(.enhanceResponse(result))
                }

            case .enhanceResponse(.success(let result)):
                state.isEnhancing = false
                state.enhancedPrompt = result.enhanced
                state.showEnhanced = true
                return .none

            case .enhanceResponse(.failure):
                state.isEnhancing = false
                return .none

            case .useOriginalTapped:
                state.showEnhanced = false
                return .none

            case .useEnhancedTapped:
                if state.enhancedPrompt != nil {
                    state.showEnhanced = true
                }
                return .none

            case .providerChanged(let provider):
                state.selectedProvider = provider
                return .none
            }
        }
    }
}

// MARK: - API Request

struct EnhanceRequest: Codable, Sendable {
    let prompt: String
    let provider: String
}
