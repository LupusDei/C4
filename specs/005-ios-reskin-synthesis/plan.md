# Implementation Plan: iOS Re-Skin — Synthesis

**Branch**: `005-ios-reskin-synthesis` | **Date**: 2026-03-12
**Epic**: `C4-004` | **Priority**: P1

## Summary

Total UI/UX re-skin of the C4 iOS app combining the best elements from three design proposals (Aurora, Atelier, Prism). Phase 1 delivers a shared DesignKit package, new typography system, two-state prompt input, sticky CTA buttons, Prism Panel selectors, Studio dashboard tab, and card redesigns. Phase 2 adds content-adaptive accent color, Command Palette, and activity-responsive opacity. Built on existing TCA architecture with SwiftUI.

## Bead Map

- `C4-004` - Root: iOS Re-Skin — Synthesis
  - `C4-004.1` - Setup: DesignKit Package Scaffold
  - `C4-004.2` - Foundational: Theme System & Core Components
    - `C4-004.2.1` - SynthesisTheme with ThemeColors, ThemeTypography, ThemeSpacing
    - `C4-004.2.2` - ThemeButton component (primary/contextual/quiet tiers)
    - `C4-004.2.3` - ThemeCard component with warm shadow system
    - `C4-004.2.4` - CollapsibleSection component
  - `C4-004.3` - US1: Creative Stage Prompt Input
    - `C4-004.3.1` - CreativeStageTextField UIViewRepresentable
    - `C4-004.3.2` - Two-state expand/collapse with dim overlay
    - `C4-004.3.3` - Drag-to-resize handle with haptic detents
    - `C4-004.3.4` - Contextual toolbar (Style/History/Enhance/Camera)
    - `C4-004.3.5` - Integrate into ImageGenerateView and VideoGenerateView
  - `C4-004.4` - US2: Navigation & Studio Dashboard
    - `C4-004.4.1` - Redesign TabView with 4 tabs + accent dot indicators
    - `C4-004.4.2` - StudioView dashboard (project spotlight, carousel, credit card)
    - `C4-004.4.3` - BreadcrumbView for project navigation
    - `C4-004.4.4` - Wire Studio tab data (TCA reducer)
  - `C4-004.5` - US3: Button Hierarchy & Sticky CTA
    - `C4-004.5.1` - Sticky CTA overlay in ImageGenerateView
    - `C4-004.5.2` - Sticky CTA overlay in VideoGenerateView
    - `C4-004.5.3` - Apply three-tier hierarchy across all views
  - `C4-004.6` - US4: Prism Panel Selectors
    - `C4-004.6.1` - PanelPicker generic component
    - `C4-004.6.2` - AspectRatioPanelView with visual ratio cards
    - `C4-004.6.3` - QualityPanelView with mini-cards + cost badges
    - `C4-004.6.4` - ProviderPanelView with logo cards
    - `C4-004.6.5` - DurationStepperView with haptic feedback
    - `C4-004.6.6` - Integrate panels into generate views (replace .menu pickers)
  - `C4-004.7` - US5: Card System & Visual Polish
    - `C4-004.7.1` - Restyle ProjectListView cards
    - `C4-004.7.2` - Restyle StoryboardTimelineView scene cards (300pt, film-frame)
    - `C4-004.7.3` - Restyle generation result cards (masonry grid, entrance animation)
    - `C4-004.7.4` - Restyle CreditView transactions
  - `C4-004.8` - US6: Floating Credit Pill & Micro-Interactions
    - `C4-004.8.1` - CreditPill floating overlay component
    - `C4-004.8.2` - Mechanical counter animation for balance
    - `C4-004.8.3` - Generation completion toast banner
    - `C4-004.8.4` - Wire CreditPill into root navigation
  - `C4-004.9` - US7: Content-Adaptive Accent Color (Phase 2)
    - `C4-004.9.1` - AdaptiveColorEngine (CIAreaAverage + WCAG check)
    - `C4-004.9.2` - Settings toggle UI ("Adaptive Color")
    - `C4-004.9.3` - Wire accent color into SynthesisTheme
  - `C4-004.10` - US8: Command Palette (Phase 2)
    - `C4-004.10.1` - CommandPaletteView with fuzzy search
    - `C4-004.10.2` - Index all app entities for search
    - `C4-004.10.3` - Double-tap status bar gesture trigger
  - `C4-004.11` - US9: Activity-Responsive Opacity (Phase 2)
    - `C4-004.11.1` - ActivityMode TCA state enum
    - `C4-004.11.2` - ActivityResponder ViewModifier
    - `C4-004.11.3` - Wire into generate views
  - `C4-004.12` - Accessibility & Polish
    - `C4-004.12.1` - Reduce Motion fallbacks for all animations
    - `C4-004.12.2` - Reduce Transparency solid fill fallbacks
    - `C4-004.12.3` - Dynamic Type testing + layout wrapping
    - `C4-004.12.4` - VoiceOver semantic grouping for all custom components

## Technical Context

**Stack**: Swift, SwiftUI, TCA (Composable Architecture), SPM packages
**Storage**: N/A (UI-only, uses existing API/models)
**Testing**: SwiftUI Previews, manual device testing, XCTest for TCA reducers
**Constraints**: iOS 17+, iPhone + iPad, light/dark mode, Dynamic Type XXXL, Reduce Motion

## Architecture Decision

Create a new `DesignKit` SPM package as a **sibling** to CoreKit (not nested), importable by all feature packages. This centralizes the design system without polluting the data/API layer in CoreKit. DesignKit has no dependency on CoreKit — it's pure UI.

