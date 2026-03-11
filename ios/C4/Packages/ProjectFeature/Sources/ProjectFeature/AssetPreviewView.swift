import AVKit
import ComposableArchitecture
import CoreKit
import GenerateFeature
import SwiftUI

@Reducer
public struct AssetPreviewReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public let asset: Asset
        public var showExtendSheet: Bool = false
        public var showSaveStyleSheet: Bool = false
        public var extractedStyle: ExtractedStyle?
        public var editStyleName: String = ""
        public var editStyleDescription: String = ""
        public var editStyleCategory: String = "abstract"
        public var isExtractingStyle: Bool = false
        public var isSavingStyle: Bool = false
        public var styleError: String?
        public var styleSaved: Bool = false

        public init(asset: Asset) {
            self.asset = asset
        }

        public var isVideo: Bool { asset.type == .video }
        public var assetFileURL: URL? {
            URL(string: "http://localhost:3000/api/assets/\(asset.id)/file")
        }
    }

    public enum Action: Sendable {
        case extendTapped
        case dismissExtendSheet
        case saveAsStyleTapped
        case styleExtracted(Result<ExtractedStyle, Error>)
        case dismissSaveStyleSheet
        case setStyleName(String)
        case setStyleDescription(String)
        case setStyleCategory(String)
        case confirmSaveStyle
        case styleSaved(Result<StylePreset, Error>)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .extendTapped:
                state.showExtendSheet = true
                return .none

            case .dismissExtendSheet:
                state.showExtendSheet = false
                return .none

            case .saveAsStyleTapped:
                state.isExtractingStyle = true
                state.styleError = nil
                state.styleSaved = false
                let prompt = state.asset.prompt

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/styles/extract",
                            body: ExtractStyleRequest(prompt: prompt),
                            as: ExtractedStyle.self
                        )
                    }
                    await send(.styleExtracted(result))
                }

            case .styleExtracted(.success(let style)):
                state.isExtractingStyle = false
                state.extractedStyle = style
                state.editStyleName = style.name
                state.editStyleDescription = style.description
                state.editStyleCategory = style.category
                state.showSaveStyleSheet = true
                return .none

            case .styleExtracted(.failure(let error)):
                state.isExtractingStyle = false
                state.styleError = error.localizedDescription
                return .none

            case .dismissSaveStyleSheet:
                state.showSaveStyleSheet = false
                state.extractedStyle = nil
                return .none

            case .setStyleName(let name):
                state.editStyleName = name
                return .none

            case .setStyleDescription(let desc):
                state.editStyleDescription = desc
                return .none

            case .setStyleCategory(let category):
                state.editStyleCategory = category
                return .none

            case .confirmSaveStyle:
                guard let extracted = state.extractedStyle else { return .none }
                state.isSavingStyle = true

                let request = SaveAsStyleRequest(
                    name: state.editStyleName,
                    description: state.editStyleDescription,
                    promptModifier: extracted.promptModifier,
                    category: state.editStyleCategory
                )

                return .run { send in
                    let result = await Result {
                        try await apiClient.post(
                            "/api/styles",
                            body: request,
                            as: StylePreset.self
                        )
                    }
                    await send(.styleSaved(result))
                }

            case .styleSaved(.success):
                state.isSavingStyle = false
                state.styleSaved = true
                state.showSaveStyleSheet = false
                state.extractedStyle = nil
                return .none

            case .styleSaved(.failure(let error)):
                state.isSavingStyle = false
                state.styleError = error.localizedDescription
                return .none
            }
        }
    }
}

// MARK: - API Requests

struct ExtractStyleRequest: Codable, Sendable {
    let prompt: String
}

struct SaveAsStyleRequest: Codable, Sendable {
    let name: String
    let description: String
    let promptModifier: String
    let category: String
}

public struct AssetPreviewView: View {
    @Bindable var store: StoreOf<AssetPreviewReducer>
    @State private var scale: CGFloat = 1.0

    public init(store: StoreOf<AssetPreviewReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            mediaContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            metadataBar
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        store.send(.saveAsStyleTapped)
                    } label: {
                        Label("Save as Style", systemImage: "paintpalette")
                    }
                    .disabled(store.isExtractingStyle)

                    if store.isVideo {
                        Button {
                            store.send(.extendTapped)
                        } label: {
                            Label("Extend Video", systemImage: "arrow.right.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showExtendSheet },
            set: { if !$0 { store.send(.dismissExtendSheet) } }
        )) {
            VideoExtendSheetWrapper(asset: store.asset)
        }
        .sheet(isPresented: Binding(
            get: { store.showSaveStyleSheet },
            set: { if !$0 { store.send(.dismissSaveStyleSheet) } }
        )) {
            saveStyleSheet
        }
        .overlay {
            if store.isExtractingStyle {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Extracting style...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .overlay(alignment: .top) {
            if store.styleSaved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Style saved!")
                        .font(.subheadline.weight(.medium))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Media Content

    @ViewBuilder
    private var mediaContent: some View {
        if store.isVideo {
            videoPlayer
        } else {
            zoomableImage
        }
    }

    private var videoPlayer: some View {
        Group {
            if let url = store.assetFileURL {
                VideoPlayer(player: AVPlayer(url: url))
            } else {
                mediaErrorPlaceholder
            }
        }
    }

    private var zoomableImage: some View {
        Group {
            if let url = store.assetFileURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        scale = value.magnification
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = max(1.0, min(scale, 5.0))
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    scale = scale > 1.0 ? 1.0 : 2.0
                                }
                            }
                    case .failure:
                        mediaErrorPlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                mediaErrorPlaceholder
            }
        }
    }

    private var mediaErrorPlaceholder: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Failed to load media")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Metadata

    private var metadataBar: some View {
        VStack(spacing: 8) {
            Text(store.asset.prompt)
                .font(.subheadline)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Label(store.asset.provider, systemImage: "cpu")
                Label(store.asset.qualityTier, systemImage: "dial.low")
                Label("\(store.asset.creditCost) credits", systemImage: "creditcard")
                Spacer()
                Label(store.asset.type.rawValue, systemImage: store.isVideo ? "film" : "photo")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Save Style Sheet

    private var saveStyleSheet: some View {
        NavigationStack {
            Form {
                Section("Style Name") {
                    TextField("Name", text: Binding(
                        get: { store.editStyleName },
                        set: { store.send(.setStyleName($0)) }
                    ))
                }

                Section("Description") {
                    TextField("Description", text: Binding(
                        get: { store.editStyleDescription },
                        set: { store.send(.setStyleDescription($0)) }
                    ))
                }

                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { store.editStyleCategory },
                        set: { store.send(.setStyleCategory($0)) }
                    )) {
                        Text("Cinematic").tag("cinematic")
                        Text("Photography").tag("photography")
                        Text("Illustration").tag("illustration")
                        Text("Digital Art").tag("digital-art")
                        Text("Retro").tag("retro")
                        Text("Abstract").tag("abstract")
                    }
                }

                if let extracted = store.extractedStyle {
                    Section("Style Modifier (Preview)") {
                        Text(extracted.promptModifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = store.styleError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Save as Style")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.dismissSaveStyleSheet)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.confirmSaveStyle)
                    }
                    .disabled(store.editStyleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSavingStyle)
                }
            }
        }
    }
}

// MARK: - Video Extend Sheet Wrapper

private struct VideoExtendSheetWrapper: View {
    let asset: Asset

    var body: some View {
        VideoExtendView(
            store: Store(initialState: VideoExtendReducer.State(sourceAsset: asset)) {
                VideoExtendReducer()
            }
        )
    }
}
