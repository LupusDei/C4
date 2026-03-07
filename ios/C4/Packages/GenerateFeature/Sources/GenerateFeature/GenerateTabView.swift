import ComposableArchitecture
import SwiftUI

public struct GenerateTabView: View {
    public init() {}

    public var body: some View {
        List {
            NavigationLink {
                ImageGenerateView(store: Store(initialState: ImageGenerateReducer.State()) {
                    ImageGenerateReducer()
                })
            } label: {
                Label("Generate Image", systemImage: "photo.fill")
            }

            NavigationLink {
                VideoGenerateView(store: Store(initialState: VideoGenerateReducer.State()) {
                    VideoGenerateReducer()
                })
            } label: {
                Label("Generate Video", systemImage: "film.fill")
            }

            Label("Extend Video", systemImage: "arrow.right.to.line.compact")
                .foregroundStyle(.secondary)
                .badge("From project")
        }
        .navigationTitle("Generate")
    }
}
