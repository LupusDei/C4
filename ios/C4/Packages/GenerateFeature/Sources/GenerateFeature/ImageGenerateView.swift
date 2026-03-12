import ComposableArchitecture
import CoreKit
import PromptFeature
import SwiftUI

public struct ImageGenerateView: View {
    @Bindable var store: StoreOf<ImageGenerateReducer>

    public init(store: StoreOf<ImageGenerateReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    promptSection
                    styleSection
                        .activityResponsive(mode: store.activityMode)
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
                title: "Generate Image",
                icon: "sparkles",
                isLoading: store.isGenerating,
                isEnabled: store.canGenerate,
                action: { store.send(.generateTapped) }
            )
        }
        .overlay(alignment: .top) {
            CompletionToast(
                message: "Image generated successfully",
                isPresented: store.showCompletionToast
            )
            .animation(.spring(duration: 0.4), value: store.showCompletionToast)
        }
        .navigationTitle("Generate Image")
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

    // MARK: - Settings (Panel Pickers)

    private var settingsSection: some View {
        VStack(spacing: 16) {
            AspectRatioPanelView(
                options: ImageGenerateReducer.AspectRatio.allCases,
                selection: store.aspectRatio,
                onSelect: { store.send(.setAspectRatio($0)) }
            )

            QualityPanelView(
                options: ImageGenerateReducer.QualityTier.allCases,
                selection: store.qualityTier,
                displayName: { $0.displayName },
                onSelect: { store.send(.setQualityTier($0)) }
            )

            ProviderPanelView(
                options: ImageGenerateReducer.Provider.allCases,
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
                .font(.subheadline)
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
            MasonryResultGrid(
                asset: asset,
                mediaType: .image,
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

                Button {
                    store.send(.generateTapped)
                } label: {
                    Text("Retry")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)
        }
    }
}
