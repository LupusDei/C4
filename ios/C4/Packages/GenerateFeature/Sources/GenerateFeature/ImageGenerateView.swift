import ComposableArchitecture
import CoreKit
import DesignKit
import PromptFeature
import SwiftUI

public struct ImageGenerateView: View {
    @Bindable var store: StoreOf<ImageGenerateReducer>
    @FocusState private var isPromptFocused: Bool

    public init(store: StoreOf<ImageGenerateReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    settingsSection
                    costSection
                    resultSection
                }
                .padding()
                .padding(.bottom, 120) // space for creative stage
            }
            .navigationTitle("Generate Image")

            // Creative Stage at bottom
            VStack(spacing: 0) {
                Spacer()

                if isPromptFocused {
                    ContextualToolbar(actions: .init(
                        onStyle: { store.send(.styleButtonTapped) },
                        onHistory: { store.send(.historyTapped) },
                        onEnhance: { store.send(.promptEnhancer(.enhanceTapped)) },
                        onCamera: nil
                    ))
                    .padding(.bottom, ThemeSpacing.xs)
                }

                CreativeStageView(
                    text: Binding(
                        get: { store.prompt },
                        set: { store.send(.setPrompt($0)) }
                    ),
                    styleName: store.selectedStyle?.name,
                    wordCount: store.prompt
                        .split(separator: " ")
                        .count,
                    onGenerate: { store.send(.generateTapped) }
                )
                .focused($isPromptFocused)
            }
        }
        .warmBackground()
        .synthesisTheme()
        .sheet(isPresented: Binding(
            get: { store.stylePicker != nil },
            set: { if !$0 { store.send(.dismissStylePicker) } }
        )) {
            if let pickerStore = store.scope(state: \.stylePicker, action: \.stylePicker.presented) {
                StylePickerView(store: pickerStore)
            }
        }
        .sheet(isPresented: Binding(
            get: { store.isHistoryPresented },
            set: { store.send(.setHistoryPresented($0)) }
        )) {
            if let historyStore = store.scope(state: \.history, action: \.history) {
                PromptHistoryView(store: historyStore)
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        ThemeCard {
            VStack(spacing: 12) {
                Picker("Quality", selection: Binding(
                    get: { store.qualityTier },
                    set: { store.send(.setQualityTier($0)) }
                )) {
                    ForEach(ImageGenerateReducer.QualityTier.allCases, id: \.self) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }

                Picker("Provider", selection: Binding(
                    get: { store.selectedProvider },
                    set: { store.send(.setProvider($0)) }
                )) {
                    ForEach(ImageGenerateReducer.Provider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Picker("Aspect Ratio", selection: Binding(
                    get: { store.aspectRatio },
                    set: { store.send(.setAspectRatio($0)) }
                )) {
                    ForEach(ImageGenerateReducer.AspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
            }
            .pickerStyle(.menu)
            .padding(ThemeSpacing.md)
        }
    }

    // MARK: - Cost

    private var costSection: some View {
        HStack {
            Image(systemName: "creditcard")
                .foregroundStyle(.secondary)
            Text("Estimated cost: **\(store.estimatedCreditCost) credits**")
                .font(ThemeTypography.body)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        switch store.generationStatus {
        case .idle:
            EmptyView()

        case .generating:
            VStack(spacing: 12) {
                ProgressView()
                Text("Starting generation...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

        case .progress(let value):
            VStack(spacing: 12) {
                ProgressView(value: value, total: 100) {
                    Text("Generating...")
                        .font(.subheadline)
                } currentValueLabel: {
                    Text("\(Int(value))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            }
            .padding(.top, 20)

        case .complete(let asset):
            ThemeCard {
                VStack(spacing: 12) {
                    if let _ = asset.filePath {
                        AsyncImage(url: URL(string: "http://localhost:3000/api/assets/\(asset.id)/file")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                imageErrorPlaceholder
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    HStack {
                        Label("\(asset.creditCost) credits", systemImage: "creditcard")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(asset.provider, systemImage: "cpu")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ThemeButton("Generate Another", tier: .quiet) {
                        store.send(.reset)
                    }
                }
                .padding(ThemeSpacing.md)
            }
            .padding(.top, 20)

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ThemeButton("Retry", systemImage: "arrow.clockwise", tier: .primary) {
                    store.send(.generateTapped)
                }
            }
            .padding(.top, 20)
        }
    }

    private var imageErrorPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .frame(height: 200)
            .overlay {
                VStack {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Failed to load image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
    }
}
