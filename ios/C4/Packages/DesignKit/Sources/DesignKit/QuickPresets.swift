import SwiftUI

// MARK: - QuickPresets
// Bugs addressed:
//   C4-004.12.3   — Dynamic Type XXXL: wrap horizontal layout to vertical

/// A horizontal row of quick-action preset chips, wrapping to vertical at XXXL.
public struct QuickPresets: View {
    let presets: [QuickPreset]
    let onSelect: (QuickPreset) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(presets: [QuickPreset], onSelect: @escaping (QuickPreset) -> Void) {
        self.presets = presets
        self.onSelect = onSelect
    }

    public var body: some View {
        Group {
            if dynamicTypeSize >= .accessibility1 {
                VStack(spacing: ThemeSpacing.xs) {
                    ForEach(presets) { preset in
                        presetChip(preset)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ThemeSpacing.xs) {
                        ForEach(presets) { preset in
                            presetChip(preset)
                        }
                    }
                    .padding(.horizontal, ThemeSpacing.md)
                }
            }
        }
    }

    private func presetChip(_ preset: QuickPreset) -> some View {
        Button {
            onSelect(preset)
        } label: {
            HStack(spacing: ThemeSpacing.xxs) {
                if let icon = preset.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(preset.label)
                    .font(ThemeTypography.caption)
            }
            .padding(.horizontal, ThemeSpacing.sm)
            .padding(.vertical, ThemeSpacing.xs)
            .background(ThemeColors.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.label)
    }
}

// MARK: - QuickPreset Model

public struct QuickPreset: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?
    public let value: String

    public init(id: String, label: String, icon: String? = nil, value: String) {
        self.id = id
        self.label = label
        self.icon = icon
        self.value = value
    }
}
