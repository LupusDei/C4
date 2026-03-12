import ComposableArchitecture
import CoreKit
import SwiftUI

public struct StudioView: View {
    @Bindable var store: StoreOf<StudioReducer>

    public init(store: StoreOf<StudioReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                projectSpotlight
                recentGenerationsSection
                creditBalanceCard
                continueWhereYouLeftOff
                quickPresetsSection
            }
            .padding()
        }
        .navigationTitle("Studio")
        .refreshable {
            store.send(.refresh)
        }
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Project Spotlight

    // TODO: Replace with ThemeCard from DesignKit when available
    private var projectSpotlight: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let project = store.currentProject {
                Button {
                    store.send(.projectTapped)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        // Hero image placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 160)
                            .overlay {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Project")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            Text(project.title)
                                .font(.system(.title2, design: .serif))
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Text(project.updatedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .buttonStyle(.plain)
            } else if store.isLoadingProject {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No projects yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    // MARK: - Recent Generations Carousel

    private var recentGenerationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Generations")
                .font(.system(.headline, design: .serif))

            if store.isLoadingGenerations && store.recentGenerations.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if store.recentGenerations.isEmpty {
                Text("No generations yet. Start creating!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(store.recentGenerations) { asset in
                            generationThumbnail(asset)
                                .onTapGesture {
                                    store.send(.generationTapped(asset))
                                }
                        }
                    }
                    .padding(.horizontal, 1) // Prevent shadow clipping
                }
            }
        }
    }

    private func generationThumbnail(_ asset: Asset) -> some View {
        AsyncImage(
            url: URL(string: "http://localhost:3000/api/assets/\(asset.id)/thumbnail")
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                thumbnailPlaceholder(for: asset)
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                thumbnailPlaceholder(for: asset)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomTrailing) {
            if asset.type == .video {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(4)
            }
        }
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func thumbnailPlaceholder(for asset: Asset) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .overlay {
                Image(systemName: asset.type == .video ? "film" : "photo")
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Credit Balance Card

    // TODO: Replace with ThemeCard from DesignKit when available
    private var creditBalanceCard: some View {
        Button {
            store.send(.creditBalanceTapped)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credit Balance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if store.isLoadingBalance {
                        ProgressView()
                    } else {
                        Text("\(store.creditBalance)")
                            .font(.system(size: 36, weight: .thin, design: .default))
                            .foregroundStyle(.primary)
                    }

                    Text("credits available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Image(systemName: "creditcard.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue Where You Left Off

    private var continueWhereYouLeftOff: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Where You Left Off")
                .font(.system(.headline, design: .serif))

            if store.isLoadingLastEdited && store.lastEditedItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if store.lastEditedItems.isEmpty {
                Text("Your recent work will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.lastEditedItems) { item in
                        lastEditedRow(item)
                    }
                }
            }
        }
    }

    private func lastEditedRow(_ item: LastEditedItem) -> some View {
        Button {
            store.send(.lastEditedItemTapped(item))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: lastEditedIcon(item.type))
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(item.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func lastEditedIcon(_ type: LastEditedItemType) -> String {
        switch type {
        case .storyboard: "rectangle.stack"
        case .prompt: "text.bubble"
        case .project: "folder.fill"
        }
    }

    // MARK: - Quick Presets

    // TODO: Replace buttons with ThemeButton from DesignKit when available
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.system(.headline, design: .serif))

            HStack(spacing: 12) {
                ForEach(QualityPreset.allCases, id: \.self) { preset in
                    Button {
                        store.send(.qualityPresetTapped(preset))
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: preset.iconName)
                                .font(.title3)

                            Text(preset.displayName)
                                .font(.caption.weight(.medium))

                            Text(preset.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudioView(
            store: Store(initialState: StudioReducer.State()) {
                StudioReducer()
            }
        )
    }
}
