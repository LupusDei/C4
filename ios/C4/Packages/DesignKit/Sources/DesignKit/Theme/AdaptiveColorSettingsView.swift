import SwiftUI

// MARK: - AdaptiveColorSettingsView

/// Settings toggle for the Adaptive Color feature.
/// "Adaptive Color" toggle with description: "UI accent color adapts to your content"
/// Default: off. Stored in @AppStorage("adaptiveColorEnabled").
public struct AdaptiveColorSettingsView: View {
    @AppStorage("adaptiveColorEnabled") private var isEnabled = false
    let engine: AdaptiveColorEngine?

    public init(engine: AdaptiveColorEngine? = nil) {
        self.engine = engine
    }

    public var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adaptive Color")
                    .font(.body)

                Text("UI accent color adapts to your content")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            engine?.isEnabled = newValue
        }
        .accessibilityLabel("Adaptive Color")
        .accessibilityHint("When enabled, the app accent color shifts based on your content images")
    }
}

// MARK: - Preview

#Preview("Adaptive Color Settings") {
    Form {
        Section("Phase 2 Features") {
            AdaptiveColorSettingsView()
        }
    }
}
