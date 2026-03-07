import ComposableArchitecture
import CreditFeature
import GenerateFeature
import ProjectFeature
import SwiftUI

@main
struct C4App: App {
    var body: some Scene {
        WindowGroup {
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
        }
    }
}
