import SwiftUI

// MARK: - ThemeCard
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion support
//   C4-004.2.3.1  — Configurable cornerRadius (default 16, project cards pass 8)
//   C4-004.12.4   — VoiceOver: .accessibilityElement(children: .combine)

public struct ThemeCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    @GestureState private var isPressed = false

    public init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(ThemeSpacing.md)
            .background(ThemeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(ThemeAnimation.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
            // Bug C4-004.12.4 — VoiceOver semantic grouping
            .accessibilityElement(children: .combine)
    }
}
