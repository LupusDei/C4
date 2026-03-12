import CoreKit
import SwiftUI

// MARK: - Masonry Result Grid

/// Displays generation result cards in a 2-column masonry-style grid
/// with 12pt spacing and fade-up entrance animation.
public struct MasonryResultGrid: View {
    let asset: Asset
    let onReset: () -> Void
    let mediaType: MediaType

    public enum MediaType {
        case image
        case video
    }

    public init(asset: Asset, mediaType: MediaType, onReset: @escaping () -> Void) {
        self.asset = asset
        self.mediaType = mediaType
        self.onReset = onReset
    }

    @State private var appeared = false

    public var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            // Result card spans full width
            resultCard
                .gridCellColumns(2)

            // Metadata cards in 2-column layout
            metadataCard(
                icon: "creditcard",
                label: "Cost",
                value: "\(asset.creditCost) credits"
            )

            metadataCard(
                icon: "cpu",
                label: "Provider",
                value: asset.provider
            )

            // Action card spans full width
            actionCard
                .gridCellColumns(2)
        }
        .padding(.top, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private var resultCard: some View {
        Group {
            switch mediaType {
            case .image:
                if asset.filePath != nil {
                    AsyncImage(url: URL(string: "http://localhost:3000/api/assets/\(asset.id)/file")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            imagePlaceholder
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            case .video:
                if let url = URL(string: "http://localhost:3000/api/assets/\(asset.id)/file") {
                    VideoThumbnailView(url: url)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func metadataCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var actionCard: some View {
        Button(action: onReset) {
            Text("Generate Another")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .frame(height: 200)
            .overlay {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Failed to load")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

// MARK: - Video Thumbnail View

/// Simple video thumbnail using AVKit.
import AVKit

struct VideoThumbnailView: View {
    let url: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
    }
}
