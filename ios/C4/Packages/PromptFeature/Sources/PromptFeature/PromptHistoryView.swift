import ComposableArchitecture
import CoreKit
import SwiftUI

public struct PromptHistoryView: View {
    @Bindable var store: StoreOf<PromptHistoryReducer>
    public var onSelectPrompt: ((String) -> Void)?

    public init(
        store: StoreOf<PromptHistoryReducer>,
        onSelectPrompt: ((String) -> Void)? = nil
    ) {
        self.store = store
        self.onSelectPrompt = onSelectPrompt
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                entryList
            }
            .navigationTitle("Prompt History")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.onAppear) }
            .overlay {
                if store.isRemixing {
                    remixOverlay
                }
            }
            .alert(
                "Remix Failed",
                isPresented: Binding(
                    get: { store.remixError != nil },
                    set: { if !$0 { store.send(.dismissRemixError) } }
                ),
                presenting: store.remixError
            ) { _ in
                Button("OK") { store.send(.dismissRemixError) }
            } message: { error in
                Text(error)
            }
            .onChange(of: store.selectedEntry) { _, entry in
                if let entry {
                    let prompt = entry.enhancedPrompt ?? entry.originalPrompt
                    onSelectPrompt?(prompt)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search prompts...", text: Binding(
                get: { store.searchText },
                set: { store.send(.searchTextChanged($0)) }
            ))
            .textFieldStyle(.plain)

            if !store.searchText.isEmpty {
                Button {
                    store.send(.searchTextChanged(""))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Entry List

    private var entryList: some View {
        Group {
            if store.entries.isEmpty && !store.isLoading {
                ContentUnavailableView(
                    "No Prompts Yet",
                    systemImage: "text.bubble",
                    description: Text("Your generation prompts will appear here")
                )
            } else {
                List {
                    ForEach(store.entries) { entry in
                        PromptHistoryRow(entry: entry) {
                            store.send(.entryTapped(entry))
                        } onRemix: {
                            store.send(.remixTapped(entry))
                        }
                        .onAppear {
                            if entry.id == store.entries.last?.id {
                                store.send(.loadMore)
                            }
                        }
                    }

                    if store.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Remix Overlay

    private var remixOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Remixing prompt...")
                    .font(.headline)
            }
            .padding(32)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Row View

struct PromptHistoryRow: View {
    let entry: PromptHistory
    let onTap: () -> Void
    let onRemix: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Prompt text
                Text(entry.originalPrompt)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Metadata row
                HStack(spacing: 8) {
                    // Generation type icon
                    Image(systemName: entry.generationType == "video" ? "film" : "camera")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Provider badge
                    if let provider = entry.provider {
                        Text(provider)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(providerColor(provider).opacity(0.15))
                            .foregroundStyle(providerColor(provider))
                            .clipShape(Capsule())
                    }

                    // Asset thumbnail indicator
                    if entry.assetId != nil {
                        Image(systemName: "photo.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    // Date
                    Text(entry.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Remix button
                HStack {
                    Spacer()
                    Button {
                        onRemix()
                    } label: {
                        Label("Remix", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func providerColor(_ provider: String) -> Color {
        switch provider.lowercased() {
        case "openai": .green
        case "flux": .purple
        case "grok-imagine": .orange
        case "kling": .blue
        case "runway": .red
        case "hailuo": .pink
        default: .secondary
        }
    }
}
