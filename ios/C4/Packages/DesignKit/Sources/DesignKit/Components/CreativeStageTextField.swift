import SwiftUI
import UIKit

// MARK: - CreativeStageTextField

/// A UITextView-backed text field that tracks intrinsic content size changes,
/// displays a cycling placeholder, and uses the New York serif font.
public struct CreativeStageTextField: UIViewRepresentable {
    @Binding public var text: String
    @Binding public var height: CGFloat
    public var placeholder: String

    @Environment(\.themeColors) private var colors

    public init(
        text: Binding<String>,
        height: Binding<CGFloat>,
        placeholder: String = "Describe what you want to create..."
    ) {
        self._text = text
        self._height = height
        self.placeholder = placeholder
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // New York Regular at 17pt with 1.5x line spacing
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.serif) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let font = UIFont(descriptor: descriptor, size: 17)
        textView.font = font

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8.5 // ~1.5x line height for 17pt
        textView.typingAttributes = [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ]

        // Initial height calculation
        DispatchQueue.main.async {
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            self.height = max(size.height, 48)
        }

        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text

            // Re-apply paragraph style on programmatic text changes
            let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
                .withDesign(.serif) ?? UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let font = UIFont(descriptor: descriptor, size: 17)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8.5
            textView.typingAttributes = [
                .font: font,
                .paragraphStyle: paragraphStyle,
            ]
        }
    }

    // MARK: - Coordinator

    public final class Coordinator: NSObject, UITextViewDelegate, @unchecked Sendable {
        var parent: CreativeStageTextField

        init(_ parent: CreativeStageTextField) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text

            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
            let newHeight = max(size.height, 48)
            if abs(parent.height - newHeight) > 1 {
                parent.height = newHeight
            }
        }
    }
}

// MARK: - Cycling Placeholder

/// An overlay that cycles through inspiring placeholder prompts with a crossfade.
public struct CyclingPlaceholder: View {
    let prompts: [String]
    let isVisible: Bool

    @State private var currentIndex = 0
    @Environment(\.themeColors) private var colors

    public init(
        prompts: [String] = [
            "A cathedral of light filtering through ancient stained glass...",
            "Two astronauts sharing tea on the surface of Mars...",
            "A fox reading a book under a weeping willow...",
            "Neon rain falling on a quiet Tokyo side street...",
            "A lighthouse keeper painting the northern lights...",
        ],
        isVisible: Bool
    ) {
        self.prompts = prompts
        self.isVisible = isVisible
    }

    public var body: some View {
        if isVisible {
            Text(prompts[currentIndex])
                .font(ThemeTypography.prompt)
                .foregroundStyle(colors.textSecondary.opacity(0.5))
                .lineSpacing(ThemeTypography.promptLineSpacing)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.6), value: currentIndex)
                .id(currentIndex)
                .transition(.opacity)
                .onAppear {
                    startCycling()
                }
        }
    }

    private func startCycling() {
        guard prompts.count > 1 else { return }
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentIndex = (currentIndex + 1) % prompts.count
            }
        }
    }
}

// MARK: - Preview

#Preview("CreativeStageTextField") {
    struct DemoView: View {
        @State private var text = ""
        @State private var height: CGFloat = 48

        var body: some View {
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    CreativeStageTextField(text: $text, height: $height)
                        .frame(height: min(height, 200))

                    CyclingPlaceholder(isVisible: text.isEmpty)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                Text("Height: \(Int(height))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(ThemeColors.light.background)
            .synthesisTheme()
        }
    }

    return DemoView()
}
