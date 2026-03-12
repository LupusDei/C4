import ComposableArchitecture
import CoreKit
import DesignKit
import PromptFeature
import SwiftUI

public struct ImageGenerateView: View {
    @Bindable var store: StoreOf<ImageGenerateReducer>
    @FocusState private var isPromptFocused: Bool
    @State private var aspectRatioId: String = "1:1"
    @State private var qualityId: String = "standard"
    @State private var providerId: String = "auto"

    public init(store: StoreOf<ImageGenerateReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                promptSection
                styleSection
                    .activityResponsive()
                settingsSection
                    .activityResponsive()
                costSection
                resultSection
            }
            .padding()
            .padding(.bottom, 80) // Space for sticky CTA
        }
        .stickyCtaOverlay(
            title: "Generate Image",
            isLoading: store.isGenerating,
            isDisabled: !store.canGenerate,
            action: { store.send(.generateTapped) }
        )
        .overlay(alignment: .top) {
            if store.showCompletionToast {
                CompletionToast(
                    message: "Image generated successfully",
                    onView: { store.send(.dismissCompletionToast) },
                    onDismiss: { store.send(.dismissCompletionToast) }
                )
            }
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
        .warmBackground()
        .synthesisTheme()
        .activityMode(store.activityMode)
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
            if let historyStore = store.scope(state: \.history, action: \.history.presented) {
                PromptHistoryView(store: historyStore)
            }
        }
        .onAppear {
            aspectRatioId = store.aspectRatio.rawValue
            qualityId = store.qualityTier.rawValue
            providerId = store.selectedProvider.rawValue
        }
        .onChange(of: aspectRatioId) { _, newValue in
            if let ratio = ImageGenerateReducer.AspectRatio(rawValue: newValue) {
                store.send(.setAspectRatio(ratio))
            }
        }
        .onChange(of: qualityId) { _, newValue in
            if let tier = ImageGenerateReducer.QualityTier(rawValue: newValue) {
                store.send(.setQualityTier(tier))
            }
        }
        .onChange(of: providerId) { _, newValue in
            if let provider = ImageGenerateReducer.Provider(rawValue: newValue) {
                store.send(.setProvider(provider))
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
                options: AspectRatioOption.imageOptions,
                selectedId: $aspectRatioId
            )

            QualityPanelView(
                options: [
                    QualityOption(id: "budget", name: "Budget", description: "Fast, lower detail", iconSystemName: "bolt.fill", creditCost: 2),
                    QualityOption(id: "standard", name: "Standard", description: "Balanced quality", iconSystemName: "scalemass.fill", creditCost: 5),
                    QualityOption(id: "premium", name: "Premium", description: "Maximum detail", iconSystemName: "crown.fill", creditCost: 10),
                ],
                selectedId: $qualityId
            )

            ProviderPanelView(
                options: ImageGenerateReducer.Provider.allCases.map { provider in
                    ProviderOption(
                        id: provider.rawValue,
                        name: provider.displayName,
                        initials: String(provider.displayName.prefix(2)).uppercased(),
                        isRecommended: provider == .auto
                    )
                },
                selectedId: $providerId
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

                ThemeButton("Retry", systemImage: "arrow.clockwise", tier: .primary) {
                    store.send(.generateTapped)
                }
            }
            .padding(.top, 20)
        }
    }
}
