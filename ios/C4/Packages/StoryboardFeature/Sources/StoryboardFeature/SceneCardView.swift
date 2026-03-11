import CoreKit
import SwiftUI

struct SceneCardView: View {
    let scene: Scene
    let sceneNumber: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header: scene number + duration badge
                HStack {
                    Text("#\(sceneNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())

                    Spacer()

                    Text(String(format: "%.1fs", scene.durationSeconds))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }

                // Generation status thumbnail
                generationStatus
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Narration text excerpt (2 lines)
                if !scene.narrationText.isEmpty {
                    Text(scene.narrationText)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                } else {
                    Text("No narration")
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.tertiary)
                }

                // Visual prompt (1 line, dimmed)
                if !scene.visualPrompt.isEmpty {
                    Text(scene.visualPrompt)
                        .font(.caption2)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(width: 160)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var generationStatus: some View {
        if let assetId = scene.assetId {
            // Has generated asset - show thumbnail with green check
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(
                    url: URL(string: "http://localhost:3000/api/assets/\(assetId)/thumbnail")
                ) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderWithCheck
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderWithCheck
                    }
                }

                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(4)
            }
        } else {
            // No asset - empty circle
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
    }

    private var placeholderWithCheck: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(4)
        }
    }
}
