import SwiftUI

// MARK: - ThemeCard

public struct ThemeCard<Content: View>: View {
    private let accentBorder: Color?
    private let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @State private var isPressed = false

    /// Creates a warm editorial card.
    /// - Parameters:
    ///   - accentBorder: Optional accent border color. Pass `nil` for no border.
    ///   - content: The card content.
    public init(
        accentBorder: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accentBorder = accentBorder
        self.content = content
    }

    public var body: some View {
        content()
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if let accentBorder {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentBorder, lineWidth: 1.5)
                }
            }
            .shadow(
                color: warmShadow.opacity(isPressed ? 0.15 : 0.08),
                radius: isPressed ? 6 : 4,
                y: 2
            )
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .animation(ThemeAnimation.press, value: isPressed)
    }

    /// Enables press-state feedback on the card. Call this when the card is tappable.
    public func pressable(_ pressed: Bool) -> some View {
        self.onAppear {} // force body eval
            .modifier(PressStateModifier(isPressed: pressed))
    }

    private var warmShadow: Color {
        Color(red: 120/255, green: 90/255, blue: 50/255)
    }
}

// MARK: - Press State Modifier (for external binding)

private struct PressStateModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color(red: 120/255, green: 90/255, blue: 50/255).opacity(isPressed ? 0.15 : 0.08),
                radius: isPressed ? 6 : 4,
                y: 2
            )
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .animation(ThemeAnimation.press, value: isPressed)
    }
}

// MARK: - Tappable ThemeCard

public struct TappableThemeCard<Content: View>: View {
    private let accentBorder: Color?
    private let action: () -> Void
    private let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    @GestureState private var isPressed = false

    public init(
        accentBorder: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accentBorder = accentBorder
        self.action = action
        self.content = content
    }

    public var body: some View {
        content()
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if let accentBorder {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentBorder, lineWidth: 1.5)
                }
            }
            .shadow(
                color: warmShadow.opacity(isPressed ? 0.15 : 0.08),
                radius: isPressed ? 6 : 4,
                y: 2
            )
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .animation(ThemeAnimation.press, value: isPressed)
            .gesture(
                LongPressGesture(minimumDuration: .infinity)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .simultaneously(with: TapGesture().onEnded { _ in action() })
            )
    }

    private var warmShadow: Color {
        Color(red: 120/255, green: 90/255, blue: 50/255)
    }
}

// MARK: - Preview

#Preview("ThemeCard") {
    ScrollView {
        VStack(spacing: ThemeSpacing.lg) {
            ThemeCard {
                VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                    Text("Default Card")
                        .font(ThemeTypography.heading(size: 18))
                    Text("A warm white card with subtle shadow on the editorial background.")
                        .font(ThemeTypography.body)
                }
                .padding(ThemeSpacing.md)
            }

            ThemeCard(accentBorder: ThemeColors.light.accent) {
                VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                    Text("Accent Border Card")
                        .font(ThemeTypography.heading(size: 18))
                    Text("This card has an accent-colored border for emphasis.")
                        .font(ThemeTypography.body)
                }
                .padding(ThemeSpacing.md)
            }

            TappableThemeCard(action: {}) {
                HStack {
                    Text("Tappable Card")
                        .font(ThemeTypography.heading(size: 18))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding(ThemeSpacing.md)
            }
        }
        .padding()
    }
    .background(ThemeColors.light.background)
    .synthesisTheme()
}
