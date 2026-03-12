import SwiftUI

// MARK: - Command Palette

/// A quick-action overlay triggered by double-tapping the top area.
/// Provides fast access to common generation actions.
public struct CommandPaletteView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    private var commands: [PaletteCommand] {
        let all: [PaletteCommand] = [
            PaletteCommand(title: "Generate Image", icon: "photo.fill", category: .generate),
            PaletteCommand(title: "Generate Video", icon: "film.fill", category: .generate),
            PaletteCommand(title: "View Projects", icon: "folder.fill", category: .navigate),
            PaletteCommand(title: "Check Credits", icon: "creditcard.fill", category: .navigate),
            PaletteCommand(title: "Prompt History", icon: "clock.arrow.circlepath", category: .tool),
            PaletteCommand(title: "Style Library", icon: "paintpalette.fill", category: .tool),
        ]

        if searchText.isEmpty { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type a command...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Command list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(commands) { command in
                        Button {
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: command.icon)
                                    .font(.body)
                                    .foregroundStyle(command.category.color)
                                    .frame(width: 24)

                                Text(command.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(command.category.label)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Palette Command

struct PaletteCommand: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let category: PaletteCategory
}

enum PaletteCategory {
    case generate, navigate, tool

    var label: String {
        switch self {
        case .generate: "Generate"
        case .navigate: "Navigate"
        case .tool: "Tool"
        }
    }

    var color: Color {
        switch self {
        case .generate: .purple
        case .navigate: .blue
        case .tool: .orange
        }
    }
}
