# iOS Re-Skin — Synthesis - Beads

**Feature**: 005-ios-reskin-synthesis
**Generated**: 2026-03-12
**Source**: specs/005-ios-reskin-synthesis/tasks.md

## Root Epic

- **ID**: C4-004
- **Title**: iOS Re-Skin — Synthesis
- **Type**: epic
- **Priority**: 1
- **Description**: Total UI/UX re-skin combining best of Aurora, Atelier, and Prism proposals. Phase 1: DesignKit package, theme system, Creative Stage prompt input, Studio dashboard, sticky CTAs, Prism Panel selectors, card redesigns, micro-interactions. Phase 2: content-adaptive accent color, Command Palette, activity-responsive opacity.

## Epics

### Phase 1 — Setup: DesignKit Package Scaffold
- **ID**: C4-004.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 2

### Phase 2 — Foundational: Theme System & Core Components
- **ID**: C4-004.2
- **Type**: epic
- **Priority**: 1
- **Blocks**: US1, US2, US3, US4, US5, US6
- **Tasks**: 4

### Phase 3 — US1: Creative Stage Prompt Input
- **ID**: C4-004.3
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Tasks**: 6

### Phase 4 — US2: Navigation & Studio Dashboard
- **ID**: C4-004.4
- **Type**: epic
- **Priority**: 1
- **Tasks**: 5

### Phase 5 — US3: Button Hierarchy & Sticky CTA
- **ID**: C4-004.5
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 6 — US4: Prism Panel Selectors
- **ID**: C4-004.6
- **Type**: epic
- **Priority**: 1
- **Tasks**: 6

### Phase 7 — US5: Card System & Visual Polish
- **ID**: C4-004.7
- **Type**: epic
- **Priority**: 2
- **Tasks**: 5

### Phase 8 — US6: Floating Credit Pill & Micro-Interactions
- **ID**: C4-004.8
- **Type**: epic
- **Priority**: 2
- **Tasks**: 5

### Phase 9 — US7: Content-Adaptive Accent Color (Phase 2)
- **ID**: C4-004.9
- **Type**: epic
- **Priority**: 3
- **Tasks**: 3

### Phase 10 — US8: Command Palette (Phase 2)
- **ID**: C4-004.10
- **Type**: epic
- **Priority**: 3
- **Tasks**: 3

### Phase 11 — US9: Activity-Responsive Opacity (Phase 2)
- **ID**: C4-004.11
- **Type**: epic
- **Priority**: 3
- **Tasks**: 3

### Phase 12 — Accessibility & Polish
- **ID**: C4-004.12
- **Type**: epic
- **Priority**: 2
- **Depends**: US1, US2, US3, US4, US5, US6
- **Tasks**: 4

## Tasks

### Phase 1 — Setup

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Create DesignKit SPM package scaffold | `ios/C4/Packages/DesignKit/` | C4-004.1.1 |
| T002 | Wire DesignKit dependency to all feature packages + app target | `ios/C4.xcodeproj/project.pbxproj` | C4-004.1.2 |

### Phase 2 — Foundational

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T003 | SynthesisTheme (ThemeColors, ThemeTypography, ThemeSpacing) | `DesignKit/Theme/` | C4-004.2.1 |
| T004 | ThemeButton (primary/contextual/quiet tiers) | `DesignKit/Components/ThemeButton.swift` | C4-004.2.2 |
| T005 | ThemeCard (warm shadow system) | `DesignKit/Components/ThemeCard.swift` | C4-004.2.3 |
| T006 | CollapsibleSection component | `DesignKit/Components/CollapsibleSection.swift` | C4-004.2.4 |

