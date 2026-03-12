import ComposableArchitecture
import CoreKit
import SwiftUI

struct SceneCardView: View {
    let scene: CoreKit.Scene
    let generationStatus: StoryboardReducer.SceneGenerationStatus
    let progress: Double
    let onRegenerate: () -> Void
    let onVariations: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            narrationSection
            promptSection
            durationRow
            statusOverlay
        }
        .frame(width: 300)
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 41/255, green: 37/255, blue: 36/255), lineWidth: 1) // #292524 film-frame border
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contextMenu {
            Button {
                onVariations()
            } label: {
                Label("Variations", systemImage: "square.grid.2x2")
            }

            Button {
                onRegenerate()
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            // Scene number in serif type, top-left
            Text("Scene \(scene.orderIndex + 1)")
                .font(.system(.headline, design: .serif))

            Spacer()

            statusBadge
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch generationStatus {
        case .idle:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.secondary)
                .font(.caption)

        case .generating:
            ProgressView()
                .controlSize(.mini)

        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)

        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    // MARK: - Narration (New York Italic)

    private var narrationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Narration")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            Text(scene.narrationText)
                .font(.system(.caption, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
    }

    // MARK: - Visual Prompt (regular weight)

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Visual")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            Text(scene.visualPrompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    // MARK: - Duration

    private var durationRow: some View {
        HStack {
            Label(
                String(format: "%.1fs", scene.durationSeconds),
                systemImage: "clock"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)

            Spacer()

            if scene.assetId != nil {
                thumbnailPreview
            }
        }
    }

    // MARK: - Thumbnail Preview

    private var thumbnailPreview: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
            .frame(width: 32, height: 18)
            .overlay {
                Image(systemName: "photo.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Status Overlay

    @ViewBuilder
    private var statusOverlay: some View {
        switch generationStatus {
        case .generating:
            VStack(spacing: 4) {
                ProgressView(value: progress, total: 100)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)

                Text("\(Int(progress))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .failed(let error):
            VStack(spacing: 6) {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)

                Button {
                    onRegenerate()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

        default:
            EmptyView()
        }
    }
}
