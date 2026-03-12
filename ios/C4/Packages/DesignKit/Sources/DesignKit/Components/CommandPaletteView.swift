import SwiftUI

// MARK: - CommandPaletteItem

/// A single searchable item in the command palette.
public struct CommandPaletteItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let iconSystemName: String
    public let category: CommandCategory

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        iconSystemName: String,
        category: CommandCategory
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.category = category
    }
}

// MARK: - CommandCategory

/// Categories of searchable entities in the command palette.
public enum CommandCategory: String, CaseIterable, Sendable {
    case project = "Projects"
    case prompt = "Prompts"
    case style = "Styles"
    case generation = "Generations"
    case setting = "Settings"

    public var iconSystemName: String {
        switch self {
        case .project: "folder"
        case .prompt: "text.quote"
        case .style: "paintpalette"
        case .generation: "sparkles"
        case .setting: "gear"
        }
    }
}

// MARK: - FuzzyMatchResult

/// A fuzzy search match result with score and matched character ranges.
public struct FuzzyMatchResult: Identifiable {
    public let id: String
    public let item: CommandPaletteItem
    public let score: Int
    public let matchedRanges: [Range<String.Index>]

    public init(item: CommandPaletteItem, score: Int, matchedRanges: [Range<String.Index>]) {
        self.id = item.id
        self.item = item
        self.score = score
        self.matchedRanges = matchedRanges
    }
}

// MARK: - CommandPaletteIndex

/// Indexes all app entities for fuzzy search in the command palette.
public final class CommandPaletteIndex: @unchecked Sendable {
    private var items: [CommandPaletteItem] = []

    public init() {}

    /// Register items for search.
    public func register(_ newItems: [CommandPaletteItem]) {
        items.append(contentsOf: newItems)
    }

    /// Remove all items of a given category.
    public func clear(category: CommandCategory) {
        items.removeAll { $0.category == category }
    }

    /// Remove all indexed items.
    public func clearAll() {
        items.removeAll()
    }

    /// Perform fuzzy search, returning results sorted by score (highest first).
    public func search(query: String) -> [FuzzyMatchResult] {
        guard !query.isEmpty else { return [] }

        let lowercaseQuery = query.lowercased()
        var results: [FuzzyMatchResult] = []

        for item in items {
            if let result = fuzzyMatch(query: lowercaseQuery, in: item) {
                results.append(result)
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    /// Simple fuzzy match: characters must appear in order in the target string.
    /// Score is based on consecutive character matches (bonus for sequences).
    private func fuzzyMatch(query: String, in item: CommandPaletteItem) -> FuzzyMatchResult? {
        let target = item.title.lowercased()
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex
        var score = 0
        var consecutiveBonus = 0
        var matchedRanges: [Range<String.Index>] = []
        var currentRangeStart: String.Index?

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                score += 1 + consecutiveBonus
                consecutiveBonus += 1

                // Track matched character position in original string
                let originalIndex = item.title.index(item.title.startIndex, offsetBy: target.distance(from: target.startIndex, to: targetIndex))
                if currentRangeStart == nil {
                    currentRangeStart = originalIndex
                }
                let nextOriginalIndex = item.title.index(after: originalIndex)

                queryIndex = query.index(after: queryIndex)
                targetIndex = target.index(after: targetIndex)

                // Check if next char continues the match
                if queryIndex >= query.endIndex || targetIndex >= target.endIndex ||
                   query[queryIndex] != target[targetIndex] {
                    // End current range
                    if let start = currentRangeStart {
                        matchedRanges.append(start..<nextOriginalIndex)
                        currentRangeStart = nil
                    }
                }
            } else {
                consecutiveBonus = 0
                if let start = currentRangeStart {
                    let prevOriginalIndex = item.title.index(item.title.startIndex, offsetBy: target.distance(from: target.startIndex, to: targetIndex))
                    matchedRanges.append(start..<prevOriginalIndex)
                    currentRangeStart = nil
                }
                targetIndex = target.index(after: targetIndex)
            }
        }

        // All query characters must be matched
        guard queryIndex == query.endIndex else { return nil }

        // Bonus for matching at the start of the string
        if let firstRange = matchedRanges.first, firstRange.lowerBound == item.title.startIndex {
            score += 5
        }

        return FuzzyMatchResult(item: item, score: score, matchedRanges: matchedRanges)
    }
}

// MARK: - CommandPaletteView

/// A full-screen Spotlight-style command palette overlay.
/// Triggered by double-tap on status bar or programmatic presentation.
///
/// ```swift
/// .overlay {
///     if showPalette {
///         CommandPaletteView(
///             index: paletteIndex,
///             recentItems: recentActions,
///             onSelect: { item in handleSelection(item) },
///             onDismiss: { showPalette = false }
///         )
///     }
/// }
/// ```
public struct CommandPaletteView: View {
    private let index: CommandPaletteIndex
    private let recentItems: [CommandPaletteItem]
    private let onSelect: @MainActor (CommandPaletteItem) -> Void
    private let onDismiss: @MainActor () -> Void

