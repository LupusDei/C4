import ComposableArchitecture
import CoreKit
import SwiftUI

public struct PromptEnhancerView: View {
    @Bindable var store: StoreOf<PromptEnhancerReducer>

    public init(store: StoreOf<PromptEnhancerReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.headline)

            if store.showEnhanced {
                enhancedSection
            } else {
                promptEditor
                enhanceButton
            }
        }
    }

    // MARK: - Prompt Editor

    private var promptEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding(
                get: { store.prompt },
                set: { store.send(.promptChanged($0)) }
            ))
            .frame(minHeight: 100)
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.tertiary, lineWidth: 1)
            )

            if store.prompt.isEmpty {
                Text("Describe what you want to create...")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Enhance Button

    private var enhanceButton: some View {
        Button {
            store.send(.enhanceTapped)
        } label: {
            HStack(spacing: 6) {
                if store.isEnhancing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(store.isEnhancing ? "Enhancing..." : "Enhance")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(store.canEnhance ? Color.accentColor : Color.gray.opacity(0.3))
            .foregroundStyle(store.canEnhance ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!store.canEnhance)
    }

    // MARK: - Enhanced Section

    private var enhancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Original prompt — muted card
            VStack(alignment: .leading, spacing: 4) {
                Text("Original")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(store.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Enhanced prompt — highlighted card, editable
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                    Text("Enhanced")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }

                TextEditor(text: Binding(
                    get: { store.enhancedPrompt ?? "" },
                    set: { newValue in
                        store.send(.enhanceResponse(.success(EnhanceResult(
                            original: store.prompt,
                            enhanced: newValue,
                            providerHints: []
                        ))))
                    }
                ))
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.accentColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    store.send(.useOriginalTapped)
                } label: {
                    Text("Use Original")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    store.send(.enhanceTapped)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-enhance")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
