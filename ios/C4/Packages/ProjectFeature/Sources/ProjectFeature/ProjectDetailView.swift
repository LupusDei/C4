import ComposableArchitecture
import CoreKit
import PromptFeature
import StoryboardFeature
import SwiftUI

public struct ProjectDetailView: View {
    @Bindable var store: StoreOf<ProjectDetailReducer>

    public init(store: StoreOf<ProjectDetailReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                defaultStyleSection
                storyboardsSection
                assetGridSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(store.project.title)
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { store.stylePicker != nil },
            set: { if !$0 { store.send(.dismissStylePicker) } }
        )) {
            if let pickerStore = store.scope(state: \.stylePicker, action: \.stylePicker.presented) {
                StylePickerView(store: pickerStore)
            }
        }
    }

    // MARK: - Default Style

    private var defaultStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default Style")
                .font(.title3.bold())

            Button {
                store.send(.styleButtonTapped)
            } label: {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(store.defaultStyle != nil ? Color.accentColor : .secondary)

                    if let style = store.defaultStyle {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(style.name)
                                .font(.subheadline.weight(.medium))
                            Text(StylePickerReducer.categoryDisplayName(style.category))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("None")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Storyboards

    private var storyboardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Storyboards")
                    .font(.title3.bold())
                Spacer()
                NavigationLink {
                    StoryboardListView(
                        store: Store(
                            initialState: StoryboardListReducer.State(projectId: store.project.id)
                        ) {
                            StoryboardListReducer()
                        }
                    )
                } label: {
                    Label("View All", systemImage: "rectangle.stack")
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Asset Grid

    private var assetGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assets")
                    .font(.title3.bold())
                Spacer()
                Text("\(store.assets.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if store.isLoadingAssets {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if store.assets.isEmpty {
                assetEmptyState
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8) {
                    ForEach(store.assets) { asset in
                        assetThumbnail(asset)
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.send(.deleteAsset(asset.id))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private var assetEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No assets yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Generate images or videos to see them here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func assetThumbnail(_ asset: Asset) -> some View {
        AsyncImage(url: URL(string: "http://localhost:3000/api/assets/\(asset.id)/thumbnail")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            case .failure:
                thumbnailPlaceholder(for: asset)
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
            @unknown default:
                thumbnailPlaceholder(for: asset)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .bottomTrailing) {
            if asset.type == .video {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }

    private func thumbnailPlaceholder(for asset: Asset) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                Image(systemName: asset.type == .video ? "film" : "photo")
                    .foregroundStyle(.secondary)
            }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title3.bold())

            // Add note
            HStack {
                TextField("Add a note...", text: Binding(
                    get: { store.newNoteContent },
                    set: { store.send(.setNewNoteContent($0)) }
                ))
                .textFieldStyle(.roundedBorder)

                Button {
                    store.send(.addNote)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(store.newNoteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.isLoadingNotes {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if store.notes.isEmpty {
                Text("No notes yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(store.notes) { note in
                    noteRow(note)
                }
            }
        }
    }

    private func noteRow(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if store.editingNoteId == note.id {
                HStack {
                    TextField("Edit note", text: Binding(
                        get: { store.editingNoteContent },
                        set: { store.send(.setEditingNoteContent($0)) }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Button { store.send(.saveEditingNote) } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Button { store.send(.cancelEditingNote) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Text(note.content)
                    .font(.body)

                HStack {
                    Text(note.updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Button {
                        store.send(.startEditingNote(note))
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }

                    Button {
                        store.send(.deleteNote(note.id))
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