    @State private var searchText = ""
    @State private var results: [FuzzyMatchResult] = []
    @FocusState private var isSearchFocused: Bool

    public init(
        index: CommandPaletteIndex,
        recentItems: [CommandPaletteItem] = [],
        onSelect: @escaping @MainActor (CommandPaletteItem) -> Void,
        onDismiss: @escaping @MainActor () -> Void
    ) {
        self.index = index
        self.recentItems = recentItems
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    TextField("Search actions, projects, settings...", text: $searchText)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .onSubmit {
                            if let first = results.first {
                                onSelect(first.item)
                            }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)

                Divider()

                // Results or recents
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if searchText.isEmpty {
                            recentSection
                        } else if results.isEmpty {
                            noResultsView
                        } else {
                            resultsSection
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 40, y: 10)
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 200)
        }
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { _, newValue in
            results = index.search(query: newValue)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Recent Section

    @ViewBuilder
    private var recentSection: some View {
        if !recentItems.isEmpty {
            Section {
                ForEach(recentItems) { item in
                    commandRow(item: item, matchedRanges: [])
                }
            } header: {
                sectionHeader("Recent")
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.title)
                    .foregroundStyle(.tertiary)
                Text("No recent actions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        let grouped = Dictionary(grouping: results, by: { $0.item.category })
        return ForEach(CommandCategory.allCases, id: \.self) { category in
            if let categoryResults = grouped[category], !categoryResults.isEmpty {
                Section {
                    ForEach(categoryResults) { result in
                        commandRow(item: result.item, matchedRanges: result.matchedRanges)
                    }
                } header: {
                    sectionHeader(category.rawValue)
                }
            }
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }

    private func commandRow(item: CommandPaletteItem, matchedRanges: [Range<String.Index>]) -> some View {
        Button {
            onSelect(item)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.iconSystemName)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    highlightedText(item.title, ranges: matchedRanges)
                        .font(.body)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Text(item.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(item.category.rawValue)")
        .accessibilityHint(item.subtitle ?? "")
    }

    /// Renders text with accent-colored highlights on matched character ranges.
    private func highlightedText(_ text: String, ranges: [Range<String.Index>]) -> Text {
        guard !ranges.isEmpty else {
            return Text(text).foregroundColor(.primary)
        }

        var result = Text("")
        var currentIndex = text.startIndex

        for range in ranges {
            // Add non-matched text before this range
            if currentIndex < range.lowerBound {
                result = result + Text(text[currentIndex..<range.lowerBound])
                    .foregroundColor(.primary)
            }
            // Add matched text with accent color
            result = result + Text(text[range])
                .foregroundColor(.accentColor)
                .bold()

            currentIndex = range.upperBound
        }

        // Add remaining text after last match
        if currentIndex < text.endIndex {
            result = result + Text(text[currentIndex..<text.endIndex])
                .foregroundColor(.primary)
        }

        return result
    }
}

// MARK: - Preview

#Preview("Command Palette") {
    CommandPalettePreview()
}

@MainActor
private struct CommandPalettePreview: View {
    @State private var showPalette = true

    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .ignoresSafeArea()

            VStack {
                Text("Main App Content")
                    .font(.title)
                Button("Show Command Palette") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showPalette = true
                    }
                }
            }

            if showPalette {
                CommandPaletteView(
                    index: {
                        let index = CommandPaletteIndex()
                        index.register([
                            .init(id: "1", title: "Generate Image", subtitle: "Create a new image from text", iconSystemName: "sparkles", category: .generation),
                            .init(id: "2", title: "Generate Video", subtitle: "Create a new video clip", iconSystemName: "film", category: .generation),
                            .init(id: "3", title: "My Film Project", subtitle: "Last edited 2h ago", iconSystemName: "folder", category: .project),
                            .init(id: "4", title: "Cinematic Style", iconSystemName: "paintpalette", category: .style),
                            .init(id: "5", title: "Settings", iconSystemName: "gear", category: .setting),
                            .init(id: "6", title: "General Settings", iconSystemName: "gear", category: .setting),
                        ])
                        return index
                    }(),
                    recentItems: [
                        .init(id: "1", title: "Generate Image", iconSystemName: "sparkles", category: .generation),
                        .init(id: "3", title: "My Film Project", iconSystemName: "folder", category: .project),
                    ],
                    onSelect: { _ in showPalette = false },
                    onDismiss: { showPalette = false }
                )
            }
        }
    }
}
