import SwiftUI

// MARK: - Panel Picker

/// A horizontal pill-bar that replaces .pickerStyle(.menu) with tappable capsules.
/// Each option shows as a compact pill; the selected one is highlighted.
public struct PanelPicker<T: Hashable>: View {
    let title: String
    let options: [T]
    let selection: T
    let label: (T) -> String
    let onSelect: (T) -> Void

    public init(
        _ title: String,
        options: [T],
        selection: T,
        label: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) {
        self.title = title
        self.options = options
        self.selection = selection
        self.label = label
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = option == selection
                        Button {
                            onSelect(option)
                        } label: {
                            Text(label(option))
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Aspect Ratio Panel View

public struct AspectRatioPanelView<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    let selection: T
    let onSelect: (T) -> Void

    public init(options: [T], selection: T, onSelect: @escaping (T) -> Void) {
        self.options = options
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        PanelPicker(
            "Aspect Ratio",
            options: options,
            selection: selection,
            label: { $0.rawValue },
            onSelect: onSelect
        )
    }
}

// MARK: - Quality Panel View

public struct QualityPanelView<T: Hashable>: View {
    let options: [T]
    let selection: T
    let displayName: (T) -> String
    let onSelect: (T) -> Void

    public init(
        options: [T],
        selection: T,
        displayName: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) {
        self.options = options
        self.selection = selection
        self.displayName = displayName
        self.onSelect = onSelect
    }

    public var body: some View {
        PanelPicker(
            "Quality",
            options: options,
            selection: selection,
            label: displayName,
            onSelect: onSelect
        )
    }
}

// MARK: - Provider Panel View

public struct ProviderPanelView<T: Hashable>: View {
    let options: [T]
    let selection: T
    let displayName: (T) -> String
    let onSelect: (T) -> Void

    public init(
        options: [T],
        selection: T,
        displayName: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void
    ) {
        self.options = options
        self.selection = selection
        self.displayName = displayName
        self.onSelect = onSelect
    }

    public var body: some View {
        PanelPicker(
            "Provider",
            options: options,
            selection: selection,
            label: displayName,
            onSelect: onSelect
        )
    }
}

// MARK: - Duration Stepper View

public struct DurationStepperView: View {
    let duration: Int
    let range: ClosedRange<Int>
    let onSet: (Int) -> Void

    public init(duration: Int, range: ClosedRange<Int> = 1...15, onSet: @escaping (Int) -> Void) {
        self.duration = duration
        self.range = range
        self.onSet = onSet
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    if duration > range.lowerBound {
                        onSet(duration - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(duration > range.lowerBound ? Color.accentColor : .gray)
                }
                .disabled(duration <= range.lowerBound)

                Text("\(duration)s")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 44)

                Button {
                    if duration < range.upperBound {
                        onSet(duration + 1)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(duration < range.upperBound ? Color.accentColor : .gray)
                }
                .disabled(duration >= range.upperBound)

                Spacer()

                // Quick-select pills
                HStack(spacing: 6) {
                    ForEach([3, 5, 10], id: \.self) { preset in
                        if range.contains(preset) {
                            Button {
                                onSet(preset)
                            } label: {
                                Text("\(preset)s")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(duration == preset ? Color.accentColor : Color(.systemGray5))
                                    .foregroundStyle(duration == preset ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
