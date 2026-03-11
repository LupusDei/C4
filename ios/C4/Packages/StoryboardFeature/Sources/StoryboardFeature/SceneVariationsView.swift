import ComposableArchitecture
import CoreKit
import SwiftUI

struct SceneVariationsView: View {
    @Bindable var store: StoreOf<StoryboardReducer>
    let scene: CoreKit.Scene

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    originalAssetSection
                    variationsGrid
                    generateSection
                }
                .padding()
            }
            .navigationTitle("Scene \(scene.orderIndex + 1) Variations")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        store.send(.dismissVariations)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visual Prompt")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            Text(scene.visualPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Original Asset

    @ViewBuilder
    private var originalAssetSection: some View {
        if let assetId = scene.assetId {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                assetCell(assetId: assetId, label: "Original", isCurrent: true)
            }
        }
    }

    // MARK: - Variations Grid

    @ViewBuilder
    private var variationsGrid: some View {
        let variations = store.variationAssets[scene.id] ?? []

        if !variations.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Variations")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    ForEach(variations) { asset in
                        variationCell(asset: asset)
                    }
                }
            }
        }
    }

    // MARK: - Asset Cell

    private func assetCell(assetId: UUID, label: String, isCurrent: Bool) -> some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: "http://localhost:3000/api/assets/\(assetId)/file")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                @unknown default:
                    EmptyView()
                }
            }

            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isCurrent {
                    Label("Current", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrent ? .green.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Variation Cell

    private func variationCell(asset: Asset) -> some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: "http://localhost:3000/api/assets/\(asset.id)/file")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    placeholderView
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                @unknown default:
                    EmptyView()
                }
            }

            Text(asset.prompt)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Button {
                store.send(.selectWinner(sceneId: scene.id, assetId: asset.id))
            } label: {
                Text("Use This")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .frame(height: 120)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Generate Section

    private var generateSection: some View {
        VStack(spacing: 12) {
            if store.isGeneratingVariations {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Generating variations...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                HStack(spacing: 12) {
                    Button {
                        store.send(.generateVariations(
                            sceneId: scene.id,
                            count: 2,
                            provider: .standard
                        ))
                    } label: {
                        Label("2 Variations", systemImage: "square.grid.2x2")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        store.send(.generateVariations(
                            sceneId: scene.id,
                            count: 3,
                            provider: .standard
                        ))
                    } label: {
                        Label("3 Variations", systemImage: "square.grid.3x3")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}