The CreativeStageTextField uses `UIViewRepresentable` wrapping `UITextView` because SwiftUI's `TextEditor` lacks `intrinsicContentSize` tracking, delegate-based height updates, and custom input accessory views. This is the same pattern used successfully in messaging apps for auto-expanding chat inputs.

PanelPicker uses `matchedGeometryEffect` for pill-to-panel transitions and `@Namespace` for animation coordination. Each panel is a generic view conforming to a `PanelContent` protocol.

## Files Changed

| File | Change |
|------|--------|
| `ios/C4/Packages/DesignKit/` | New SPM package (entire directory) |
| `ios/C4/Packages/DesignKit/Sources/DesignKit/Theme/` | SynthesisTheme, ThemeColors, ThemeTypography, ThemeSpacing |
| `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/` | ThemeButton, ThemeCard, CreativeStageTextField, PanelPicker, CreditPill, CollapsibleSection, BreadcrumbView |
| `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift` | Replace TextEditor + pickers + button with CreativeStage + PanelPicker + sticky CTA |
| `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/VideoGenerateView.swift` | Same as ImageGenerateView |
| `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateReducer.swift` | Add ActivityMode state |
| `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/VideoGenerateReducer.swift` | Add ActivityMode state |
| `ios/C4App/C4App.swift` or `ios/C4/C4App.swift` | Redesign TabView, add Studio tab, wire CreditPill overlay |
| `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/ProjectListView.swift` | Restyle project cards |
| `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/ProjectDetailView.swift` | Add BreadcrumbView |
| `ios/C4/Packages/StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift` | Restyle scene cards to 300pt, film-frame |
| `ios/C4/Packages/StoryboardFeature/Sources/StoryboardFeature/SceneCardView.swift` | Film-frame aesthetic, accent connector lines |
| `ios/C4/Packages/CreditFeature/Sources/CreditFeature/CreditView.swift` | Restyle transactions, add mechanical counter |
| `ios/C4/Packages/PromptFeature/Sources/PromptFeature/PromptEnhancerView.swift` | Editorial markup style for enhanced prompts |
| `ios/C4.xcodeproj/project.pbxproj` | Add DesignKit package reference |

## Phase 1: Setup (C4-004.1)
Create the DesignKit SPM package scaffold with Package.swift, directory structure, and add it as a dependency to all feature packages + the app target.

## Phase 2: Foundational (C4-004.2)
Build the theme system (SynthesisTheme with colors, typography, spacing) and core reusable components (ThemeButton, ThemeCard, CollapsibleSection). These are required by all subsequent user stories.

## Phase 3: US1 — Creative Stage Prompt Input (C4-004.3, MVP)
Build CreativeStageTextField and integrate into both generate views. This is the highest-impact single change.

## Phase 4: US2 — Navigation & Studio Dashboard (C4-004.4)
Redesign tab bar, build StudioView, add BreadcrumbView. Can run in parallel with US1 (different files).

## Phase 5: US3 — Button Hierarchy & Sticky CTA (C4-004.5)
Make generate button sticky, apply three-tier hierarchy. Depends on ThemeButton from Phase 2.

## Phase 6: US4 — Prism Panel Selectors (C4-004.6)
Build PanelPicker and specific panel views. Integrate into generate screens. Depends on Phase 2.

## Phase 7: US5 — Card System & Visual Polish (C4-004.7)
Restyle all card-based views. Can run in parallel with Phases 5-6.

## Phase 8: US6 — Floating Credit Pill & Micro-Interactions (C4-004.8)
Build CreditPill and animation components. Depends on Phase 2.

## Phase 9: US7 — Content-Adaptive Accent Color (C4-004.9, Phase 2)
AdaptiveColorEngine + settings toggle. Depends on SynthesisTheme.

## Phase 10: US8 — Command Palette (C4-004.10, Phase 2)
Standalone feature. Depends only on DesignKit theme.

## Phase 11: US9 — Activity-Responsive Opacity (C4-004.11, Phase 2)
TCA state-driven opacity adjustments. Depends on generate view integration.

## Phase 12: Accessibility & Polish (C4-004.12)
Cross-cutting accessibility verification. Depends on all Phase 1 stories.

## Parallel Execution

After Phase 2 (Foundational), these can run in parallel across agents:
- **Track A**: US1 (Prompt Input) — touches GenerateFeature views
- **Track B**: US2 (Navigation + Studio) — touches app root + new StudioView
- **Track C**: US5 (Cards) — touches ProjectFeature, StoryboardFeature, CreditFeature

After Phase 1 stories complete:
- **Track D**: US7 (Adaptive Color) + US8 (Command Palette) + US9 (Activity Opacity) — all Phase 2, independent

US3 (Sticky CTA) and US4 (Panel Selectors) touch GenerateFeature views and should run after US1 integrates the CreativeStageTextField, or coordinate carefully.

## Verification Steps

- [ ] All feature packages import and use DesignKit without compile errors
- [ ] New York serif visible in all headings and prompt text
- [ ] Generate button stays pinned on scroll (iPhone SE through iPhone 15 Pro Max)
- [ ] Prompt input expand/collapse smooth at 60fps on iPhone 13
- [ ] Settings pills show current config, panels open/close correctly
- [ ] Studio tab shows dashboard with real data
- [ ] Credit pill visible and updating on all screens
- [ ] Dark mode: all screens readable with espresso background
- [ ] Reduce Motion: all animations fall back to fades
- [ ] Dynamic Type XXXL: no clipped text, layouts adapt
- [ ] VoiceOver: all interactive elements announced properly
