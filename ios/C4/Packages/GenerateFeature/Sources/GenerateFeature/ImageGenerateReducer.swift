import ComposableArchitecture
import CoreKit
import Foundation
import PromptFeature

@Reducer
public struct ImageGenerateReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var prompt: String = ""
        public var promptEnhancer = PromptEnhancerReducer.State()
        public var selectedProvider: Provider = .auto
        public var qualityTier: QualityTier = .standard
        public var selectedProjectId: UUID?
        public var aspectRatio: AspectRatio = .square
        public var generationStatus: GenerationStatus = .idle
        public var selectedStyle: StylePreset?
        public var showStylePicker: Bool = false
        @Presents public var stylePicker: StylePickerReducer.State?
        public var isHistoryPresented: Bool = false
        @Presents public var history: PromptHistoryReducer.State?
        public var activityMode: ActivityMode = .idle
        public var showCompletionToast: Bool = false

        public init() {}

        public var isGenerating: Bool {
            if case .generating = generationStatus { return true }
            if case .progress = generationStatus { return true }
            return false
        }

        public var canGenerate: Bool {
            !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !isGenerating
                && selectedProjectId != nil
        }

        public var estimatedCreditCost: Int {
            switch qualityTier {
            case .budget: 2
            case .standard: 5
            case .premium: 10
            }
        }
    }

    public enum Provider: String, CaseIterable, Codable, Sendable {
        case auto
        case openai
        case flux
        case grokImagine = "grok-imagine"
        case nanoBanana = "nano-banana"

        public var displayName: String {
            switch self {
            case .auto: "Auto (Best for tier)"
            case .openai: "OpenAI GPT Image"
            case .flux: "FLUX (fal.ai)"
            case .grokImagine: "Grok Imagine"
            case .nanoBanana: "Imagen (Nano Banana)"
            }
        }
    }

    public enum QualityTier: String, CaseIterable, Codable, Sendable {
        case budget
        case standard
        case premium

        public var displayName: String {
            switch self {
            case .budget: "Budget (2 credits)"
            case .standard: "Standard (5 credits)"
            case .premium: "Premium (10 credits)"
            }
        }
    }

    public enum AspectRatio: String, CaseIterable, Codable, Sendable {
        case square = "1:1"
        case landscape = "16:9"
        case portrait = "9:16"
        case classic = "4:3"
    }

    public enum GenerationStatus: Equatable, Sendable {
        case idle
        case generating
        case progress(Double)
        case complete(Asset)
        case error(String)
    }

    public enum Action: Sendable {
        case setPrompt(String)
        case setProvider(Provider)
        case setQualityTier(QualityTier)
        case setProject(UUID?)
        case setAspectRatio(AspectRatio)
        case generateTapped
        case generationResponse(Result<GenerationJob, Error>)
        case progressUpdate(WebSocketMessage)
        case assetLoaded(Result<Asset, Error>)
        case reset
        case promptEnhancer(PromptEnhancerReducer.Action)
        case styleButtonTapped
        case dismissStylePicker
        case stylePicker(PresentationAction<StylePickerReducer.Action>)
        case setDefaultStyle(StylePreset?)
        case historyTapped
        case setHistoryPresented(Bool)
        case history(PresentationAction<PromptHistoryReducer.Action>)
        case loadPromptFromHistory(String)
        case setActivityMode(ActivityMode)
        case dismissCompletionToast
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient

    private enum CancelID { case generation, progress }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.promptEnhancer, action: \.promptEnhancer) {
            PromptEnhancerReducer()
        }

        Reduce { state, action in
            switch action {
            case .setPrompt(let prompt):
                state.prompt = prompt
                state.promptEnhancer.prompt = prompt
                return .none

            case .setProvider(let provider):
                state.selectedProvider = provider
                state.promptEnhancer.selectedProvider = provider == .auto ? "auto" : provider.rawValue
                return .none

            case .promptEnhancer(.promptChanged(let newPrompt)):
                state.prompt = newPrompt
                return .none

            case .promptEnhancer:
                return .none

            case .setQualityTier(let tier):
                state.qualityTier = tier
                return .none

            case .setProject(let projectId):
                state.selectedProjectId = projectId
                return .none

            case .setAspectRatio(let ratio):
                state.aspectRatio = ratio
                return .none

            case .setActivityMode(let mode):
                state.activityMode = mode
                return .none

            case .dismissCompletionToast:
                state.showCompletionToast = false
                return .none

            case .generateTapped:
                guard state.canGenerate, let projectId = state.selectedProjectId else { return .none }
                state.generationStatus = .generating
                state.activityMode = .generating

                // Use enhanced prompt if available, then append style modifier
                var fullPrompt = state.promptEnhancer.effectivePrompt
                if let style = state.selectedStyle {
                    fullPrompt = "\(fullPrompt), \(style.promptModifier)"
                }

                let request = ImageGenerateRequest(
                    prompt: fullPrompt,
                    provider: state.selectedProvider == .auto ? nil : state.selectedProvider.rawValue,
                    qualityTier: state.qualityTier.rawValue,
                    projectId: projectId,
                    aspectRatio: state.aspectRatio.rawValue
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/generate/image",
                            body: request,
                            as: GenerationJob.self
                        )
                    }
                    await send(.generationResponse(result))
                }
                .cancellable(id: CancelID.generation)

            case .generationResponse(.success(let job)):
                state.generationStatus = .progress(0)

                return .run { send in
                    for await message in await webSocketClient.progressUpdates(job.id) {
                        await send(.progressUpdate(message))
                    }
                }
                .cancellable(id: CancelID.progress)

            case .generationResponse(.failure(let error)):
                state.generationStatus = .error(error.localizedDescription)
                state.activityMode = .idle
                return .none

            case .progressUpdate(let message):
                if let progress = message.progress {
                    state.generationStatus = .progress(progress)
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
                    state.generationStatus = .error(message.error ?? "Generation failed")
                    return .cancel(id: CancelID.progress)
                }

                return .none

            case .assetLoaded(.success(let asset)):
                state.generationStatus = .complete(asset)
                state.activityMode = .idle
                state.showCompletionToast = true
                return .run { send in
                    try await Task.sleep(for: .seconds(3))
                    await send(.dismissCompletionToast)
                }

            case .assetLoaded(.failure(let error)):
                state.generationStatus = .error(error.localizedDescription)
                state.activityMode = .idle
                return .none

            case .reset:
                state.prompt = ""
                state.promptEnhancer = PromptEnhancerReducer.State()
                state.generationStatus = .idle
                state.activityMode = .idle
                state.showCompletionToast = false
                return .merge(
                    .cancel(id: CancelID.generation),
                    .cancel(id: CancelID.progress)
                )

            case .styleButtonTapped:
                state.stylePicker = StylePickerReducer.State(selectedPreset: state.selectedStyle)
                return .none

            case .dismissStylePicker:
                state.stylePicker = nil
                return .none

            case .stylePicker(.presented(.presetSelected(let preset))):
                state.selectedStyle = preset
                return .none

            case .stylePicker:
                return .none

            case .setDefaultStyle(let preset):
                state.selectedStyle = preset
                return .none

            case .historyTapped:
                state.history = PromptHistoryReducer.State()
                state.isHistoryPresented = true
                return .none

            case .setHistoryPresented(let presented):
                state.isHistoryPresented = presented
                if !presented { state.history = nil }
                return .none

            case .history(.presented(.entryTapped(let entry))):
                let prompt = entry.enhancedPrompt ?? entry.originalPrompt
                state.prompt = prompt
                state.promptEnhancer.prompt = prompt
                state.isHistoryPresented = false
                state.history = nil
                return .none

            case .history(.presented(.remixResponse(.success(let result)))):
                state.prompt = result.remixed
                state.promptEnhancer.prompt = result.remixed
                state.isHistoryPresented = false
                state.history = nil
                return .none

            case .history:
                return .none

            case .loadPromptFromHistory(let prompt):
                state.prompt = prompt
                state.promptEnhancer.prompt = prompt
                return .none
            }
        }
        .ifLet(\.$stylePicker, action: \.stylePicker) {
            StylePickerReducer()
        }
        .ifLet(\.$history, action: \.history) {
            PromptHistoryReducer()
        }
    }
}

// MARK: - API Request

struct ImageGenerateRequest: Codable, Sendable {
    let prompt: String
    let provider: String?
    let qualityTier: String
    let projectId: UUID
    let aspectRatio: String
}
