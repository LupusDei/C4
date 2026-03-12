import SwiftUI

/// A small translucent pill that displays the current credit balance.
///
/// Features:
/// - Capsule shape with ultra-thin material background
/// - SF Mono digit display
/// - Tappable to open credit detail
/// - Spend animation: expands, shows "-N" with strikethrough, contracts to new balance
/// - Reduce Transparency support (C4-004.12.2)
/// - VoiceOver accessibility label (C4-004.12.4)
///
/// Usage:
/// ```swift
/// CreditPill(balance: 1250, onTap: { showCreditSheet = true })
/// ```
public struct CreditPill: View {
    let balance: Int
    let onTap: () -> Void

    @State private var isAnimatingSpend = false
    @State private var spendAmount: Int = 0
    @State private var displayBalance: Int
    @State private var pillWidth: CGFloat = 0
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(balance: Int, onTap: @escaping () -> Void) {
        self.balance = balance
        self.onTap = onTap
        self._displayBalance = State(initialValue: balance)
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption2)
                    .foregroundStyle(ThemeColors.accent)

                if isAnimatingSpend {
                    spendAnimationContent
                } else {
                    Text("\(displayBalance)")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(pillBackground)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Credit balance: \(displayBalance)")
        .onChange(of: balance) { oldValue, newValue in
            if newValue < oldValue {
                animateSpend(from: oldValue, to: newValue)
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayBalance = newValue
                }
            }
        }
    }

    @ViewBuilder
    private var pillBackground: some View {
        if reduceTransparency {
            ThemeColors.surface
        } else {
            Capsule().fill(.ultraThinMaterial)
        }
    }

    private var spendAnimationContent: some View {
        HStack(spacing: 4) {
            Text("-\(spendAmount)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.red.opacity(0.8))
                .strikethrough(true, color: .red.opacity(0.6))

            Text("\(displayBalance)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    private func animateSpend(from oldValue: Int, to newValue: Int) {
        spendAmount = oldValue - newValue

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isAnimatingSpend = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                displayBalance = newValue
                isAnimatingSpend = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Credit Pill") {
    struct CreditPillDemo: View {
        @State private var balance = 1250

        var body: some View {
            VStack(spacing: 40) {
                CreditPill(balance: balance) {
                    print("Pill tapped")
                }

                HStack(spacing: 16) {
                    Button("Spend 5") { balance -= 5 }
                    Button("Spend 25") { balance -= 25 }
                    Button("Add 100") { balance += 100 }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }

    return CreditPillDemo()
}
