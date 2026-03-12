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
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    modeSection
                    promptSection
                    styleSection
                        .activityResponsive(mode: store.activityMode)
                    if store.mode == .imageToVideo {
                        sourceAssetSection
                    }
                    settingsSection
                        .activityResponsive(mode: store.activityMode)
                    costSection
                    resultSection
                }
                .padding()
                .padding(.bottom, 80) // Space for sticky CTA
            }

            // Sticky CTA replaces the old inline generate button
            StickyCtaOverlay(
                title: "Generate Video",
                icon: "film",
                isLoading: store.isGenerating,
                isEnabled: store.canGenerate,
                action: { store.send(.generateTapped) }
            )
        }
        .overlay(alignment: .top) {
            CompletionToast(
                message: "Video generated successfully",
                isPresented: store.showCompletionToast
            )
            .animation(.spring(duration: 0.4), value: store.showCompletionToast)
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

    // MARK: - Prompt

    private var promptSection: some View {
        PromptEnhancerView(
            store: store.scope(state: \.promptEnhancer, action: \.promptEnhancer)
        )
        .onTapGesture {
            store.send(.setActivityMode(.composing))
        }
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

    // MARK: - Settings (Panel Pickers + Duration Stepper)

    private var settingsSection: some View {
        VStack(spacing: 16) {
            DurationStepperView(
                duration: store.duration,
                onSet: { store.send(.setDuration($0)) }
            )

            AspectRatioPanelView(
                options: VideoGenerateReducer.AspectRatio.allCases,
                selection: store.aspectRatio,
                onSelect: { store.send(.setAspectRatio($0)) }
            )

            PanelPicker(
                "Resolution",
                options: VideoGenerateReducer.Resolution.allCases,
                selection: store.resolution,
                label: { $0.displayName },
                onSelect: { store.send(.setResolution($0)) }
            )

            QualityPanelView(
                options: VideoGenerateReducer.QualityTier.allCases,
                selection: store.qualityTier,
                displayName: { $0.displayName },
                onSelect: { store.send(.setQualityTier($0)) }
            )

            ProviderPanelView(
                options: VideoGenerateReducer.Provider.allCases,
                selection: store.selectedProvider,
                displayName: { $0.displayName },
                onSelect: { store.send(.setProvider($0)) }
            )
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
            MasonryResultGrid(
                asset: asset,
                mediaType: .video,
                onReset: { store.send(.reset) }
            )

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
