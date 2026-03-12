import ComposableArchitecture
import CreditFeature
import DesignKit
import GenerateFeature
import ProjectFeature
import StoryboardFeature
import StudioFeature
import SwiftUI

@main
struct C4App: App {
    @State private var creditBalance: Int = 0
    @State private var showCreditSheet = false
    @State private var selectedTab: AppTab = .studio

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedTab) {
                    Tab(AppTab.studio.title, systemImage: AppTab.studio.icon, value: .studio) {
                        NavigationStack {
                            StudioView(store: Store(initialState: StudioReducer.State()) {
                                StudioReducer()
                            })
                        }
                    }

                    Tab(AppTab.generate.title, systemImage: AppTab.generate.icon, value: .generate) {
                        NavigationStack {
                            GenerateTabView()
                        }
                    }

                    Tab(AppTab.projects.title, systemImage: AppTab.projects.icon, value: .projects) {
                        NavigationStack {
                            ProjectListView(store: Store(initialState: ProjectListReducer.State()) {
                                ProjectListReducer()
                            })
                        }
                    }

                    Tab(AppTab.credits.title, systemImage: AppTab.credits.icon, value: .credits) {
                        NavigationStack {
                            CreditView(store: Store(initialState: CreditReducer.State()) {
                                CreditReducer()
                            })
                        }
                    }
                }

                // Credit Pill overlay — top-right, above TabView
                CreditPill(balance: creditBalance) {
                    showCreditSheet = true
                }
                .padding(.top, 4)
                .padding(.trailing, 16)
            }
            .sheet(isPresented: $showCreditSheet) {
                NavigationStack {
                    CreditView(store: Store(initialState: CreditReducer.State()) {
                        CreditReducer()
                    })
                }
            }
        }
    }
}

// MARK: - App Tabs

enum AppTab: String, CaseIterable {
    case studio
    case generate
    case projects
    case credits

    var title: String {
        switch self {
        case .studio: "Studio"
        case .generate: "Generate"
        case .projects: "Projects"
        case .credits: "Credits"
        }
    }

    var icon: String {
        switch self {
        case .studio: "house.fill"
        case .generate: "sparkles"
        case .projects: "folder.fill"
        case .credits: "creditcard.fill"
        }
    }
}
