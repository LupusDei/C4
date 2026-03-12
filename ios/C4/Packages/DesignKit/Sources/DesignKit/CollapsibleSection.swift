import SwiftUI

// MARK: - CollapsibleSection
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion (ThemeAnimation.spring)

public struct CollapsibleSection<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    let header: Header
    let content: Content

    public init(
        isExpanded: Binding<Bool>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self._isExpanded = isExpanded
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(ThemeAnimation.spring) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    header
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColors.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(ThemeAnimation.spring, value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Toggle section")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
