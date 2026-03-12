import SwiftUI

// MARK: - QualityOption

/// Represents a quality tier option for the panel picker.
public struct QualityOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let iconSystemName: String
    public let creditCost: Int

    public init(id: String, name: String, description: String, iconSystemName: String, creditCost: Int) {
        self.id = id
        self.name = name
        self.description = description
        self.iconSystemName = iconSystemName
        self.creditCost = creditCost
    }

    /// Standard quality tiers.
    public static let standardTiers: [QualityOption] = [
        .init(id: "standard", name: "Standard", description: "Fast, lower detail", iconSystemName: "bolt.fill", creditCost: 2),
        .init(id: "high", name: "High", description: "Balanced quality", iconSystemName: "scalemass.fill", creditCost: 5),
        .init(id: "ultra", name: "Ultra", description: "Maximum detail", iconSystemName: "crown.fill", creditCost: 12),
    ]
}

// MARK: - QualityPanelView

/// Three HStack mini-cards showing quality tiers with icons, descriptions, and credit cost badges.
/// Selected card gets an accent left border (bookmark style).
public struct QualityPanelView: View {
    let options: [QualityOption]
    @Binding var selectedId: String

    public init(
        options: [QualityOption] = QualityOption.standardTiers,
        selectedId: Binding<String>
    ) {
        self.options = options
        self._selectedId = selectedId
    }

    public var body: some View {
        HStack(spacing: 10) {
            ForEach(options) { option in
                qualityCard(option)
            }
        }
    }

    private func qualityCard(_ option: QualityOption) -> some View {
        let isSelected = option.id == selectedId

        return Button {
            selectedId = option.id
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: option.iconSystemName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .symbolRenderingMode(.hierarchical)

                Text(option.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)

                Text(option.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Credit cost badge
                Text("\(option.creditCost) cr")
                    .font(.system(.caption2, design: .monospaced).weight(.medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                    )
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.06) : Color.gray.opacity(0.04))
            )
            .overlay(alignment: .leading) {
                // Accent left border bookmark style
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .padding(.vertical, 8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.name), \(option.description), \(option.creditCost) credits")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Quality Panel") {
    QualityPanelPreview()
}

private struct QualityPanelPreview: View {
    @State private var selected = "standard"

    var body: some View {
        VStack(spacing: 24) {
            Text("Quality")
                .font(.headline)

            QualityPanelView(selectedId: $selected)
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
