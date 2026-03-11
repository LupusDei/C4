import ComposableArchitecture
import CoreKit
import SwiftUI

public struct StoryboardTimelineView: View {
    @Bindable var store: StoreOf<StoryboardReducer>

    public init(store: StoreOf<StoryboardReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                Spacer()
                ProgressView("Loading scenes...")
                Spacer()
            } else if store.scenes.isEmpty {
                emptyState
            } else {
                timelineContent
                assemblyStatusSection
            }
        }
        .navigationTitle(store.storyboard.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtons
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showScriptInput },
            set: { store.send(.showScriptInput($0)) }
        )) {
            ScriptInputView(store: store)
        }
        .sheet(isPresented: Binding(
            get: { store.showGenerateAllSheet },
            set: { store.send(.showGenerateAllSheet($0)) }
        )) {
            generateAllSheet
        }
        .sheet(isPresented: Binding(
            get: { store.showAssembleSheet },
            set: { store.send(.showAssembleSheet($0)) }
        )) {
            assembleSheet
        }
        .sheet(isPresented: Binding(
            get: { store.showVariationsSheet },
            set: { _ in store.send(.dismissVariations) }
        )) {
            if let sceneId = store.variationsSceneId,
               let selectedScene = store.scenes.first(where: { $0.id == sceneId }) {
                SceneVariationsView(
                    store: store,
                    scene: selectedScene
                )
            }
        }
        .sheet(
            item: Binding(
                get: { store.editingScene },
                set: { if $0 == nil { store.send(.dismissSceneEditor) } }
            )
        ) { scene in
            SceneEditorSheet(scene: scene) { narration, prompt, duration in
                store.send(.updateScene(
                    id: scene.id,
                    narrationText: narration,
                    visualPrompt: prompt,
                    durationSeconds: duration
                ))
            }
        }
        .alert("Error", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.send(.dismissError) } }
        )) {
            Button("OK") { store.send(.dismissError) }
        } message: {
            if let error = store.error {
                Text(error)
            }
        }
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "text.document")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Scenes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a script to automatically split it into scenes, or create scenes manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                Button {
                    store.send(.showScriptInput(true))
                } label: {
                    Label("Add Script", systemImage: "doc.text")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    store.send(.addScene)
                } label: {
                    Label("Add Scene", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Duration summary bar
            HStack {
                Label("\(store.scenes.count) scenes", systemImage: "rectangle.stack")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "Total: %.1fs", store.totalDuration))
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Horizontal scrollable timeline with drag-drop
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(store.scenes.enumerated()), id: \.element.id) { index, sceneItem in
                        sceneCard(for: sceneItem)
                            .draggable(sceneItem.id.uuidString) {
                                sceneCard(for: sceneItem)
                                    .opacity(0.8)
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let draggedIdString = items.first,
                                      let draggedId = UUID(uuidString: draggedIdString),
                                      let fromIndex = store.scenes.firstIndex(where: { $0.id == draggedId }),
                                      fromIndex != index else { return false }
                                store.send(.moveScene(from: fromIndex, to: index))
                                return true
                            }
                            .contextMenu {
                                Button {
                                    store.send(.selectScene(sceneItem))
                                } label: {
                                    Label("Edit Scene", systemImage: "pencil")
                                }

                                Button {
                                    store.send(.showVariationsForScene(sceneItem.id))
                                } label: {
                                    Label("Variations", systemImage: "square.grid.2x2")
                                }

                                Button {
                                    store.send(.regenerateScene(sceneId: sceneItem.id))
                                } label: {
                                    Label("Regenerate", systemImage: "arrow.clockwise")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    store.send(.deleteScene(sceneItem.id))
                                } label: {
                                    Label("Delete Scene", systemImage: "trash")
                                }
                            }
                    }

                    // Add scene button at the end
                    addSceneButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func sceneCard(for sceneItem: CoreKit.Scene) -> some View {
        let status = store.sceneGenerationStatuses[sceneItem.id] ?? .idle
        let progressValue = store.sceneProgressValues[sceneItem.id] ?? 0
        return SceneCardView(
            scene: sceneItem,
            generationStatus: status,
            progress: progressValue,
            onRegenerate: {
                store.send(.regenerateScene(sceneId: sceneItem.id))
            },
            onVariations: {
                store.send(.showVariationsForScene(sceneItem.id))
            }
        )
    }

    private var addSceneButton: some View {
        Button {
            store.send(.addScene)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                Text("Add Scene")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(width: 160, height: 160)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar Buttons

    @ViewBuilder
    private var toolbarButtons: some View {
        Button {
            store.send(.showScriptInput(true))
        } label: {
            Image(systemName: "doc.text")
        }

        Button {
            store.send(.showGenerateAllSheet(true))
        } label: {
            Image(systemName: "sparkles")
        }
        .disabled(!store.canGenerateAll)

        Button {
            store.send(.showAssembleSheet(true))
        } label: {
            Image(systemName: "film.stack")
        }
        .disabled(!store.canAssemble)
    }

    // MARK: - Generate All Sheet

    private var generateAllSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Generate All Scenes")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    Picker("Quality Tier", selection: Binding(
                        get: { store.batchProvider },
                        set: { store.send(.setBatchProvider($0)) }
                    )) {
                        ForEach(StoryboardReducer.Provider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    Picker("Asset Type", selection: Binding(
                        get: { store.batchAssetType },
                        set: { store.send(.setBatchAssetType($0)) }
                    )) {
                        ForEach(StoryboardReducer.BatchAssetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                HStack {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.secondary)
                    Text("Estimated cost: **\(store.estimatedBatchCost) credits**")
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal)

                let pendingCount = store.scenes.filter {
                    store.sceneGenerationStatuses[$0.id] != .complete
                }.count
                Text("\(pendingCount) scene\(pendingCount == 1 ? "" : "s") will be generated")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.send(.generateAll)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.showGenerateAllSheet(false))
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Assemble Sheet

    private var assembleSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Assemble Video")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    Picker("Transition", selection: Binding(
                        get: { store.assemblyTransition },
                        set: { store.send(.setTransition($0)) }
                    )) {
                        ForEach(StoryboardReducer.Transition.allCases, id: \.self) { transition in
                            Text(transition.displayName).tag(transition)
                        }
                    }

                    Toggle("Enable Captions", isOn: Binding(
                        get: { store.assemblyCaptions },
                        set: { _ in store.send(.toggleCaptions) }
                    ))
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Captions will be generated from scene narration text.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    store.send(.assemble)
                } label: {
                    HStack {
                        Image(systemName: "film.stack")
                        Text("Assemble")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.showAssembleSheet(false))
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Assembly Status

    @ViewBuilder
    private var assemblyStatusSection: some View {
        switch store.assemblyStatus {
        case .idle:
            EmptyView()

        case .assembling:
            VStack(spacing: 8) {
                ProgressView()
                Text("Starting assembly...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

        case .progress(let value):
            VStack(spacing: 8) {
                ProgressView(value: value, total: 100) {
                    Text("Assembling...")
                        .font(.caption)
                }
                .progressViewStyle(.linear)
                .padding(.horizontal)

                Text("\(Int(value))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()

        case .complete(let asset):
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Video Assembled")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
                .padding(.horizontal)
            }
            .padding()
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 8)

        case .error(let message):
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    store.send(.assemble)
                } label: {
                    Text("Retry Assembly")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
}

// MARK: - Scene Editor Sheet

private struct SceneEditorSheet: View {
    let scene: Scene
    let onSave: (String, String, Double) -> Void

    @State private var narrationText: String
    @State private var visualPrompt: String
    @State private var durationSeconds: Double
    @Environment(\.dismiss) private var dismiss

    init(scene: Scene, onSave: @escaping (String, String, Double) -> Void) {
        self.scene = scene
        self.onSave = onSave
        _narrationText = State(initialValue: scene.narrationText)
        _visualPrompt = State(initialValue: scene.visualPrompt)
        _durationSeconds = State(initialValue: scene.durationSeconds)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Narration") {
                    TextEditor(text: $narrationText)
                        .frame(minHeight: 80)
                }

                Section("Visual Prompt") {
                    TextEditor(text: $visualPrompt)
                        .frame(minHeight: 80)
                }

                Section("Duration") {
                    HStack {
                        Slider(value: $durationSeconds, in: 1...30, step: 0.5)
                        Text(String(format: "%.1fs", durationSeconds))
                            .font(.subheadline.monospaced())
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            .navigationTitle("Edit Scene")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(narrationText, visualPrompt, durationSeconds)
                        dismiss()
                    }
                }
            }
        }
    }
}
