import AVKit
import ComposableArchitecture
import CoreKit
import DesignKit
import PromptFeature
import SwiftUI

public struct VideoGenerateView: View {
    @Bindable var store: StoreOf<VideoGenerateReducer>
    @FocusState private var isPromptFocused: Bool

    public init(store: StoreOf<VideoGenerateReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    modeSection
                    if store.mode == .imageToVideo {
                        sourceAssetSection
                    }
                    durationSection
                    settingsSection
                    costSection
                    resultSection
                }
                .padding()
                .padding(.bottom, 120) // space for creative stage
            }
            .navigationTitle("Generate Video")

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

    // MARK: - Mode

    private var modeSection: some View {
        Picker("Mode", selection: Binding(
            get: { store.mode },
            set: { store.send(.setMode($0)) }
        )) {
            ForEach(VideoGenerateReducer.Mode.allCases, id: \.self) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Source Asset (image-to-video)

    private var sourceAssetSection: some View {
        ThemeCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Source Image")
                    .font(ThemeTypography.heading(size: 16))

                if store.sourceAssetId != nil {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundStyle(.green)
                        Text("Image selected")
                            .font(ThemeTypography.body)
                        Spacer()
                        ThemeButton("Clear", tier: .quiet) {
                            store.send(.setSourceAsset(nil))
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .foregroundStyle(.secondary)
                        Text("Select a source image from a project")
                            .font(ThemeTypography.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(ThemeSpacing.md)
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        ThemeCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duration")
                        .font(ThemeTypography.heading(size: 16))
                    Spacer()
                    Text("\(store.duration)s")
                        .font(ThemeTypography.numerical(size: 18))
                        .foregroundStyle(ThemeColors.light.accent)
                }

                Slider(
                    value: Binding(
                        get: { Double(store.duration) },
                        set: { store.send(.setDuration(Int($0))) }
                    ),
                    in: 1...15,
                    step: 1
                )
                .tint(ThemeColors.light.accent)

                HStack {
                    Text("1s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("15s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(ThemeSpacing.md)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        ThemeCard {
            VStack(spacing: 12) {
                Picker("Resolution", selection: Binding(
                    get: { store.resolution },
                    set: { store.send(.setResolution($0)) }
                )) {
                    ForEach(VideoGenerateReducer.Resolution.allCases, id: \.self) { res in
                        Text(res.displayName).tag(res)
                    }
                }

                Picker("Quality", selection: Binding(
                    get: { store.qualityTier },
                    set: { store.send(.setQualityTier($0)) }
                )) {
                    ForEach(VideoGenerateReducer.QualityTier.allCases, id: \.self) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }

                Picker("Provider", selection: Binding(
                    get: { store.selectedProvider },
                    set: { store.send(.setProvider($0)) }
                )) {
                    ForEach(VideoGenerateReducer.Provider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Picker("Aspect Ratio", selection: Binding(
                    get: { store.aspectRatio },
                    set: { store.send(.setAspectRatio($0)) }
                )) {
                    ForEach(VideoGenerateReducer.AspectRatio.allCases, id: \.self) { ratio in
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
                Text("Starting video generation...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

        case .progress(let value):
            VStack(spacing: 12) {
                ProgressView(value: value, total: 100) {
                    Text("Generating video...")
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
                    if let url = URL(string: "http://localhost:3000/api/assets/\(asset.id)/file") {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
}
