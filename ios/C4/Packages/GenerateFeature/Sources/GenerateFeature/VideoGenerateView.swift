import AVKit
import ComposableArchitecture
import CoreKit
import PromptFeature
import SwiftUI

public struct VideoGenerateView: View {
    @Bindable var store: StoreOf<VideoGenerateReducer>

    public init(store: StoreOf<VideoGenerateReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                modeSection
                promptSection
                styleSection
                if store.mode == .imageToVideo {
                    sourceAssetSection
                }
                durationSection
                settingsSection
                costSection
                generateButton
                resultSection
            }
            .padding()
        }
        .navigationTitle("Generate Video")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.historyTapped)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
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

    // MARK: - Prompt

    private var promptSection: some View {
        PromptEnhancerView(
            store: store.scope(state: \.promptEnhancer, action: \.promptEnhancer)
        )
    }

    // MARK: - Style

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.headline)

            Button {
                store.send(.styleButtonTapped)
            } label: {
                HStack {
                    if let style = store.selectedStyle {
                        Image(systemName: "paintpalette.fill")
                            .foregroundStyle(Color.accentColor)
                        Text(style.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button {
                            store.send(.setDefaultStyle(nil))
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Image(systemName: "paintpalette")
                            .foregroundStyle(.secondary)
                        Text("Choose a style...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Source Asset (image-to-video)

    private var sourceAssetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source Image")
                .font(.headline)

            if store.sourceAssetId != nil {
                HStack {
                    Image(systemName: "photo.fill")
                        .foregroundStyle(.green)
                    Text("Image selected")
                        .font(.subheadline)
                    Spacer()
                    Button("Clear") {
                        store.send(.setSourceAsset(nil))
                    }
                    .font(.caption)
                }
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                HStack {
                    Image(systemName: "photo.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("Select a source image from a project")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Duration")
                    .font(.headline)
                Spacer()
                Text("\(store.duration)s")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
            }

            Slider(
                value: Binding(
                    get: { Double(store.duration) },
                    set: { store.send(.setDuration(Int($0))) }
                ),
                in: 1...15,
                step: 1
            )

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
    }

    // MARK: - Settings

    private var settingsSection: some View {
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
    }

    // MARK: - Cost

    private var costSection: some View {
        HStack {
            Image(systemName: "creditcard")
                .foregroundStyle(.secondary)
            Text("Estimated cost: **\(store.estimatedCreditCost) credits**")
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            store.send(.generateTapped)
        } label: {
            HStack {
                if store.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "film")
                }
                Text(store.isGenerating ? "Generating..." : "Generate Video")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.canGenerate ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!store.canGenerate)
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

                Button {
                    store.send(.reset)
                } label: {
                    Text("Generate Another")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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

                Button {
                    store.send(.generateTapped)
                } label: {
                    Text("Retry")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)
        }
    }
}
