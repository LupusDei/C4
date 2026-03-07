import AVKit
import ComposableArchitecture
import CoreKit
import Foundation
import SwiftUI

@Reducer
public struct VideoExtendReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public let sourceAsset: Asset
        public var continuationPrompt: String = ""
        public var targetDuration: Int = 15
        public var status: ExtendStatus = .idle

        public init(sourceAsset: Asset) {
            self.sourceAsset = sourceAsset
        }

        public var canExtend: Bool {
            !continuationPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !isExtending
        }

        public var isExtending: Bool {
            if case .extending = status { return true }
            if case .progress = status { return true }
            return false
        }

        public var estimatedCreditCost: Int {
            targetDuration * 5
        }
    }

    public enum ExtendStatus: Equatable, Sendable {
        case idle
        case extending
        case progress(Double)
        case complete(Asset)
        case error(String)
    }

    public enum Action: Sendable {
        case setContinuationPrompt(String)
        case setTargetDuration(Int)
        case extendTapped
        case extendResponse(Result<GenerationJob, Error>)
        case progressUpdate(WebSocketMessage)
        case assetLoaded(Result<Asset, Error>)
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.webSocketClient) var webSocketClient

    private enum CancelID { case extend, progress }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setContinuationPrompt(let prompt):
                state.continuationPrompt = prompt
                return .none

            case .setTargetDuration(let duration):
                state.targetDuration = max(5, min(30, duration))
                return .none

            case .extendTapped:
                guard state.canExtend else { return .none }
                state.status = .extending

                let request = VideoExtendRequest(
                    assetId: state.sourceAsset.id,
                    prompt: state.continuationPrompt,
                    maxDuration: state.targetDuration
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/generate/video/extend",
                            body: request,
                            as: GenerationJob.self
                        )
                    }
                    await send(.extendResponse(result))
                }
                .cancellable(id: CancelID.extend)

            case .extendResponse(.success(let job)):
                state.status = .progress(0)

                return .run { send in
                    for await message in await webSocketClient.progressUpdates(job.id) {
                        await send(.progressUpdate(message))
                    }
                }
                .cancellable(id: CancelID.progress)

            case .extendResponse(.failure(let error)):
                state.status = .error(error.localizedDescription)
                return .none

            case .progressUpdate(let message):
                if let progress = message.progress {
                    state.status = .progress(progress)
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
                    state.status = .error(message.error ?? "Video extension failed")
                    return .cancel(id: CancelID.progress)
                }

                return .none

            case .assetLoaded(.success(let asset)):
                state.status = .complete(asset)
                return .none

            case .assetLoaded(.failure(let error)):
                state.status = .error(error.localizedDescription)
                return .none
            }
        }
    }
}

// MARK: - Request

struct VideoExtendRequest: Codable, Sendable {
    let assetId: UUID
    let prompt: String
    let maxDuration: Int
}

// MARK: - View

public struct VideoExtendView: View {
    @Bindable var store: StoreOf<VideoExtendReducer>

    public init(store: StoreOf<VideoExtendReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    sourceInfo
                    promptSection
                    durationSection
                    costSection
                    extendButton
                    resultSection
                }
                .padding()
            }
            .navigationTitle("Extend Video")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private var sourceInfo: some View {
        HStack {
            Image(systemName: "film.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading) {
                Text("Source: \(store.sourceAsset.prompt)")
                    .font(.subheadline)
                    .lineLimit(2)
                Text(store.sourceAsset.provider)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continuation Prompt")
                .font(.headline)

            TextEditor(text: Binding(
                get: { store.continuationPrompt },
                set: { store.send(.setContinuationPrompt($0)) }
            ))
            .frame(minHeight: 80)
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.tertiary, lineWidth: 1)
            )
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Target Duration")
                    .font(.headline)
                Spacer()
                Text("\(store.targetDuration)s")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
            }

            Slider(
                value: Binding(
                    get: { Double(store.targetDuration) },
                    set: { store.send(.setTargetDuration(Int($0))) }
                ),
                in: 5...30,
                step: 1
            )

            HStack {
                Text("5s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("30s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var costSection: some View {
        HStack {
            Image(systemName: "creditcard")
                .foregroundStyle(.secondary)
            Text("Estimated cost: **\(store.estimatedCreditCost) credits**")
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var extendButton: some View {
        Button {
            store.send(.extendTapped)
        } label: {
            HStack {
                if store.isExtending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                }
                Text(store.isExtending ? "Extending..." : "Extend Video")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.canExtend ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!store.canExtend)
    }

    @ViewBuilder
    private var resultSection: some View {
        switch store.status {
        case .idle:
            EmptyView()

        case .extending:
            VStack(spacing: 12) {
                ProgressView()
                Text("Extending video...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

        case .progress(let value):
            VStack(spacing: 12) {
                ProgressView(value: value, total: 100) {
                    Text("Extending...")
                        .font(.subheadline)
                } currentValueLabel: {
                    Text("\(Int(value))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            }
            .padding(.top, 20)

        case .complete(let asset):
            VStack(spacing: 12) {
                if let url = URL(string: "http://localhost:3000/api/assets/\(asset.id)/file") {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Label("Extended video ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .padding(.top, 20)

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    store.send(.extendTapped)
                } label: {
                    Text("Retry")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)
        }
    }
}
