import SwiftUI

// MARK: - ContextualToolbar
// Bugs addressed:
//   C4-004.2.1.1  — Reduce Motion (ThemeAnimation.spring)
//   C4-004.2.2.3  — Long-press tooltip on contextual button
//   C4-004.12.2   — Reduce Transparency: solid background when enabled
//   C4-004.12.3   — Dynamic Type XXXL: wrap buttons to VStack

/// A single action for the contextual toolbar.
public struct ContextualAction: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String
    public let action: @Sendable () -> Void

    public init(id: String, label: String, icon: String, action: @escaping @Sendable () -> Void) {
        self.id = id
        self.label = label
        self.icon = icon
        self.action = action
    }
}

public struct ContextualToolbar: View {
    let actions: [ContextualAction]

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(actions: [ContextualAction]) {
        self.actions = actions
    }

    public var body: some View {
        Group {
            // Bug C4-004.12.3 — wrap to VStack at XXXL
            if dynamicTypeSize >= .accessibility1 {
                VStack(spacing: ThemeSpacing.xs) {
                    ForEach(actions) { action in
                        contextualButton(action)
                    }
                }
            } else {
                HStack(spacing: ThemeSpacing.sm) {
                    ForEach(actions) { action in
                        contextualButton(action)
                    }
                }
            }
        }
        .padding(ThemeSpacing.sm)
        .background(toolbarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .animation(ThemeAnimation.spring, value: actions.map(\.id))
    }

    // MARK: - Button

    private func contextualButton(_ action: ContextualAction) -> some View {
        Button {
            action.action()
        } label: {
            VStack(spacing: ThemeSpacing.xxs) {
                Image(systemName: action.icon)
                    .font(.title3)
                Text(action.label)
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.warmGray)
            }
            .frame(minWidth: 56)
            .padding(.vertical, ThemeSpacing.xs)
            .padding(.horizontal, ThemeSpacing.xxs)
        }
        .buttonStyle(.plain)
        // Bug C4-004.2.2.3 — long-press tooltip shows button label
        .contextMenu {
            Text(action.label)
        }
        .accessibilityLabel(action.label)
    }

    // MARK: - Background

    @ViewBuilder
    private var toolbarBackground: some View {
        // Bug C4-004.12.2 — solid color when Reduce Transparency is on
        if reduceTransparency {
            ThemeColors.cardBackground
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}
