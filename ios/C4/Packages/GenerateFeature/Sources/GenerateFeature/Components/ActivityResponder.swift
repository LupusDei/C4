import SwiftUI

// MARK: - Activity Mode

/// Represents the current user activity state for adaptive UI opacity.
public enum ActivityMode: Equatable, Sendable {
    case idle
    case composing
    case generating
}

// MARK: - Activity Responsive Modifier

/// Adjusts opacity of non-essential elements based on the current activity mode.
/// During .composing, secondary elements fade to 40% to focus attention on the prompt.
/// During .generating, secondary elements fade to 30% to emphasize progress.
/// During .idle, everything is fully visible.
struct ActivityResponsiveModifier: ViewModifier {
    let mode: ActivityMode

    func body(content: Content) -> some View {
        content
            .opacity(opacityForMode)
            .animation(.easeInOut(duration: 0.3), value: mode)
    }

    private var opacityForMode: Double {
        switch mode {
        case .idle: 1.0
        case .composing: 0.4
        case .generating: 0.3
        }
    }
}

extension View {
    /// Fades this view based on activity mode. Apply to non-essential UI elements.
    public func activityResponsive(mode: ActivityMode) -> some View {
        modifier(ActivityResponsiveModifier(mode: mode))
    }
}
