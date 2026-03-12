import Testing
@testable import StudioFeature

@Test func studioReducerInitialState() {
    let state = StudioReducer.State()
    #expect(state.currentProject == nil)
    #expect(state.recentGenerations.isEmpty)
    #expect(state.creditBalance == 0)
    #expect(state.lastEditedItems.isEmpty)
    #expect(state.isLoading == false)
    #expect(state.error == nil)
}

@Test func qualityPresetDisplayNames() {
    #expect(QualityPreset.quickDraft.displayName == "Quick Draft")
    #expect(QualityPreset.standard.displayName == "Standard")
    #expect(QualityPreset.maxQuality.displayName == "Max Quality")
}

@Test func qualityPresetAllCases() {
    #expect(QualityPreset.allCases.count == 3)
}
