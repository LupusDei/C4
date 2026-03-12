import SwiftUI

// MARK: - CollapsibleSection

public struct CollapsibleSection<Content: View>: View {
    private let title: String
    private let summary: String
    private let content: () -> Content

    @Binding private var isExpanded: Bool
    @Environment(\.themeColors) private var colors

    /// Creates a collapsible section with a smooth spring animation.
    /// - Parameters:
    ///   - title: The section header text.
    ///   - summary: A one-line summary shown when collapsed.
    ///   - isExpanded: Binding that controls expansion state.
    ///   - content: The content revealed when expanded.
    public init(
        _ title: String,
        summary: String = "",
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.summary = summary
        self._isExpanded = isExpanded
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: ThemeSpacing.xs) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colors.textPrimary)

                    if !isExpanded && !summary.isEmpty {
                        Text(summary)
                            .font(.system(size: 13))
                            .foregroundStyle(colors.textSecondary)
                            .lineLimit(1)
                            .transition(.opacity)
                    }

                    Spacer()
                }
                .padding(.vertical, ThemeSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }
}

// MARK: - Preview

#Preview("CollapsibleSection") {
    struct DemoView: View {
        @State private var settingsExpanded = true
        @State private var advancedExpanded = false

        var body: some View {
            VStack(spacing: ThemeSpacing.md) {
                CollapsibleSection(
                    "Settings",
                    summary: "Standard quality, 1:1",
                    isExpanded: $settingsExpanded
                ) {
                    VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                        Text("Quality: Standard")
                        Text("Aspect Ratio: 1:1")
                        Text("Provider: Auto")
                    }
                    .font(ThemeTypography.body)
                    .padding(.leading, ThemeSpacing.lg)
                    .padding(.bottom, ThemeSpacing.sm)
                }

                Divider()

                CollapsibleSection(
                    "Advanced",
                    summary: "Default settings",
                    isExpanded: $advancedExpanded
                ) {
                    VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                        Text("Seed: Random")
                        Text("CFG Scale: 7.0")
                        Text("Steps: 30")
                    }
                    .font(ThemeTypography.body)
                    .padding(.leading, ThemeSpacing.lg)
                    .padding(.bottom, ThemeSpacing.sm)
                }
            }
            .padding()
            .synthesisTheme()
        }
    }

    return DemoView()
}
