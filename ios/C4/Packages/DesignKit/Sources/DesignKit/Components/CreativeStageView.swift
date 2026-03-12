import SwiftUI

// MARK: - CreativeStageView

/// The creative stage prompt input — a collapsible manuscript card that expands
/// from a compact bar into a full editing surface.
public struct CreativeStageView: View {
    @Binding public var text: String
    public let styleName: String?
    public let wordCount: Int
    public let onGenerate: () -> Void

    @State private var isExpanded = false
    @State private var textFieldHeight: CGFloat = 48
    @State private var dragHeight: CGFloat = 200
    @AppStorage("preferredPromptHeight") private var preferredHeight: Double = 200

    @Environment(\.themeColors) private var colors
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        styleName: String? = nil,
        wordCount: Int = 0,
        onGenerate: @escaping () -> Void
    ) {
        self._text = text
        self.styleName = styleName
        self.wordCount = wordCount
        self.onGenerate = onGenerate
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Dimming background
            if isExpanded {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        collapse()
                    }
                    .transition(.opacity)
            }

            // The card
            if isExpanded {
                expandedCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                collapsedBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .onAppear {
            dragHeight = preferredHeight
        }
    }

    // MARK: - Collapsed Bar

    private var collapsedBar: some View {
        ThemeCard {
            HStack(spacing: ThemeSpacing.xs) {
                // Style pill
                if let styleName {
                    stylePill(styleName)
                } else {
                    Text(text.isEmpty ? "Tap to write a prompt..." : text)
                        .font(ThemeTypography.body)
                        .foregroundStyle(text.isEmpty ? colors.textSecondary : colors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                // Generate arrow
                Button(action: onGenerate) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(text.isEmpty ? colors.textSecondary.opacity(0.4) : colors.accent)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, ThemeSpacing.md)
            .frame(height: 48)
        }
        .padding(.horizontal, ThemeSpacing.md)
        .onTapGesture {
            expand()
        }
    }

    // MARK: - Expanded Card

    private var expandedCard: some View {
        VStack(spacing: 0) {
            ThemeCard(accentBorder: colors.accent.opacity(0.3)) {
                VStack(spacing: 0) {
                    // Style tag pinned to top-right
                    HStack {
                        Spacer()
                        if let styleName {
                            stylePill(styleName)
                                .padding(.top, ThemeSpacing.sm)
                                .padding(.trailing, ThemeSpacing.sm)
                        }
                    }

                    // Text field
                    ZStack(alignment: .topLeading) {
                        CreativeStageTextField(text: $text, height: $textFieldHeight)
                            .frame(height: min(max(textFieldHeight, 80), dragHeight))
                            .focused($isFocused)

                        CyclingPlaceholder(isVisible: text.isEmpty)
                    }

                    // Bottom bar: word count + drag handle
                    HStack {
                        Spacer()
                        wordCountPill
                    }
                    .padding(.horizontal, ThemeSpacing.sm)
                    .padding(.bottom, ThemeSpacing.xs)

                    // Drag handle
                    dragHandle
                }
            }
            .padding(.horizontal, ThemeSpacing.lg)
        }
    }

    // MARK: - Subviews

    private func stylePill(_ name: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(colors.accent)
        .padding(.horizontal, ThemeSpacing.xs)
        .padding(.vertical, ThemeSpacing.xxs)
        .background(colors.accent.opacity(0.1))
        .clipShape(Capsule())
    }

    private var wordCountPill: some View {
        Text("\(wordCount) words")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(colors.textSecondary)
            .padding(.horizontal, ThemeSpacing.xs)
            .padding(.vertical, 2)
            .background(colors.border.opacity(0.5))
            .clipShape(Capsule())
    }

    private var dragHandle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(colors.textSecondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.vertical, ThemeSpacing.xs)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let screenHeight = UIScreen.main.bounds.height
                let maxHeight = screenHeight * 0.6
                let newHeight = dragHeight - value.translation.height

                // Clamp between detents
                let clamped = min(max(newHeight, 100), maxHeight)
                dragHeight = clamped

                // Haptic detents
                checkDetent(clamped, screenHeight: screenHeight)
            }
            .onEnded { _ in
                let screenHeight = UIScreen.main.bounds.height
                let maxHeight = screenHeight * 0.6

                // Snap to nearest detent
                let detents: [CGFloat] = [100, 200, maxHeight]
                let nearest = detents.min(by: { abs($0 - dragHeight) < abs($1 - dragHeight) }) ?? 200

                withAnimation(ThemeAnimation.press) {
                    dragHeight = nearest
                }
                preferredHeight = nearest
            }
    }

    @State private var lastDetent: CGFloat = 0

    private func checkDetent(_ height: CGFloat, screenHeight: CGFloat) {
        let maxHeight = screenHeight * 0.6
        let detents: [CGFloat] = [100, 200, maxHeight]

        for detent in detents {
            if abs(height - detent) < 5 && abs(lastDetent - detent) > 5 {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred()
                lastDetent = detent
            }
        }
    }

    // MARK: - Actions

    private func expand() {
        isExpanded = true
        isFocused = true
    }

    private func collapse() {
        isFocused = false
        isExpanded = false
    }
}

// MARK: - Preview

#Preview("CreativeStageView") {
    struct DemoView: View {
        @State private var text = ""

        var body: some View {
            ZStack {
                ThemeColors.light.background
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Text("Content goes here")
                        .foregroundStyle(.secondary)
                    Spacer()

                    CreativeStageView(
                        text: $text,
                        styleName: "Cinematic",
                        wordCount: text.split(separator: " ").count,
                        onGenerate: {}
                    )
                }
            }
            .synthesisTheme()
        }
    }

    return DemoView()
}
