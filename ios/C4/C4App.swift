import ComposableArchitecture
import CreditFeature
import GenerateFeature
import ProjectFeature
import StoryboardFeature
import SwiftUI

@main
struct C4App: App {
    @State private var showCommandPalette = false

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                TabView {
                    Tab("Projects", systemImage: "folder.fill") {
                        NavigationStack {
                            ProjectListView(store: Store(initialState: ProjectListReducer.State()) {
                                ProjectListReducer()
                            })
                        }
                    }

                    Tab("Generate", systemImage: "sparkles") {
                        NavigationStack {
                            GenerateTabView()
                        }
                    }

                    Tab("Credits", systemImage: "creditcard.fill") {
                        NavigationStack {
                            CreditView(store: Store(initialState: CreditReducer.State()) {
                                CreditReducer()
                            })
                        }
                    }
                }

                // Command palette trigger: double-tap top safe area
                Color.clear
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(duration: 0.35)) {
                            showCommandPalette.toggle()
                        }
                    }
                    .allowsHitTesting(true)

                // Command palette overlay
                if showCommandPalette {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.35)) {
                                showCommandPalette = false
                            }
                        }

                    CommandPaletteView(isPresented: $showCommandPalette)
                        .padding(.top, 60)
                }
            }
        }
    }
}
