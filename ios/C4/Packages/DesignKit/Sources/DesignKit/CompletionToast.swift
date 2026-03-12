import SwiftUI

/// A warm banner toast that slides from the top to notify the user of completed generations.
///
/// Features:
/// - Slides in from top with offset + opacity transition
/// - Shows thumbnail, message, and "View" action button
/// - Auto-dismisses after 4 seconds
///
/// Usage:
/// ```swift
/// .overlay(alignment: .top) {
///     if let toast = toastInfo {
///         CompletionToast(
///             message: "Your image is ready",
///             thumbnailURL: toast.thumbnailURL,
///             onView: { navigateToAsset(toast.assetId) },
///             onDismiss: { toastInfo = nil }
///         )
///     }
/// }
/// ```
public struct CompletionToast: View {
    let message: String
    let thumbnailURL: URL?
    let onView: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false

    public init(
        message: String = "Your image is ready",
        thumbnailURL: URL? = nil,
        onView: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.thumbnailURL = thumbnailURL
        self.onView = onView
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Image(systemName: "photo.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            // Message
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // View button
            // TODO: Replace with ThemeButton(.quiet) from DesignKit when available
            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onView()
                    onDismiss()
                }
            }) {
                Text("View")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Dismiss
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .offset(y: isVisible ? 0 : -80)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isVisible = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(4))
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = false
            }
            try? await Task.sleep(for: .seconds(0.3))
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Completion Toast") {
    struct ToastDemo: View {
        @State private var showToast = false

        var body: some View {
            ZStack(alignment: .top) {
                VStack {
                    Spacer()
                    Button("Show Toast") {
                        showToast = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }

                if showToast {
                    CompletionToast(
                        message: "Your image is ready",
                        thumbnailURL: nil,
                        onView: { print("View tapped") },
                        onDismiss: { showToast = false }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    return ToastDemo()
}
