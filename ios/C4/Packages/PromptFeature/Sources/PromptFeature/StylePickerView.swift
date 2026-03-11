import ComposableArchitecture
import CoreKit
import SwiftUI

public struct StylePickerView: View {
    @Bindable var store: StoreOf<StylePickerReducer>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<StylePickerReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryTabs
                content
            }
            .navigationTitle("Select Style")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(
                text: Binding(
                    get: { store.searchText },
                    set: { store.send(.searchTextChanged($0)) }
                ),
                prompt: "Search styles"
            )
            .onAppear { store.send(.onAppear) }
        }
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", category: nil)
                ForEach(StylePickerReducer.categories, id: \.self) { category in
                    categoryChip(
                        title: StylePickerReducer.categoryDisplayName(category),
                        category: category
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func categoryChip(title: String, category: String?) -> some View {
        let isSelected = store.selectedCategory == category
        return Button {
            store.send(.categoryChanged(category))
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(spacing: 16) {
                    noneOption
                    if !store.customPresets.isEmpty {
                        myStylesSection
                    }
                    presetsGrid
                }
                .padding()
            }
        }
    }

    // MARK: - None Option

    private var noneOption: some View {
        Button {
            store.send(.presetSelected(nil))
        } label: {
            HStack {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("No Style")
                    .font(.body.weight(.medium))
                Spacer()
                if store.selectedPreset == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(store.selectedPreset == nil ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(store.selectedPreset == nil ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - My Styles Section

    private var myStylesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Styles")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(store.customPresets) { preset in
                    presetCard(preset)
                }
            }
        }
    }

    // MARK: - Presets Grid

    private var presetsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !store.customPresets.isEmpty {
                Text("Presets")
                    .font(.headline)
                    .padding(.horizontal, 4)
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(store.builtinPresets) { preset in
                    presetCard(preset)
                }
            }
        }
    }

    // MARK: - Preset Card

    private func presetCard(_ preset: StylePreset) -> some View {
        let isSelected = store.selectedPreset?.id == preset.id
        return Button {
            store.send(.presetSelected(preset))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Color placeholder based on category
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryGradient(for: preset.category))
                    .frame(height: 80)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                                .padding(6)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(StylePickerReducer.categoryDisplayName(preset.category))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(for: preset.category).opacity(0.15))
                        .foregroundStyle(categoryColor(for: preset.category))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Colors

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "cinematic": return .indigo
        case "photography": return .blue
        case "illustration": return .orange
        case "digital-art": return .purple
        case "retro": return .brown
        case "abstract": return .pink
        default: return .gray
        }
    }

    private func categoryGradient(for category: String) -> LinearGradient {
        let color = categoryColor(for: category)
        return LinearGradient(
            colors: [color.opacity(0.6), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
