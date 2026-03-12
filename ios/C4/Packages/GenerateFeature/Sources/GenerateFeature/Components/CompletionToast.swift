import SwiftUI

// MARK: - Completion Toast

/// A brief success notification shown at the top of the screen when generation completes.
/// Auto-dismisses after a configurable duration.
public struct CompletionToast: View {
    let message: String
    let icon: String
    let isPresented: Bool

    public init(
        message: String,
        icon: String = "checkmark.circle.fill",
        isPresented: Bool
    ) {
        self.message = message
        self.icon = icon
        self.isPresented = isPresented
    }

    public var body: some View {
        if isPresented {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.green)
                Text(message)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, 8)
        }
    }
}
