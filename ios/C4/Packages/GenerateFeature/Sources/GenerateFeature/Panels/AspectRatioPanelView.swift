import SwiftUI

// MARK: - AspectRatioOption

/// Represents an aspect ratio option for the panel picker.
public struct AspectRatioOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let widthRatio: CGFloat
    public let heightRatio: CGFloat

    public init(id: String, label: String, widthRatio: CGFloat, heightRatio: CGFloat) {
        self.id = id
        self.label = label
        self.widthRatio = widthRatio
        self.heightRatio = heightRatio
    }

    /// Standard aspect ratio options.
    public static let allOptions: [AspectRatioOption] = [
        .init(id: "1:1", label: "Square", widthRatio: 1, heightRatio: 1),
        .init(id: "16:9", label: "Wide", widthRatio: 16, heightRatio: 9),
        .init(id: "9:16", label: "Tall", widthRatio: 9, heightRatio: 16),
        .init(id: "21:9", label: "Cinema", widthRatio: 21, heightRatio: 9),
    ]

    /// Common ratios including classic 4:3.
    public static let imageOptions: [AspectRatioOption] = [
        .init(id: "1:1", label: "Square", widthRatio: 1, heightRatio: 1),
        .init(id: "16:9", label: "Wide", widthRatio: 16, heightRatio: 9),
        .init(id: "9:16", label: "Tall", widthRatio: 9, heightRatio: 16),
        .init(id: "4:3", label: "Classic", widthRatio: 4, heightRatio: 3),
    ]
}

// MARK: - AspectRatioPanelView

/// A grid of proportional rectangles rendered at actual ratios for the PanelPicker.
/// Labels: Square (1:1), Wide (16:9), Tall (9:16), Cinema (21:9)
/// Selected option gets an accent border.
public struct AspectRatioPanelView: View {
    let options: [AspectRatioOption]
    @Binding var selectedId: String

    public init(
        options: [AspectRatioOption] = AspectRatioOption.allOptions,
        selectedId: Binding<String>
    ) {
        self.options = options
        self._selectedId = selectedId
    }

    public var body: some View {
        HStack(spacing: 16) {
            ForEach(options) { option in
                ratioCard(option)
            }
        }
    }

    private func ratioCard(_ option: AspectRatioOption) -> some View {
        let isSelected = option.id == selectedId
        let maxDimension: CGFloat = 60

        // Calculate proportional dimensions
        let aspectRatio = option.widthRatio / option.heightRatio
        let width: CGFloat
        let height: CGFloat
        if aspectRatio >= 1 {
            width = maxDimension
            height = maxDimension / aspectRatio
        } else {
            height = maxDimension
            width = maxDimension * aspectRatio
        }

        return Button {
            selectedId = option.id
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: width, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                VStack(spacing: 2) {
                    Text(option.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)

                    Text(option.id)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.label), \(option.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Aspect Ratio Panel") {
    AspectRatioPanelPreview()
}

private struct AspectRatioPanelPreview: View {
    @State private var selected = "16:9"

    var body: some View {
        VStack(spacing: 24) {
            Text("Aspect Ratio")
                .font(.headline)

            AspectRatioPanelView(selectedId: $selected)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                )
                .padding(.horizontal)

            Text("Selected: \(selected)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
