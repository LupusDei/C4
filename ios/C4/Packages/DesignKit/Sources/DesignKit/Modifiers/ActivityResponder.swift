import SwiftUI

// MARK: - ActivityMode

/// Represents the current user activity mode, driving opacity adjustments
/// for non-essential UI elements.
///
/// - idle: Default browsing state, all elements fully visible
/// - composing: Prompt input is focused, non-essential elements fade
/// - generating: Generation in progress, subtle de-emphasis of other elements
/// - reviewing: Viewing generation results, result has visual emphasis
public enum ActivityMode: String, Sendable, Equatable, Hashable {
    case idle
    case composing
    case generating
    case reviewing
}

// MARK: - ActivityMode Environment Key

private struct ActivityModeKey: EnvironmentKey {
    static let defaultValue: ActivityMode = .idle
}

extension EnvironmentValues {
    /// The current activity mode, used by ActivityResponder to adjust opacity.
    public var activityMode: ActivityMode {
        get { self[ActivityModeKey.self] }
        set { self[ActivityModeKey.self] = newValue }
    }
}

extension View {
    /// Sets the activity mode for this view and its descendants.
    public func activityMode(_ mode: ActivityMode) -> some View {
        environment(\.activityMode, mode)
    }
}

// MARK: - ActivityResponder ViewModifier

/// A ViewModifier that reads `ActivityMode` from the environment and adjusts
/// the opacity of the modified view accordingly.
///
/// - composing: 50% opacity (prompt is the focus)
/// - generating: 70% opacity (generation card is the focus)
/// - reviewing: 100% opacity
/// - idle: 100% opacity
///
/// Usage:
/// ```swift
/// settingsSection
///     .activityResponsive()
///
/// // Or with custom opacity overrides:
/// toolbar
///     .activityResponsive(composing: 0.3, generating: 0.5)
/// ```
public struct ActivityResponder: ViewModifier {
    @Environment(\.activityMode) private var mode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let composingOpacity: Double
    let generatingOpacity: Double
    let reviewingOpacity: Double
    let idleOpacity: Double

    public init(
        composing: Double = 0.5,
        generating: Double = 0.7,
        reviewing: Double = 1.0,
        idle: Double = 1.0
    ) {
        self.composingOpacity = composing
        self.generatingOpacity = generating
        self.reviewingOpacity = reviewing
        self.idleOpacity = idle
    }

    private var currentOpacity: Double {
        switch mode {
        case .composing: composingOpacity
        case .generating: generatingOpacity
        case .reviewing: reviewingOpacity
        case .idle: idleOpacity
        }
    }

    public func body(content: Content) -> some View {
        content
            .opacity(currentOpacity)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.4),
                value: mode
            )
    }
}

extension View {
    /// Makes this view respond to the current `ActivityMode` by adjusting its opacity.
    ///
    /// Default opacities:
    /// - idle: 1.0
    /// - composing: 0.5
    /// - generating: 0.7
    /// - reviewing: 1.0
    public func activityResponsive(
        composing: Double = 0.5,
        generating: Double = 0.7,
        reviewing: Double = 1.0,
        idle: Double = 1.0
    ) -> some View {
        modifier(ActivityResponder(
            composing: composing,
            generating: generating,
            reviewing: reviewing,
            idle: idle
        ))
    }
}

// MARK: - Preview

#Preview("ActivityResponder") {
    ActivityResponderPreview()
}

private struct ActivityResponderPreview: View {
    @State private var mode: ActivityMode = .idle

    var body: some View {
        VStack(spacing: 32) {
            Text("Activity Mode: \(mode.rawValue)")
                .font(.headline)

            // Simulated elements
            VStack(spacing: 16) {
                Text("Primary Content")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Settings Section")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .activityResponsive()

                Text("Toolbar")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .activityResponsive(composing: 0.3, generating: 0.5)

                Text("Credit Pill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .activityResponsive()
            }
            .padding()

            // Mode switcher
            HStack(spacing: 12) {
                ForEach([ActivityMode.idle, .composing, .generating, .reviewing], id: \.self) { m in
                    Button(m.rawValue.capitalized) {
                        mode = m
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(mode == m ? .accentColor : .gray)
                }
            }
        }
        .padding()
        .activityMode(mode)
    }
}
