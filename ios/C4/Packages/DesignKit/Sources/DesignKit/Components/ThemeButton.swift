import SwiftUI

// MARK: - ThemeButton

public struct ThemeButton: View {
    public enum Tier {
        /// Full-width, 56pt height, accent fill, white serif bold text, haptic press.
        case primary
        /// Capsule, ultraThinMaterial background, accent text, 36pt height.
        case contextual
        /// Text-only, no background, charcoal semibold.
        case quiet
    }

    private let title: String
    private let systemImage: String?
    private let tier: Tier
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.themeColors) private var colors
    @State private var isPressed = false

    public init(
        _ title: String,
        systemImage: String? = nil,
        tier: Tier = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tier = tier
        self.action = action
    }

    public var body: some View {
        Button(action: handleTap) {
            label
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Label

    @ViewBuilder
    private var label: some View {
        switch tier {
        case .primary:
            primaryLabel
        case .contextual:
            contextualLabel
        case .quiet:
            quietLabel
        }
    }

    private var primaryLabel: some View {
        HStack(spacing: ThemeSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.system(size: 17, weight: .bold, design: .serif))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(isEnabled ? colors.accent : colors.accent.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(
            color: isPressed ? colors.accent.opacity(0.3) : colors.accent.opacity(0.15),
            radius: isPressed ? 6 : 3,
            y: 2
        )
        .animation(ThemeAnimation.press, value: isPressed)
    }

    private var contextualLabel: some View {
        HStack(spacing: ThemeSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
            }
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(isEnabled ? colors.accent : colors.textSecondary)
        .padding(.horizontal, ThemeSpacing.md)
        .frame(height: 36)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(ThemeAnimation.press, value: isPressed)
    }

    private var quietLabel: some View {
        HStack(spacing: ThemeSpacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(isEnabled ? colors.textPrimary : colors.textSecondary)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(ThemeAnimation.press, value: isPressed)
    }

    // MARK: - Tap Handling

    private func handleTap() {
        guard isEnabled else { return }
        isPressed = true

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }

        action()
    }
}

// MARK: - Preview

#Preview("ThemeButton — All Tiers") {
    VStack(spacing: ThemeSpacing.lg) {
        ThemeButton("Generate Image", systemImage: "sparkles", tier: .primary) {}

        ThemeButton("Generate Image", systemImage: "sparkles", tier: .primary) {}
            .disabled(true)

        HStack(spacing: ThemeSpacing.sm) {
            ThemeButton("Style", systemImage: "paintpalette", tier: .contextual) {}
            ThemeButton("History", systemImage: "clock", tier: .contextual) {}
            ThemeButton("Enhance", systemImage: "sparkles", tier: .contextual) {}
        }

        ThemeButton("Enhance", systemImage: "sparkles", tier: .contextual) {}
            .disabled(true)

        HStack(spacing: ThemeSpacing.md) {
            ThemeButton("Cancel", tier: .quiet) {}
            ThemeButton("Use Original", tier: .quiet) {}
        }

        ThemeButton("Disabled Quiet", tier: .quiet) {}
            .disabled(true)
    }
    .padding()
    .background(ThemeColors.light.background)
    .synthesisTheme()
}
