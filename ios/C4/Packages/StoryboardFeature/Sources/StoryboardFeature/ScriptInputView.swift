import ComposableArchitecture
import CoreKit
import SwiftUI

public struct ScriptInputView: View {
    @Bindable var store: StoreOf<StoryboardReducer>

    public init(store: StoreOf<StoryboardReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scriptEditorSection
                    countsSection
                    splitButton
                    errorSection
                }
                .padding()
            }
            .navigationTitle("Script Input")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.showScriptInput(false))
                    }
                }
            }
        }
    }

    // MARK: - Script Editor

    private var scriptEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Script")
                .font(.headline)

            Text("Paste or write your script below. AI will analyze the text and split it into individual scenes with visual prompts, narration, and duration estimates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: Binding(
                get: { store.scriptText },
                set: { store.send(.setScriptText($0)) }
            ))
            .frame(minHeight: 200)
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.tertiary, lineWidth: 1)
            )
        }
    }

    // MARK: - Word/Character Count

    private var countsSection: some View {
        HStack {
            Label("\(store.wordCount) words", systemImage: "text.word.spacing")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Label("\(store.characterCount) characters", systemImage: "character.cursor.ibeam")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Split Button

    private var splitButton: some View {
        Button {
            store.send(.splitScript)
        } label: {
            HStack {
                if store.isSplittingScript {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "scissors")
                }
                Text(store.isSplittingScript ? "Splitting into Scenes..." : "Split into Scenes")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.canSplitScript ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!store.canSplitScript)
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = store.scriptError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)

                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    store.send(.dismissError)
                } label: {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)
        }

        if store.wordCount > 0 && store.wordCount < 10 {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.orange)
                Text("Script must be at least 10 words to split into scenes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}
