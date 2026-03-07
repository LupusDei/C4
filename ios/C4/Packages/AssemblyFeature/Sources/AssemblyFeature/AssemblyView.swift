import ComposableArchitecture
import CoreKit
import SwiftUI

public struct AssemblyView: View {
    @Bindable var store: StoreOf<AssemblyReducer>

    public init(store: StoreOf<AssemblyReducer>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clipsSection
                if !store.selectedClipIds.isEmpty {
                    selectedClipsSection
                }
                settingsSection
                assembleButton
                resultSection
            }
            .padding()
        }
        .navigationTitle("Assemble Video")
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Available Clips

    @ViewBuilder
    private var clipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Clips")
                .font(.headline)

            if store.isLoadingClips {
                ProgressView("Loading clips...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if store.availableClips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No completed video clips")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(store.availableClips) { clip in
                        clipThumbnail(clip)
                    }
                }
            }
        }
    }

    private func clipThumbnail(_ clip: Asset) -> some View {
        let isSelected = store.selectedClipIds.contains(clip.id)
        return Button {
            store.send(.toggleClip(clip.id))
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        Image(systemName: "film.fill")
                            .foregroundStyle(.secondary)
                    }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, Color.accentColor)
                        .padding(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Clips Order

    private var selectedClipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clip Order (\(store.selectedClipIds.count) selected)")
                .font(.headline)

            ForEach(Array(store.selectedClips.enumerated()), id: \.element.id) { index, clip in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Circle())

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 48, height: 27)
                        .overlay {
                            Image(systemName: "film.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                    Text(clip.prompt)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    if index > 0 {
                        Button {
                            store.send(.moveClip(from: index, to: index - 1))
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption)
                        }
                    }

                    if index < store.selectedClipIds.count - 1 {
                        Button {
                            store.send(.moveClip(from: index, to: index + 1))
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 12) {
            Picker("Aspect Ratio", selection: Binding(
                get: { store.aspectRatio },
                set: { store.send(.setAspectRatio($0)) }
            )) {
                ForEach(AssemblyReducer.AspectRatio.allCases, id: \.self) { ratio in
                    Text(ratio.rawValue).tag(ratio)
                }
            }

            Picker("Transition", selection: Binding(
                get: { store.transition },
                set: { store.send(.setTransition($0)) }
            )) {
                ForEach(AssemblyReducer.Transition.allCases, id: \.self) { transition in
                    Text(transition.displayName).tag(transition)
                }
            }

            Toggle("Enable Captions", isOn: Binding(
                get: { store.enableCaptions },
                set: { _ in store.send(.toggleCaptions) }
            ))
        }
        .pickerStyle(.menu)
    }

    // MARK: - Assemble Button

    private var assembleButton: some View {
        Button {
            store.send(.assembleTapped)
        } label: {
            HStack {
                if store.isAssembling {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "film.stack")
                }
                Text(store.isAssembling ? "Assembling..." : "Assemble Video")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(store.canAssemble ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!store.canAssemble)
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        switch store.assemblyStatus {
        case .idle:
            EmptyView()

        case .assembling:
            VStack(spacing: 12) {
                ProgressView()
                Text("Starting assembly...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

        case .progress(let value):
            VStack(spacing: 12) {
                ProgressView(value: value, total: 100) {
                    Text("Assembling...")
                        .font(.subheadline)
                } currentValueLabel: {
                    Text("\(Int(value))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            }
            .padding(.top, 20)

        case .complete(let asset):
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.green)
                            Text("Video Assembled")
                                .font(.headline)
                        }
                    }

                HStack {
                    Label("\(asset.creditCost) credits", systemImage: "creditcard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label(asset.provider, systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    store.send(.reset)
                } label: {
                    Text("Assemble Another")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    store.send(.assembleTapped)
                } label: {
                    Text("Retry")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 20)
        }

        if let error = store.error, case .idle = store.assemblyStatus {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.top, 8)
        }
    }
}
