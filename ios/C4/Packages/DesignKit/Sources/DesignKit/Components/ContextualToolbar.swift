import SwiftUI

// MARK: - ContextualToolbar

/// A floating toolbar that slides in between the creative stage card and keyboard.
/// Provides quick actions: Style, History, Enhance, Camera.
public struct ContextualToolbar: View {
    public struct Actions {
        public let onStyle: () -> Void
        public let onHistory: () -> Void
        public let onEnhance: () -> Void
        public let onCamera: (() -> Void)?

        public init(
            onStyle: @escaping () -> Void,
            onHistory: @escaping () -> Void,
            onEnhance: @escaping () -> Void,
            onCamera: (() -> Void)? = nil
        ) {
            self.onStyle = onStyle
            self.onHistory = onHistory
            self.onEnhance = onEnhance
            self.onCamera = onCamera
        }
    }

    private let actions: Actions
    @Environment(\.themeColors) private var colors

    public init(actions: Actions) {
        self.actions = actions
    }

    public var body: some View {
        HStack(spacing: ThemeSpacing.lg) {
            toolbarButton("paintpalette", label: "Style", action: actions.onStyle)
            toolbarButton("clock", label: "History", action: actions.onHistory)
            toolbarButton("sparkles", label: "Enhance", action: actions.onEnhance)
            if let onCamera = actions.onCamera {
                toolbarButton("camera", label: "Camera", action: onCamera)
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
        .padding(.vertical, ThemeSpacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func toolbarButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(colors.accent)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("ContextualToolbar") {
    VStack {
        Spacer()

        ContextualToolbar(actions: .init(
            onStyle: {},
            onHistory: {},
            onEnhance: {},
            onCamera: {}
        ))
        .padding()
    }
    .background(ThemeColors.light.background)
    .synthesisTheme()
}
