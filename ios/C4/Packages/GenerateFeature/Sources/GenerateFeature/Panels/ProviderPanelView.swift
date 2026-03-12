import SwiftUI

// MARK: - ProviderOption

/// Represents a generation provider option for the panel picker.
public struct ProviderOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let initials: String
    public let isRecommended: Bool

    public init(id: String, name: String, initials: String, isRecommended: Bool = false) {
        self.id = id
        self.name = name
        self.initials = initials
        self.isRecommended = isRecommended
    }
}

// MARK: - ProviderPanelView

/// Horizontal scroll of provider cards with initials/logo + name.
/// "Recommended" badge on best option for selected quality.
/// Selected = accent underline.
public struct ProviderPanelView: View {
    let options: [ProviderOption]
    @Binding var selectedId: String

    public init(
        options: [ProviderOption],
        selectedId: Binding<String>
    ) {
        self.options = options
        self._selectedId = selectedId
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options) { option in
                    providerCard(option)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func providerCard(_ option: ProviderOption) -> some View {
        let isSelected = option.id == selectedId

        return Button {
            selectedId = option.id
        } label: {
            VStack(spacing: 8) {
                // Provider initials circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(option.initials)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                }

                // Provider name
                Text(option.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                    .lineLimit(1)

                // Recommended badge
                if option.isRecommended {
                    Text("Recommended")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor))
                }

                // Accent underline for selected
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
                    .padding(.horizontal, 8)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.name)\(option.isRecommended ? ", recommended" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("Provider Panel") {
    ProviderPanelPreview()
}

private struct ProviderPanelPreview: View {
    @State private var selected = "auto"

    var body: some View {
        VStack(spacing: 24) {
            Text("Provider")
                .font(.headline)

            ProviderPanelView(
                options: [
                    .init(id: "auto", name: "Auto", initials: "A", isRecommended: true),
                    .init(id: "openai", name: "OpenAI", initials: "OA"),
                    .init(id: "flux", name: "FLUX", initials: "FX"),
                    .init(id: "grok", name: "Grok", initials: "GK"),
                    .init(id: "imagen", name: "Imagen", initials: "IG"),
                ],
                selectedId: $selected
            )
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
