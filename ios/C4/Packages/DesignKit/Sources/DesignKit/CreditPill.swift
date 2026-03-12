import SwiftUI

// MARK: - CreditPill
// Bugs addressed:
//   C4-004.12.2   — Reduce Transparency: solid background when enabled
//   C4-004.12.4   — VoiceOver: accessibilityLabel with balance

public struct CreditPill: View {
    let balance: Int

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(balance: Int) {
        self.balance = balance
    }

    public var body: some View {
        HStack(spacing: ThemeSpacing.xxs) {
            Image(systemName: "creditcard.fill")
                .font(.caption)
                .foregroundStyle(ThemeColors.accent)

            Text("\(balance)")
                .font(ThemeTypography.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, ThemeSpacing.sm)
        .padding(.vertical, ThemeSpacing.xxs + 2)
        .background(pillBackground)
        .clipShape(Capsule())
        // Bug C4-004.12.4 — VoiceOver label
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Credit balance: \(balance)")
    }

    @ViewBuilder
    private var pillBackground: some View {
        // Bug C4-004.12.2 — solid background for Reduce Transparency
        if reduceTransparency {
            ThemeColors.surface
        } else {
            Capsule().fill(.ultraThinMaterial)
        }
    }
}
