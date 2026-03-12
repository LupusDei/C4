import SwiftUI

// MARK: - StickyCtaOverlay
// Bugs addressed:
//   C4-004.12.2   — Reduce Transparency: solid background when enabled

public struct StickyCtaOverlay<Content: View>: View {
    let content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Divider()
            content
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.sm)
        }
        .background(overlayBackground)
    }

    @ViewBuilder
    private var overlayBackground: some View {
        // Bug C4-004.12.2 — solid color when Reduce Transparency is on
        if reduceTransparency {
            ThemeColors.cardBackground
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}
