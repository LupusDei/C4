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
        ScrollView {
            VStack(spacing: 20) {
                promptSection
                settingsSection
                costSection
                generateButton
                resultSection
            }
            .padding()
        }
        .navigationTitle("Generate Image")
    }

    // MARK: - Prompt

    private var promptSection: some View {
        PromptEnhancerView(
            store: store.scope(state: \.promptEnhancer, action: \.promptEnhancer)
        )
    }

    // MARK: - Settings

    private var settingsSection: some View {
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
                    Image(systemName: "sparkles")
                }
                Text(store.isGenerating ? "Generating..." : "Generate Image")
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
            VStack(spacing: 12) {
                if let filePath = asset.filePath {
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