### Phase 3 — US1: Creative Stage Prompt Input

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T007 | CreativeStageTextField UIViewRepresentable | `DesignKit/Components/CreativeStageTextField.swift` | C4-004.3.1 |
| T008 | CreativeStageView two-state expand/collapse | `DesignKit/Components/CreativeStageView.swift` | C4-004.3.2 |
| T009 | Drag-to-resize handle with haptic detents | `DesignKit/Components/CreativeStageView.swift` | C4-004.3.3 |
| T010 | ContextualToolbar component | `DesignKit/Components/ContextualToolbar.swift` | C4-004.3.4 |
| T011 | Integrate CreativeStage into ImageGenerateView | `GenerateFeature/ImageGenerateView.swift` | C4-004.3.5 |
| T012 | Integrate CreativeStage into VideoGenerateView | `GenerateFeature/VideoGenerateView.swift` | C4-004.3.6 |

### Phase 4 — US2: Navigation & Studio Dashboard

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T013 | Redesign TabView with 4 tabs + accent dots | `C4App.swift` | C4-004.4.1 |
| T014 | StudioReducer (TCA) | `StudioFeature/StudioReducer.swift` | C4-004.4.2 |
| T015 | StudioView dashboard | `StudioFeature/StudioView.swift` | C4-004.4.3 |
| T016 | BreadcrumbView component | `DesignKit/Components/BreadcrumbView.swift` | C4-004.4.4 |
| T017 | Wire breadcrumbs into ProjectDetailView + StoryboardTimelineView | `ProjectFeature/`, `StoryboardFeature/` | C4-004.4.5 |

### Phase 5 — US3: Button Hierarchy & Sticky CTA

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T018 | StickyCtaOverlay component | `DesignKit/Components/StickyCtaOverlay.swift` | C4-004.5.1 |
| T019 | Integrate StickyCtaOverlay into ImageGenerateView | `GenerateFeature/ImageGenerateView.swift` | C4-004.5.2 |
| T020 | Integrate StickyCtaOverlay into VideoGenerateView | `GenerateFeature/VideoGenerateView.swift` | C4-004.5.3 |
| T021 | Audit + apply three-tier button hierarchy across all views | All feature packages | C4-004.5.4 |

### Phase 6 — US4: Prism Panel Selectors

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T022 | PanelPicker generic component | `DesignKit/Components/PanelPicker.swift` | C4-004.6.1 |
| T023 | AspectRatioPanelView | `GenerateFeature/Panels/AspectRatioPanelView.swift` | C4-004.6.2 |
| T024 | QualityPanelView | `GenerateFeature/Panels/QualityPanelView.swift` | C4-004.6.3 |
| T025 | ProviderPanelView | `GenerateFeature/Panels/ProviderPanelView.swift` | C4-004.6.4 |
| T026 | DurationStepperView | `GenerateFeature/Panels/DurationStepperView.swift` | C4-004.6.5 |
| T027 | Integrate panels into generate views | `GenerateFeature/ImageGenerateView.swift`, `VideoGenerateView.swift` | C4-004.6.6 |

### Phase 7 — US5: Card System & Visual Polish

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T028 | Restyle ProjectListView cards | `ProjectFeature/ProjectListView.swift` | C4-004.7.1 |
| T029 | Restyle SceneCardView (300pt, film-frame) | `StoryboardFeature/SceneCardView.swift` | C4-004.7.2 |
| T030 | Accent connector lines + dashed Add Scene card | `StoryboardFeature/StoryboardTimelineView.swift` | C4-004.7.3 |
| T031 | Restyle generation result cards (masonry grid) | `ProjectFeature/AssetPreviewView.swift` | C4-004.7.4 |
| T032 | Restyle CreditView transactions | `CreditFeature/CreditView.swift` | C4-004.7.5 |

### Phase 8 — US6: Floating Credit Pill & Micro-Interactions

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T033 | CreditPill floating overlay component | `DesignKit/Components/CreditPill.swift` | C4-004.8.1 |
| T034 | MechanicalCounter animation | `DesignKit/Components/MechanicalCounter.swift` | C4-004.8.2 |
| T035 | CompletionToast banner | `DesignKit/Components/CompletionToast.swift` | C4-004.8.3 |
| T036 | Wire CreditPill into root navigation | `C4App.swift` | C4-004.8.4 |
| T037 | Wire CompletionToast into generate flow | `GenerateFeature/ImageGenerateReducer.swift`, `VideoGenerateReducer.swift` | C4-004.8.5 |

