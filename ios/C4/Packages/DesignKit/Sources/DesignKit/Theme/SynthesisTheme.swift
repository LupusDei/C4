import SwiftUI

// MARK: - Theme Colors

public struct ThemeColors: Sendable {
    // Backgrounds
    public let background: Color
    public let surface: Color

    // Accent
    public let accent: Color

    // Text
    public let textPrimary: Color
    public let textSecondary: Color

    // Semantic
    public let success: Color
    public let error: Color

    // Borders
    public let border: Color

    public init(
        background: Color,
        surface: Color,
        accent: Color,
        textPrimary: Color,
        textSecondary: Color,
        success: Color,
        error: Color,
        border: Color
    ) {
        self.background = background
        self.surface = surface
        self.accent = accent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.success = success
        self.error = error
        self.border = border
    }
}

extension ThemeColors {
    /// Light mode palette — warm editorial tones.
    public static let light = ThemeColors(
        background: Color(red: 250/255, green: 248/255, blue: 245/255),   // #FAF8F5
        surface: .white,
        accent: Color(red: 194/255, green: 65/255, blue: 12/255),         // #C2410C
        textPrimary: Color(red: 41/255, green: 37/255, blue: 36/255),     // #292524
        textSecondary: Color(red: 120/255, green: 113/255, blue: 108/255),// #78716C
        success: Color(red: 101/255, green: 163/255, blue: 13/255),       // #65A30D
        error: Color(red: 220/255, green: 38/255, blue: 38/255),          // #DC2626
        border: Color(red: 231/255, green: 229/255, blue: 228/255)        // #E7E5E4
    )

    /// Dark mode palette — warm dark tones.
    public static let dark = ThemeColors(
        background: Color(red: 28/255, green: 25/255, blue: 23/255),      // #1C1917
        surface: Color(red: 41/255, green: 37/255, blue: 36/255),         // #292524
        accent: Color(red: 194/255, green: 65/255, blue: 12/255),         // #C2410C
        textPrimary: Color(red: 250/255, green: 248/255, blue: 245/255),  // #FAF8F5
        textSecondary: Color(red: 168/255, green: 162/255, blue: 158/255),// #A8A29E
        success: Color(red: 101/255, green: 163/255, blue: 13/255),       // #65A30D
        error: Color(red: 220/255, green: 38/255, blue: 38/255),          // #DC2626
        border: Color(red: 68/255, green: 64/255, blue: 60/255)           // #44403C
    )

    /// Returns the appropriate palette for the given color scheme.
    public static func forScheme(_ scheme: ColorScheme) -> ThemeColors {
        scheme == .dark ? .dark : .light
    }
}

// MARK: - Theme Typography

public struct ThemeTypography: Sendable {
    private init() {}

    /// Heading — serif bold (New York).
    public static func heading(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    /// Body — system default 15pt.
    public static let body: Font = .system(size: 15)

    /// Prompt — serif regular, used inside the creative stage text field.
    public static let prompt: Font = .system(size: 17, weight: .regular, design: .serif)

    /// Line spacing for prompt text.
    public static let promptLineSpacing: CGFloat = 1.5 * 17 - 17 // ~8.5pt extra leading

    /// Numerical — monospaced digits.
    public static func numerical(size: CGFloat = 15) -> Font {
        .system(size: size, design: .monospaced)
    }

    /// Large display — thin weight for hero numbers or labels.
    public static let largeDisplay: Font = .system(size: 48, weight: .thin)
}

// MARK: - Theme Spacing

public enum ThemeSpacing {
    /// 4pt
    public static let xxs: CGFloat = 4
    /// 8pt
    public static let xs: CGFloat = 8
    /// 12pt
    public static let sm: CGFloat = 12
    /// 16pt
    public static let md: CGFloat = 16
    /// 20pt
    public static let lg: CGFloat = 20
    /// 24pt
    public static let xl: CGFloat = 24
    /// 32pt
    public static let xxl: CGFloat = 32
}

// MARK: - Theme Animations

public enum ThemeAnimation {
    /// Scale / press feedback.
    public static let press: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    /// Movement transitions.
    public static let movement: Animation = .easeOut(duration: 0.25)
    /// Card entrance.
    public static let cardEntrance: Animation = .spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - Environment Key

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .light
}

extension EnvironmentValues {
    public var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}

// MARK: - View Modifier

public struct SynthesisThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    public func body(content: Content) -> some View {
        content
            .environment(\.themeColors, ThemeColors.forScheme(colorScheme))
    }
}

extension View {
    /// Apply the Synthesis theme, injecting color tokens as environment values.
    public func synthesisTheme() -> some View {
        modifier(SynthesisThemeModifier())
    }
}

// MARK: - Preview

#Preview("SynthesisTheme Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: ThemeSpacing.md) {
            Text("Heading")
                .font(ThemeTypography.heading())
            Text("Body text in the default system font at 15pt.")
                .font(ThemeTypography.body)
            Text("Prompt text in New York Regular at 17pt with generous line spacing.")
                .font(ThemeTypography.prompt)
                .lineSpacing(ThemeTypography.promptLineSpacing)
            Text("1,234,567")
                .font(ThemeTypography.numerical(size: 20))
            Text("Large Display")
                .font(ThemeTypography.largeDisplay)

            Divider()

            HStack(spacing: ThemeSpacing.xs) {
                colorSwatch("Accent", ThemeColors.light.accent)
                colorSwatch("Success", ThemeColors.light.success)
                colorSwatch("Error", ThemeColors.light.error)
                colorSwatch("Border", ThemeColors.light.border)
            }
        }
        .padding()
    }
    .synthesisTheme()
}

private func colorSwatch(_ label: String, _ color: Color) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 48, height: 48)
        Text(label)
            .font(.caption2)
    }
}
