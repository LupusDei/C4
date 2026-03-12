import SwiftUI

// MARK: - Sticky CTA Overlay

/// A bottom-anchored overlay containing the primary call-to-action button.
/// Only one primary CTA should be visible per screen at any time.
public struct StickyCtaOverlay: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    public init(
        title: String,
        icon: String = "sparkles",
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Gradient fade from content to CTA bar
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            VStack(spacing: 8) {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: icon)
                        }
                        Text(isLoading ? "Generating..." : title)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isEnabled && !isLoading ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isEnabled || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
        }
    }
}
