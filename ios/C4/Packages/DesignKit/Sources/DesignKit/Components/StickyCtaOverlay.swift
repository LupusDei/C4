import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - StickyCtaOverlay

/// A ZStack overlay that pins a primary CTA button 16pt above the safe area bottom
/// with a frosted glass extension from the button to the screen edge.
///
/// Usage:
/// ```swift
/// ScrollView { ... }
///     .stickyCtaOverlay(
///         title: "Generate Image",
///         isLoading: store.isGenerating,
///         progress: store.generationProgress,
///         action: { store.send(.generateTapped) }
///     )
/// ```
public struct StickyCtaOverlay<Content: View>: View {
    let content: Content
    let title: String
    let loadingTitle: String?
    let isLoading: Bool
    let isDisabled: Bool
    let progress: Double?
    let action: @MainActor () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        title: String,
        loadingTitle: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        progress: Double? = nil,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.loadingTitle = loadingTitle
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.progress = progress
        self.action = action
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            content

            // Frosted glass extension from button to screen edge
            VStack(spacing: 0) {
                // Progress bar at top of button when loading
                if isLoading, let progress {
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(.linear)
                        .tint(.white.opacity(0.8))
                }

                // Primary CTA button
                Button(action: action) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? (loadingTitle ?? title) : title)
                            .font(.custom("NewYork-Bold", size: 17, relativeTo: .headline))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isDisabled ? Color.gray : Color.accentColor)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(PrimaryCTAButtonStyle())
                .disabled(isDisabled || isLoading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
            .background(
                .ultraThinMaterial,
                in: Rectangle()
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - PrimaryCTAButtonStyle

/// Button style for the primary CTA: darken-10% + scale-0.98 press animation with medium haptic.
struct PrimaryCTAButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(
                reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    #if canImport(UIKit)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    #endif
                }
            }
    }
}

// MARK: - ViewModifier

/// ViewModifier for convenient `.stickyCtaOverlay(...)` syntax.
struct StickyCtaOverlayModifier: ViewModifier {
    let title: String
    let loadingTitle: String?
    let isLoading: Bool
    let isDisabled: Bool
    let progress: Double?
    let action: @MainActor () -> Void

    func body(content: Content) -> some View {
        StickyCtaOverlay(
            title: title,
            loadingTitle: loadingTitle,
            isLoading: isLoading,
            isDisabled: isDisabled,
            progress: progress,
            action: action
        ) {
            content
        }
    }
}

extension View {
    /// Wraps the view in a ZStack with a sticky primary CTA button pinned to the bottom.
    /// The button has a frosted glass extension to the screen edge.
    ///
    /// - Parameters:
    ///   - title: The button label text.
    ///   - loadingTitle: Optional text shown during loading state.
    ///   - isLoading: Whether the action is in progress.
    ///   - isDisabled: Whether the button should be disabled.
    ///   - progress: Optional progress value (0-100) shown as a thin bar.
    ///   - action: The action to perform on tap.
    public func stickyCtaOverlay(
        title: String,
        loadingTitle: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        progress: Double? = nil,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        modifier(StickyCtaOverlayModifier(
            title: title,
            loadingTitle: loadingTitle,
            isLoading: isLoading,
            isDisabled: isDisabled,
            progress: progress,
            action: action
        ))
    }
}

// MARK: - Preview

#Preview("Sticky CTA - Default") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<20) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 60)
                    .overlay(Text("Setting \(i + 1)"))
            }
        }
        .padding()
        .padding(.bottom, 80) // Space for the CTA
    }
    .stickyCtaOverlay(
        title: "Generate Image",
        action: {}
    )
}

#Preview("Sticky CTA - Loading") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 60)
                    .overlay(Text("Setting \(i + 1)"))
            }
        }
        .padding()
        .padding(.bottom, 80)
    }
    .stickyCtaOverlay(
        title: "Generate Image",
        loadingTitle: "Generating... 45%",
        isLoading: true,
        progress: 45,
        action: {}
    )
}