### Phase 9 — US7: Content-Adaptive Accent Color

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T038 | AdaptiveColorEngine | `DesignKit/Theme/AdaptiveColorEngine.swift` | C4-004.9.1 |
| T039 | Settings toggle UI ("Adaptive Color") | Settings view | C4-004.9.2 |
| T040 | Wire AdaptiveColorEngine into SynthesisTheme | `DesignKit/Theme/SynthesisTheme.swift` | C4-004.9.3 |

### Phase 10 — US8: Command Palette

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T041 | CommandPaletteView | `DesignKit/Components/CommandPaletteView.swift` | C4-004.10.1 |
| T042 | Searchable entity index + fuzzy search | `DesignKit/Components/CommandPaletteIndex.swift` | C4-004.10.2 |
| T043 | Double-tap status bar trigger + navigation | `C4App.swift` | C4-004.10.3 |

### Phase 11 — US9: Activity-Responsive Opacity

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T044 | ActivityMode TCA enum | `GenerateFeature/` | C4-004.11.1 |
| T045 | ActivityResponder ViewModifier | `DesignKit/Modifiers/ActivityResponder.swift` | C4-004.11.2 |
| T046 | Apply ActivityResponder to generate views | `GenerateFeature/` | C4-004.11.3 |

### Phase 12 — Accessibility & Polish

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T047 | Reduce Motion fallbacks | All DesignKit components | C4-004.12.1 |
| T048 | Reduce Transparency fallbacks | CreditPill, ContextualToolbar, StickyCtaOverlay | C4-004.12.2 |
| T049 | Dynamic Type XXXL testing + layout wrapping | All feature views | C4-004.12.3 |
| T050 | VoiceOver semantic grouping | All custom components | C4-004.12.4 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Setup | 2 | 1 | C4-004.1 |
| 2: Foundational | 4 | 1 | C4-004.2 |
| 3: US1 — Creative Stage (MVP) | 6 | 1 | C4-004.3 |
| 4: US2 — Navigation & Studio | 5 | 1 | C4-004.4 |
| 5: US3 — Sticky CTA | 4 | 1 | C4-004.5 |
| 6: US4 — Panel Selectors | 6 | 1 | C4-004.6 |
| 7: US5 — Cards | 5 | 2 | C4-004.7 |
| 8: US6 — Credit Pill & Micro | 5 | 2 | C4-004.8 |
| 9: US7 — Adaptive Color (P2) | 3 | 3 | C4-004.9 |
| 10: US8 — Command Palette (P2) | 3 | 3 | C4-004.10 |
| 11: US9 — Activity Opacity (P2) | 3 | 3 | C4-004.11 |
| 12: Accessibility | 4 | 2 | C4-004.12 |
| **Total** | **50** | | |

## Dependency Graph

```
Phase 1: Setup (C4-004.1)
    |
Phase 2: Foundational (C4-004.2) ──blocks──> All user stories
    |
    ├── Phase 3: US1 Creative Stage (C4-004.3, MVP) ──blocks──> US3, US4
    ├── Phase 4: US2 Navigation & Studio (C4-004.4)     [parallel with US1]
    ├── Phase 7: US5 Cards (C4-004.7)                   [parallel with US1]
    └── Phase 8: US6 Credit Pill (C4-004.8)              [parallel with US1]
         |
         ├── Phase 5: US3 Sticky CTA (C4-004.5)         [after US1]
         └── Phase 6: US4 Panel Selectors (C4-004.6)    [after US1]
              |
    ┌─────────┴──────────────────────────────┐
    Phase 9: US7 Adaptive Color (C4-004.9)   |  [Phase 2, parallel]
    Phase 10: US8 Command Palette (C4-004.10) |  [Phase 2, parallel]
    Phase 11: US9 Activity Opacity (C4-004.11)|  [Phase 2, parallel]
    └────────────────────────────────────────┘
              |
    Phase 12: Accessibility (C4-004.12)  [after all Phase 1 stories]
```

## Improvements

Improvements (Level 4: C4-004.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered.
