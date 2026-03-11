import ComposableArchitecture
import CoreKit
import Foundation
import PromptFeature

@Reducer
public struct VideoGenerateReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var prompt: String = ""
        public var promptEnhancer = PromptEnhancerReducer.State()
        public var mode: Mode = .textToVideo
        public var sourceAssetId: UUID?
        public var duration: Int = 5
        public var resolution: Resolution = .hd720
        public var selectedProvider: Provider = .auto
        public var qualityTier: QualityTier = .standard
        public var selectedProjectId: UUID?
        public var aspectRatio: AspectRatio = .landscape
        public var generationStatus: GenerationStatus = .idle

        public init() {}

        public var isGenerating: Bool {
            if case .generating = generationStatus { return true }
            if case .progress = generationStatus { return true }
            return false
        }

        public var canGenerate: Bool {
            let hasPrompt = !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasSource = mode == .imageToVideo ? sourceAssetId != nil : true
            return hasPrompt && hasSource && !isGenerating && selectedProjectId != nil
        }

        public var estimatedCreditCost: Int {
            let perSecond: Int = switch qualityTier {
            case .budget: 3
            case .standard: 8
            case .premium: 15
            }
            return perSecond * duration
        }
    }

    public enum Mode: String, CaseIterable, Codable, Sendable {
        case textToVideo = "text-to-video"
        case imageToVideo = "image-to-video"

        public var displayName: String {
            switch self {
            case .textToVideo: "Text to Video"
            case .imageToVideo: "Image to Video"
            }
        }
    }

    public enum Resolution: String, CaseIterable, Codable, Sendable {
        case sd480 = "480p"
        case hd720 = "720p"

        public var displayName: String { rawValue }
    }

    public enum Provider: String, CaseIterable, Codable, Sendable {
        case auto
        case kling
        case runway
        case hailuo
        case grokImagine = "grok-imagine"

        public var displayName: String {
            switch self {
            case .auto: "Auto (Best for tier)"
            case .kling: "Kling 3.0 (fal.ai)"
            case .runway: "Runway Gen-4"
            case .hailuo: "Hailuo (fal.ai)"
            case .grokImagine: "Grok Imagine Video"
            }
        }
    }

    public enum QualityTier: String, CaseIterable, Codable, Sendable {
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
        case setMode(Mode)
        case setSourceAsset(UUID?)
        case setDuration(Int)
        case setResolution(Resolution)
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

            case .setMode(let mode):
                state.mode = mode
                if mode == .textToVideo { state.sourceAssetId = nil }
                return .none

            case .setSourceAsset(let id):
                state.sourceAssetId = id
                return .none

            case .setDuration(let duration):
                state.duration = max(1, min(15, duration))
                return .none

            case .setResolution(let resolution):
                state.resolution = resolution
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

            case .generateTapped:
                guard state.canGenerate, let projectId = state.selectedProjectId else { return .none }
                state.generationStatus = .generating

                let effectivePrompt = state.promptEnhancer.effectivePrompt

                let request = VideoGenerateRequest(
                    prompt: effectivePrompt,
                    mode: state.mode.rawValue,
                    sourceAssetId: state.sourceAssetId,
                    duration: state.duration,
                    resolution: state.resolution.rawValue,
                    provider: state.selectedProvider == .auto ? nil : state.selectedProvider.rawValue,
                    qualityTier: state.qualityTier.rawValue,
                    projectId: projectId,
                    aspectRatio: state.aspectRatio.rawValue
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/generate/video",
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
                return .none

            case .progressUpdate(let message):
                if let progress = message.progress {
                    state.generationStatus = .progress(progress)
                }

                if message.isComplete, let assetId = message.assetId {
                    return .run { send in
                        let result = await Result {
                            try await apiClient.get("/api/assets/\(assetId)", as: Asset.self)
                        }
                        await send(.assetLoaded(result))
                    }
                }

                if message.isFailed {
                    state.generationStatus = .error(message.error ?? "Video generation failed")
                    return .cancel(id: CancelID.progress)
                }

                return .none

            case .assetLoaded(.success(let asset)):
                state.generationStatus = .complete(asset)
                return .none

            case .assetLoaded(.failure(let error)):
                state.generationStatus = .error(error.localizedDescription)
                return .none

            case .reset:
                state.prompt = ""
                state.promptEnhancer = PromptEnhancerReducer.State()
                state.generationStatus = .idle
                state.sourceAssetId = nil
                return .merge(
                    .cancel(id: CancelID.generation),
                    .cancel(id: CancelID.progress)
                )
            }
        }
    }
}

// MARK: - API Request

struct VideoGenerateRequest: Codable, Sendable {
    let prompt: String
    let mode: String
    let sourceAssetId: UUID?
    let duration: Int
    let resolution: String
    let provider: String?
    let qualityTier: String
    let projectId: UUID
    let aspectRatio: String
}
