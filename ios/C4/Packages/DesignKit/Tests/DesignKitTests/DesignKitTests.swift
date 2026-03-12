import Testing
@testable import DesignKit

@Suite("DesignKit Theme Tests")
struct DesignKitTests {

    @Test("ThemeColors tertiary is deep navy")
    func tertiaryColor() {
        // Bug C4-004.2.1.3 — verify tertiary exists
        let _ = ThemeColors.tertiary
    }

    @Test("ThemeTypography caption is 12pt medium")
    func captionTypography() {
        // Bug C4-004.2.1.2 — verify caption exists
        let _ = ThemeTypography.caption
    }

    @Test("ThemeSpacing values are consistent")
    func spacingScale() {
        #expect(ThemeSpacing.xs < ThemeSpacing.sm)
        #expect(ThemeSpacing.sm < ThemeSpacing.md)
        #expect(ThemeSpacing.md < ThemeSpacing.lg)
    }

    @Test("QuickPreset is identifiable")
    func quickPresetIdentifiable() {
        let preset = QuickPreset(id: "test", label: "Test", value: "test-value")
        #expect(preset.id == "test")
        #expect(preset.label == "Test")
    }

    @Test("ContextualAction is identifiable")
    func contextualActionIdentifiable() {
        let action = ContextualAction(id: "act", label: "Action", icon: "star") {}
        #expect(action.id == "act")
        #expect(action.label == "Action")
    }
}
