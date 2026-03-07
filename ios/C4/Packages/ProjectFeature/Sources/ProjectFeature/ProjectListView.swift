import ComposableArchitecture
import CoreKit
import SwiftUI

public struct ProjectListView: View {
    @Bindable var store: StoreOf<ProjectListReducer>
    @State private var useGrid = true

    public init(store: StoreOf<ProjectListReducer>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if store.isLoading && store.projects.isEmpty {
                ProgressView("Loading projects...")
            } else if store.projects.isEmpty {
                emptyState
            } else if useGrid {
                gridView
            } else {
                listView
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { store.send(.createTapped) } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    useGrid.toggle()
                } label: {
                    Image(systemName: useGrid ? "list.bullet" : "square.grid.2x2")
                }
            }
        }
        .refreshable {
            store.send(.loadProjects)
        }
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { store.showCreateSheet },
            set: { if !$0 { store.send(.dismissCreateSheet) } }
        )) {
            createProjectSheet
        }
        .navigationDestination(
            item: Binding(
                get: { store.selectedProject.map { _ in true } },
                set: { if $0 != true { store.send(.clearSelection) } }
            )
        ) { _ in
            if store.selectedProject != nil {
                ProjectDetailView(
                    store: store.scope(
                        state: \.selectedProject!,
                        action: \.projectDetail
                    )
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Projects", systemImage: "folder")
        } description: {
            Text("Create a project to start generating content.")
        } actions: {
            Button("Create Project") {
                store.send(.createTapped)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
            ], spacing: 16) {
                ForEach(store.projects) { project in
                    projectCard(project)
                        .onTapGesture { store.send(.selectProject(project)) }
                        .contextMenu {
                            Button(role: .destructive) {
                                store.send(.deleteProject(project.id))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }

    private func projectCard(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.title)
                .foregroundStyle(Color.accentColor)

            Text(project.title)
                .font(.headline)
                .lineLimit(2)

            if !project.description.isEmpty {
                Text(project.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(project.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - List View

    private var listView: some View {
        List {
            ForEach(store.projects) { project in
                Button { store.send(.selectProject(project)) } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading) {
                            Text(project.title)
                                .font(.body)
                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text(project.updatedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.send(.deleteProject(project.id))
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Create Sheet

    private var createProjectSheet: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Title", text: Binding(
                        get: { store.newProjectTitle },
                        set: { store.send(.setNewProjectTitle($0)) }
                    ))

                    TextField("Description (optional)", text: Binding(
                        get: { store.newProjectDescription },
                        set: { store.send(.setNewProjectDescription($0)) }
                    ))
                }
            }
            .navigationTitle("New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.dismissCreateSheet) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { store.send(.submitCreateProject) }
                        .disabled(store.newProjectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
