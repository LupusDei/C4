import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - DurationStepperView

/// A custom stepper for selecting video duration with SF Mono centered value display.
///
/// ```
/// [ - ]  5.0s  [ + ]
/// ```
///
/// Features:
/// - SF Mono centered value for technical precision
/// - Accent color on stepper buttons
/// - UIImpactFeedbackGenerator(.light) on each step
/// - Configurable range and step size
public struct DurationStepperView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        value: Binding<Double>,
        range: ClosedRange<Double> = 1.0...15.0,
        step: Double = 0.5,
        unit: String = "s"
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }

    public var body: some View {
        HStack(spacing: 20) {
            // Decrement button
            stepButton(systemName: "minus", isEnabled: value > range.lowerBound) {
                let newValue = max(range.lowerBound, value - step)
                if newValue != value {
                    value = newValue
                    triggerHaptic()
                }
            }

            // Centered value display
            Text(formattedValue)
                .font(.system(.title2, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
                .frame(minWidth: 70)
                .contentTransition(.numericText(value: value))
                .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8), value: value)

            // Increment button
            stepButton(systemName: "plus", isEnabled: value < range.upperBound) {
                let newValue = min(range.upperBound, value + step)
                if newValue != value {
                    value = newValue
                    triggerHaptic()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Duration")
        .accessibilityValue("\(formattedValue)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Private

    private var formattedValue: String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(format: "%.1f%@", value, unit)
        }
        return String(format: "%.1f%@", value, unit)
    }

    private func stepButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.accentColor : .gray)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isEnabled ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Preview

#Preview("DurationStepper") {
    DurationStepperPreview()
}

private struct DurationStepperPreview: View {
    @State private var duration: Double = 5.0

    var body: some View {
        VStack(spacing: 32) {
            Text("Video Duration")
                .font(.headline)

            DurationStepperView(value: $duration)

            Text("Selected: \(duration, specifier: "%.1f") seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
