import SwiftUI

/// A mechanical counter that animates individual digits with a rolling spring effect.
///
/// Each digit animates independently using an interpolating spring,
/// creating a satisfying odometer-style transition when values change.
///
/// Usage:
/// ```swift
/// MechanicalCounter(value: creditBalance)
///     .font(.system(size: 36, weight: .thin))
/// ```
public struct MechanicalCounter: View {
    let value: Int
    let font: Font

    public init(value: Int, font: Font = .system(size: 36, weight: .thin, design: .monospaced)) {
        self.value = value
        self.font = font
    }

    private var digits: [DigitInfo] {
        let str = String(value)
        return str.enumerated().map { index, char in
            DigitInfo(
                id: index,
                digit: Int(String(char)) ?? 0,
                totalDigits: str.count
            )
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(digits, id: \.id) { info in
                SingleDigitView(
                    digit: info.digit,
                    font: font
                )
            }
        }
    }
}

private struct DigitInfo: Identifiable {
    let id: Int
    let digit: Int
    let totalDigits: Int
}

/// Animates a single digit with a vertical rolling effect.
private struct SingleDigitView: View {
    let digit: Int
    let font: Font

    @State private var animatedDigit: Double = 0

    var body: some View {
        Text(displayText)
            .font(font)
            .monospacedDigit()
            .frame(minWidth: 0)
            .onChange(of: digit, initial: true) { _, newValue in
                withAnimation(.interpolatingSpring(stiffness: 120, damping: 15)) {
                    animatedDigit = Double(newValue)
                }
            }
            .modifier(RollingDigitModifier(digit: animatedDigit, font: font))
    }

    private var displayText: String {
        "\(Int(animatedDigit.rounded()) % 10)"
    }
}

/// A geometry effect that creates the vertical rolling animation for a digit.
private struct RollingDigitModifier: ViewModifier, Animatable {
    var digit: Double
    let font: Font

    nonisolated var animatableData: Double {
        get { digit }
        set { digit = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(
                Rectangle()
            )
            .overlay {
                GeometryReader { geometry in
                    let currentDigit = Int(digit.rounded()) % 10
                    let fraction = digit - Double(Int(digit))
                    let offset = fraction * geometry.size.height

                    ZStack {
                        Text("\(currentDigit)")
                            .font(font)
                            .monospacedDigit()
                            .offset(y: -offset)

                        Text("\((currentDigit + 1) % 10)")
                            .font(font)
                            .monospacedDigit()
                            .offset(y: geometry.size.height - offset)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
    }
}

// MARK: - Preview

#Preview("Mechanical Counter") {
    struct CounterDemo: View {
        @State private var value = 1250

        var body: some View {
            VStack(spacing: 24) {
                MechanicalCounter(value: value)

                MechanicalCounter(
                    value: value,
                    font: .system(size: 48, weight: .thin, design: .monospaced)
                )

                HStack(spacing: 16) {
                    Button("-10") { value = max(0, value - 10) }
                    Button("-1") { value = max(0, value - 1) }
                    Button("+1") { value += 1 }
                    Button("+10") { value += 10 }
                    Button("+100") { value += 100 }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    return CounterDemo()
}
