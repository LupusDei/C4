import SwiftUI

// MARK: - PanelPicker
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion (ThemeAnimation.spring)
//   C4-004.12.3   — Dynamic Type XXXL: wrap pills to VStack
//   C4-004.12.4   — VoiceOver: accessibilityLabel with current value per pill

/// A horizontal (or vertical at XXXL) pill-style segmented picker.
public struct PanelPicker<Item: Hashable & CustomStringConvertible>: View {
    let items: [Item]
    @Binding var selection: Item

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var pillNamespace

    public init(items: [Item], selection: Binding<Item>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        // Bug C4-004.12.3 — wrap to VStack at accessibility sizes
        if dynamicTypeSize >= .accessibility1 {
            VStack(spacing: ThemeSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    pillButton(for: item)
                }
            }
        } else {
            HStack(spacing: ThemeSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    pillButton(for: item)
                }
            }
        }
    }

    private func pillButton(for item: Item) -> some View {
        let isSelected = selection == item

        return Button {
            withAnimation(ThemeAnimation.spring) {
                selection = item
            }
        } label: {
            Text(item.description)
                .font(ThemeTypography.subheadline)
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.xs)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(ThemeColors.accent)
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        // Bug C4-004.12.4 — VoiceOver label with current value
        .accessibilityLabel("\(item.description)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
