import SwiftUI

// MARK: - Card Press Style

/// A button style that applies warm-shadow press feedback.
public struct CardPressButtonStyle: ButtonStyle {
    @Environment(\.themeColors) private var colors

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color(red: 120/255, green: 90/255, blue: 50/255)
                    .opacity(configuration.isPressed ? 0.15 : 0.08),
                radius: configuration.isPressed ? 6 : 4,
                y: 2
            )
            .animation(ThemeAnimation.press, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardPressButtonStyle {
    /// A button style with warm shadow press feedback matching ThemeCard.
    public static var cardPress: CardPressButtonStyle { CardPressButtonStyle() }
}

// MARK: - Warm Background

extension View {
    /// Applies the warm editorial background color.
    public func warmBackground() -> some View {
        modifier(WarmBackgroundModifier())
    }
}

private struct WarmBackgroundModifier: ViewModifier {
    @Environment(\.themeColors) private var colors

    func body(content: Content) -> some View {
        content
            .background(colors.background.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview("ThemeModifiers") {
    VStack(spacing: ThemeSpacing.lg) {
        Button {
        } label: {
            Text("Card Press Style")
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.cardPress)
    }
    .padding()
    .warmBackground()
    .synthesisTheme()
}
