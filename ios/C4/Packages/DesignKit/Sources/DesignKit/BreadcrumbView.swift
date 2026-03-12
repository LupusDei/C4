import SwiftUI

/// A slim breadcrumb navigation bar with tappable segments separated by chevrons.
///
/// The last segment is displayed in the accent color (current location).
/// Previous segments are shown in secondary text color and are tappable.
///
/// Usage:
/// ```swift
/// BreadcrumbView(crumbs: [
///     Breadcrumb("Projects") { /* navigate to projects */ },
///     Breadcrumb("My Film") { /* navigate to project */ },
///     Breadcrumb("Storyboard") { /* navigate to storyboard */ },
///     Breadcrumb("Scene 3") { /* current, no action needed */ },
/// ])
/// ```
public struct BreadcrumbView: View {
    private let crumbs: [Breadcrumb]

    public init(crumbs: [Breadcrumb]) {
        self.crumbs = crumbs
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(crumbs) { crumb in
                    let index = crumbs.firstIndex(where: { $0.id == crumb.id }) ?? 0

                    if index > 0 {
                        Text("\u{203A}")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    let isCurrent = index == crumbs.count - 1

                    if isCurrent {
                        Text(crumb.label)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.accentColor)
                    } else {
                        Button {
                            crumb.action()
                        } label: {
                            Text(crumb.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

/// A single breadcrumb segment with a label and navigation action.
public struct Breadcrumb: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let action: @Sendable () -> Void

    /// Creates a breadcrumb segment.
    /// - Parameters:
    ///   - label: The display text for this segment.
    ///   - action: The action to perform when tapped. For the last (current) segment,
    ///     this action is not called since it represents the current location.
    public init(_ label: String, action: @escaping @Sendable () -> Void = {}) {
        self.id = label
        self.label = label
        self.action = action
    }
}

// MARK: - Preview

#Preview("Breadcrumb Navigation") {
    VStack(spacing: 20) {
        BreadcrumbView(crumbs: [
            Breadcrumb("Projects"),
            Breadcrumb("My Film"),
            Breadcrumb("Storyboard"),
            Breadcrumb("Scene 3"),
        ])

        BreadcrumbView(crumbs: [
            Breadcrumb("Projects"),
            Breadcrumb("Short Series"),
        ])

        BreadcrumbView(crumbs: [
            Breadcrumb("Studio"),
        ])
    }
}
