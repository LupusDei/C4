import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme Animation (Bug C4-004.2.1.1)

/// Provides Reduce Motion-aware animation helpers.
/// When Reduce Motion is enabled, all animations collapse to a short ease-out.
public enum ThemeAnimation: Sendable {
    /// Returns a reduced-motion-safe animation. When Reduce Motion is on,
    /// returns a short easeOut; otherwise returns the requested animation.
    @MainActor
    public static func animation(_ animation: Animation) -> Animation {
        #if canImport(UIKit)
        UIAccessibility.isReduceMotionEnabled ? .easeOut(duration: 0.2) : animation
        #else
        animation
        #endif
    }

    /// Standard spring used across DesignKit components.
    @MainActor
    public static var spring: Animation {
        animation(.spring(response: 0.35, dampingFraction: 0.7))
    }

    /// Gentle spring for subtle interactions.
    @MainActor
    public static var gentleSpring: Animation {
        animation(.spring(response: 0.5, dampingFraction: 0.8))
    }

    /// Quick interaction feedback.
    @MainActor
    public static var snappy: Animation {
        animation(.spring(response: 0.25, dampingFraction: 0.9))
    }
}

// MARK: - Theme Colors (Bug C4-004.2.1.3, C4-004.2.1.5)

public enum ThemeColors: Sendable {
    /// Warm accent — earthy orange-amber.
    public static let accent = Color(hex: "#D97706")

    /// Secondary warm tone — muted stone.
    public static let secondary = Color(hex: "#78716C")

    /// Tertiary color — deep navy (Bug C4-004.2.1.3).
    public static let tertiary = Color(hex: "#1E3A5F")

    /// Surface background — warm off-white.
    public static let surface = Color(hex: "#FAF9F6")

    /// Card background.
    public static let cardBackground = Color(hex: "#FFFFFF")

    /// Warm gray for captions and metadata.
    public static let warmGray = Color(hex: "#78716C")

    /// Error state.
    public static let error = Color(hex: "#DC2626")

    /// Success state.
    public static let success = Color(hex: "#16A34A")
}

// MARK: - Theme Typography (Bug C4-004.2.1.2)

public enum ThemeTypography: Sendable {
    public static let largeTitle: Font = .system(size: 34, weight: .bold)
    public static let title: Font = .system(size: 22, weight: .bold)
    public static let headline: Font = .system(size: 17, weight: .semibold)
    public static let body: Font = .system(size: 17, weight: .regular)
    public static let subheadline: Font = .system(size: 15, weight: .medium)

    /// Caption typography — warm gray 12pt medium (Bug C4-004.2.1.2).
    public static let caption: Font = .system(size: 12, weight: .medium)

    public static let footnote: Font = .system(size: 13, weight: .regular)
}

// MARK: - Theme Spacing

public enum ThemeSpacing: Sendable {
    public static let xxxs: CGFloat = 2
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

// MARK: - Color Hex Extension

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
