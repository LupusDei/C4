import ComposableArchitecture
import CoreKit
import SwiftUI

public struct StoryboardTimelineView: View {
    @Bindable var store: StoreOf<StoryboardTimelineReducer>

    public init(store: StoreOf<StoryboardTimelineReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                ProgressView("Loading scenes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.scenes.isEmpty {
                emptyState
            } else {
                timelineContent
            }
        }
        .navigationTitle(store.storyboard.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        store.send(.addScene)
                    } label: {
                        Label("Add Scene", systemImage: "plus")
                    }

                    Button {
                        store.send(.generateAllTapped)
                    } label: {
                        Label("Generate All", systemImage: "sparkles")
                    }

                    Button {
                        store.send(.assembleTapped)
                    } label: {
                        Label("Assemble", systemImage: "film.stack")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Scenes", systemImage: "rectangle.stack")
        } description: {
            Text("Add scenes to build your storyboard timeline.")
        } actions: {
            Button("Add Scene") {
                store.send(.addScene)
            }
            .buttonStyle(.borderedProminent)
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

            // Horizontal scrollable timeline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(store.scenes.enumerated()), id: \.element.id) { index, scene in
                        SceneCardView(
                            scene: scene,
                            sceneNumber: index + 1
                        ) {
                            store.send(.selectScene(scene))
                        }
                        .draggable(scene.id.uuidString) {
                            SceneCardView(scene: scene, sceneNumber: index + 1) {}
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
                            Button(role: .destructive) {
                                store.send(.deleteScene(scene.id))
                            } label: {
                                Label("Delete Scene", systemImage: "trash")
                            }
                        }
                    }

                    // Add scene button at the end
                    addSceneButton
                }
                .padding()
            }
            .frame(maxHeight: .infinity)

            if let error = store.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
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
