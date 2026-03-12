import SwiftUI

// MARK: - PanelContent Protocol

/// Protocol for views that can be displayed inside a PanelPicker expansion panel.
public protocol PanelContent: View {
    associatedtype Option: Identifiable & Hashable
    var selectedOption: Option { get }
}

// MARK: - PanelPicker

/// A horizontal pill bar where each pill shows the current value for a setting.
/// Tapping a pill fans open a panel above the bar with all options.
/// Only one panel is open at a time.
///
/// Usage requires `@Namespace` declared in the parent view and passed in.
///
/// ```swift
/// @Namespace private var panelNamespace
///
/// PanelPicker(
///     namespace: panelNamespace,
///     activePanel: $activePanel,
///     items: [
///         .init(id: "ratio", label: "16:9", panel: { AspectRatioPanelView(...) }),
///         .init(id: "quality", label: "High", panel: { QualityPanelView(...) }),
///     ]
/// )
/// ```
public struct PanelPicker<PanelID: Hashable>: View {
    private let namespace: Namespace.ID
    @Binding private var activePanel: PanelID?
    private let items: [PanelItem<PanelID>]

    public init(
        namespace: Namespace.ID,
        activePanel: Binding<PanelID?>,
        items: [PanelItem<PanelID>]
    ) {
        self.namespace = namespace
        self._activePanel = activePanel
        self.items = items
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Expanded panel area
            if let activePanelId = activePanel,
               let item = items.first(where: { $0.id == activePanelId }) {
                item.panelBuilder()
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.background)
                            .shadow(color: Color(red: 120/255, green: 90/255, blue: 50/255, opacity: 0.08), radius: 12, y: 4)
                    )
                    .matchedGeometryEffect(id: "panel-\(String(describing: activePanelId))", in: namespace)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }

            // Pill bar
            HStack(spacing: 8) {
                ForEach(items) { item in
                    PanelPill(
                        label: item.label,
                        isActive: activePanel == item.id,
                        namespace: namespace,
                        pillId: "pill-\(String(describing: item.id))"
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            if activePanel == item.id {
                                activePanel = nil
                            } else {
                                activePanel = item.id
                            }
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap outside panels collapses them
        }
        .background(
            // Invisible tap catcher for dismissing panels
            Group {
                if activePanel != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                activePanel = nil
                            }
                        }
                }
            }
        )
    }
}

// MARK: - PanelItem

/// A single item in the PanelPicker pill bar.
public struct PanelItem<PanelID: Hashable>: Identifiable {
    public let id: PanelID
    public let label: String
    let panelBuilder: @MainActor () -> AnyView

    public init<Panel: View>(
        id: PanelID,
        label: String,
        @ViewBuilder panel: @escaping @MainActor () -> Panel
    ) {
        self.id = id
        self.label = label
        self.panelBuilder = { AnyView(panel()) }
    }
}

// MARK: - PanelPill

/// Individual pill button in the PanelPicker bar.
struct PanelPill: View {
    let label: String
    let isActive: Bool
    let namespace: Namespace.ID
    let pillId: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? Color.accentColor : Color.gray.opacity(0.2))
                )
                .matchedGeometryEffect(id: pillId, in: namespace)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(isActive ? "Collapse panel" : "Expand panel")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("PanelPicker") {
    PanelPickerPreview()
}

private struct PanelPickerPreview: View {
    enum PanelID: Hashable {
        case ratio
        case quality
        case provider
    }

    @Namespace private var namespace
    @State private var activePanel: PanelID?

    var body: some View {
        VStack {
            Spacer()
            PanelPicker(
                namespace: namespace,
                activePanel: $activePanel,
                items: [
                    PanelItem(id: PanelID.ratio, label: "16:9") {
                        Text("Aspect Ratio options go here")
                            .frame(maxWidth: .infinity, minHeight: 100)
                    },
                    PanelItem(id: PanelID.quality, label: "High") {
                        Text("Quality options go here")
                            .frame(maxWidth: .infinity, minHeight: 80)
                    },
                    PanelItem(id: PanelID.provider, label: "Flux") {
                        Text("Provider options go here")
                            .frame(maxWidth: .infinity, minHeight: 80)
                    },
                ]
            )
            .padding()
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
    }
}
