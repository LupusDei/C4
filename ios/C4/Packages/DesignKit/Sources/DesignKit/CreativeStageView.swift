import SwiftUI

// MARK: - CreativeStageView
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion (ThemeAnimation.spring)
//   C4-004.12.4   — VoiceOver: accessibilityLabel + accessibilityHint

public struct CreativeStageView: View {
    let prompt: String
    let isExpanded: Bool
    let onTap: () -> Void

    @GestureState private var isPressed = false

    public init(
        prompt: String,
        isExpanded: Bool,
        onTap: @escaping () -> Void
    ) {
        self.prompt = prompt
        self.isExpanded = isExpanded
        self.onTap = onTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .foregroundStyle(ThemeColors.accent)

                Text("Creative Prompt")
                    .font(ThemeTypography.headline)

                Spacer()

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColors.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .animation(ThemeAnimation.spring, value: isExpanded)
            }

            if isExpanded {
                Text(prompt.isEmpty ? "Tap to enter your creative vision..." : prompt)
                    .font(ThemeTypography.body)
                    .foregroundStyle(prompt.isEmpty ? ThemeColors.secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ThemeSpacing.sm)
                    .background(ThemeColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(ThemeAnimation.snappy, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
        .onTapGesture { onTap() }
        // Bug C4-004.12.4 — VoiceOver semantic label and hint
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Prompt input")
        .accessibilityHint("Tap to expand")
        .accessibilityValue(prompt.isEmpty ? "Empty" : prompt)
        .accessibilityAddTraits(.isButton)
    }
}
