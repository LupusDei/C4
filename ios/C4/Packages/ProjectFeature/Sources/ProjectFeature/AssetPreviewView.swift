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
    }

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
            }
        }
    }
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
            if store.isVideo {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.extendTapped)
                    } label: {
                        Label("Extend", systemImage: "arrow.right.circle")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showExtendSheet },
            set: { if !$0 { store.send(.dismissExtendSheet) } }
        )) {
            VideoExtendSheetWrapper(asset: store.asset)
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
