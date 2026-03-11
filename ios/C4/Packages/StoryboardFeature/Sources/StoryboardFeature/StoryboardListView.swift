import ComposableArchitecture
import CoreKit
import SwiftUI

public struct StoryboardListView: View {
    @Bindable var store: StoreOf<StoryboardListReducer>

    public init(store: StoreOf<StoryboardListReducer>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading && store.storyboards.isEmpty {
                ProgressView("Loading storyboards...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.storyboards.isEmpty {
                emptyState
            } else {
                storyboardList
            }
        }
        .navigationTitle("Storyboards")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { store.send(.createTapped) } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            store.send(.loadStoryboards)
        }
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { store.showCreateSheet },
            set: { if !$0 { store.send(.dismissCreateSheet) } }
        )) {
            createStoryboardSheet
        }
        .navigationDestination(
            item: Binding(
                get: { store.selectedStoryboard.map { _ in true } },
                set: { if $0 != true { store.send(.clearSelection) } }
            )
        ) { _ in
            if store.selectedStoryboard != nil {
                StoryboardTimelineView(
                    store: store.scope(
                        state: \.selectedStoryboard!,
                        action: \.timeline
                    )
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Storyboards", systemImage: "rectangle.stack")
        } description: {
            Text("Create a storyboard to start building scenes.")
        } actions: {
            Button("New Storyboard") {
                store.send(.createTapped)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Storyboard List

    private var storyboardList: some View {
        List {
            ForEach(store.storyboards) { storyboard in
                Button {
                    store.send(.selectStoryboard(storyboard))
                } label: {
                    storyboardRow(storyboard)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.send(.deleteStoryboard(storyboard.id))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func storyboardRow(_ storyboard: Storyboard) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(storyboard.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    statusBadge(for: storyboard.status)

                    if let scenes = storyboard.scenes {
                        Text("\(scenes.count) scenes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(storyboard.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func statusBadge(for status: StoryboardStatus) -> some View {
        let (label, color): (String, Color) = switch status {
        case .draft: ("Draft", .secondary)
        case .generating: ("Generating", .orange)
        case .complete: ("Complete", .green)
        case .assembled: ("Assembled", .blue)
        }

        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    // MARK: - Create Sheet

    private var createStoryboardSheet: some View {
        NavigationStack {
            Form {
                Section("Storyboard Details") {
                    TextField("Title", text: Binding(
                        get: { store.newStoryboardTitle },
                        set: { store.send(.setNewStoryboardTitle($0)) }
                    ))
                }
            }
            .navigationTitle("New Storyboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.dismissCreateSheet) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { store.send(.submitCreateStoryboard) }
                        .disabled(store.newStoryboardTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
