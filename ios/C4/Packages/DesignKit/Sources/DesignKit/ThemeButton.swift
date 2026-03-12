import SwiftUI

// MARK: - ThemeButton
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion support (ThemeAnimation.spring)
//   C4-004.2.2.1  — Loading state with progress bar on primary
//   C4-004.2.2.2  — Primary press darkens 10%
//   C4-004.2.2.4  — @GestureState for press state (replaces asyncAfter)
//   C4-004.12.3   — Dynamic Type XXXL layout adaptation
//   C4-004.12.4   — VoiceOver: ensure label is announced

/// The tier / visual weight of a ThemeButton.
public enum ThemeButtonTier: Sendable {
    case primary
    case secondary
    case ghost
}

public struct ThemeButton: View {
    let label: String
    let icon: String?
    let tier: ThemeButtonTier
    let isLoading: Bool
    let loadingText: String
    let action: () -> Void

    // Bug C4-004.2.2.4 — GestureState automatically resets on gesture end
    @GestureState private var isPressed = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        _ label: String,
        icon: String? = nil,
        tier: ThemeButtonTier = .primary,
        isLoading: Bool = false,
        loadingText: String = "Loading...",
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.tier = tier
        self.isLoading = isLoading
        self.loadingText = loadingText
        self.action = action
    }

    public var body: some View {
        buttonContent
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.sm)
            .padding(.horizontal, ThemeSpacing.md)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .top) {
                // Bug C4-004.2.2.1 — thin progress bar at top of primary button
                if tier == .primary && isLoading {
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: geo.size.width * 0.6, height: 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(x: -geo.size.width * 0.1)
                            .animation(
                                ThemeAnimation.animation(
                                    .linear(duration: 1.0).repeatForever(autoreverses: true)
                                ),
                                value: isLoading
                            )
                    }
                    .frame(height: 2)
                    .clipped()
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
            }
            // Bug C4-004.2.2.2 — scale + brightness shift on press
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(tier == .primary && isPressed ? -0.1 : 0)
            .animation(ThemeAnimation.snappy, value: isPressed)
            // Bug C4-004.2.2.4 — DragGesture-based press detection
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
            .onTapGesture {
                if !isLoading { action() }
            }
            .disabled(isLoading)
            // Bug C4-004.12.4 — VoiceOver label
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isLoading ? loadingText : label)
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isLoading ? .isButton : [])
    }

    // MARK: - Content

    @ViewBuilder
    private var buttonContent: some View {
        if isLoading && tier == .primary {
            // Bug C4-004.2.2.1 — show ProgressView + text when loading
            loadingContent
        } else {
            normalContent
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        // Bug C4-004.12.3 — Dynamic Type: stack vertically at XXXL
        if dynamicTypeSize >= .accessibility1 {
            VStack(spacing: ThemeSpacing.xs) {
                ProgressView()
                    .tint(foregroundColor)
                Text(loadingText)
                    .font(ThemeTypography.subheadline)
            }
        } else {
            HStack(spacing: ThemeSpacing.xs) {
                ProgressView()
                    .tint(foregroundColor)
                Text(loadingText)
                    .font(ThemeTypography.subheadline)
            }
        }
    }

    @ViewBuilder
    private var normalContent: some View {
        if dynamicTypeSize >= .accessibility1 {
            VStack(spacing: ThemeSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
                    .font(ThemeTypography.headline)
            }
        } else {
            HStack(spacing: ThemeSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(label)
                    .font(ThemeTypography.headline)
            }
        }
    }

    // MARK: - Styling

    @ViewBuilder
    private var backgroundView: some View {
        switch tier {
        case .primary:
            ThemeColors.accent
        case .secondary:
            ThemeColors.accent.opacity(0.12)
        case .ghost:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch tier {
        case .primary: .white
        case .secondary: ThemeColors.accent
        case .ghost: ThemeColors.accent
        }
    }
}
