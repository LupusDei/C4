# Tasks: iOS Re-Skin — Synthesis

**Input**: Design documents from `/specs/005-ios-reskin-synthesis/` and `/specs/004-ios-reskin-proposals/proposal-d-synthesis.md`
**Epic**: `C4-004`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-004.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1-US10)

## Phase 1: Setup

**Purpose**: Create DesignKit SPM package scaffold and wire dependencies

- [ ] T001 Create DesignKit SPM package with Package.swift, source directories, and placeholder module in `ios/C4/Packages/DesignKit/`
- [ ] T002 Add DesignKit as dependency to all feature packages (GenerateFeature, ProjectFeature, StoryboardFeature, CreditFeature, PromptFeature, AssemblyFeature) and app target in `ios/C4.xcodeproj/project.pbxproj`

---

## Phase 2: Foundational

**Purpose**: Theme system and core reusable components — blocks all user stories

- [ ] T003 [US1] Create SynthesisTheme with ThemeColors (light/dark palettes, configurable accent default #C2410C), ThemeTypography (New York serif headings, SF Pro body, SF Mono numerical), ThemeSpacing in `ios/C4/Packages/DesignKit/Sources/DesignKit/Theme/`
- [ ] T004 [P] [US1] Create ThemeButton component with three tiers (primary: full-width accent fill 56pt; contextual: glass capsule 36pt; quiet: text-only) with haptic + press animation in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/ThemeButton.swift`
- [ ] T005 [P] [US1] Create ThemeCard component with warm shadow system (light: rgba(120,90,50,0.08), press deepens to 0.15), configurable accent border, cornerRadius 16 in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/ThemeCard.swift`
- [ ] T006 [P] [US1] Create CollapsibleSection component with smooth height animation, disclosure triangle, one-line summary when collapsed in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CollapsibleSection.swift`

**Checkpoint**: Foundation ready — user stories can begin

---

## Phase 3: US1 — Creative Stage Prompt Input (Priority: P1, MVP)

**Goal**: Replace all TextEditor instances with the two-state Creative Stage input
**Independent Test**: Tap collapsed bar → expands to manuscript card with drag-to-resize → type text → auto-grows → swipe down → collapses preserving text

- [ ] T007 [US2] Create CreativeStageTextField UIViewRepresentable wrapping UITextView with intrinsicContentSize tracking, delegate-based height updates, and placeholder text cycling in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CreativeStageTextField.swift`
- [ ] T008 [US2] Create CreativeStageView with two-state expand/collapse: collapsed 48pt card bar with style pill + generate arrow, expanded manuscript card with dim overlay (0.5 opacity spring animation) in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CreativeStageView.swift`
- [ ] T009 [US2] Add drag-to-resize handle to CreativeStageView with haptic detents at compact (100pt), medium (200pt), full (60% screen height). Persist preferred height per screen via @AppStorage in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CreativeStageView.swift`
- [ ] T010 [US2] Create ContextualToolbar component (Style/History/Enhance/Camera icon buttons with labels, frosted glass background, slides between card and keyboard) in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/ContextualToolbar.swift`
- [ ] T011 [US2] Integrate CreativeStageView into ImageGenerateView — replace TextEditor and scattered buttons with CreativeStage + ContextualToolbar in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`
- [ ] T012 [P] [US2] Integrate CreativeStageView into VideoGenerateView — same replacement as ImageGenerateView in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/VideoGenerateView.swift`

**Checkpoint**: US1 independently functional — prompt input transformed

---

## Phase 4: US2 — Navigation & Studio Dashboard (Priority: P1)

**Goal**: Add Studio home tab, redesign tab bar, add breadcrumb navigation
**Independent Test**: Launch app → Studio tab is default → see dashboard → navigate into project → see breadcrumbs

- [ ] T013 [P] [US3] Redesign TabView in C4App.swift: 4 tabs (Studio/Generate/Projects/Credits), larger 28pt icons, labels always visible, accent-colored dot indicator on active tab in `ios/C4App/C4App.swift` or `ios/C4/C4App.swift`
- [ ] T014 [US3] Create StudioReducer (TCA) — loads current project, recent generations, credit balance, last-edited items in `ios/C4/Packages/StudioFeature/Sources/StudioFeature/StudioReducer.swift` (new package)
- [ ] T015 [US3] Create StudioView — project spotlight hero card, recent generations horizontal carousel (ScrollView .horizontal), credit balance card, "Continue Where You Left Off" section, Quick Presets in `ios/C4/Packages/StudioFeature/Sources/StudioFeature/StudioView.swift`
- [ ] T016 [P] [US3] Create BreadcrumbView component — slim bar with tappable segments separated by "›", accent color on current segment in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/BreadcrumbView.swift`
- [ ] T017 [US3] Wire BreadcrumbView into ProjectDetailView and StoryboardTimelineView navigation in `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/ProjectDetailView.swift` and `ios/C4/Packages/StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift`

**Checkpoint**: US2 independently functional — navigation transformed

---

## Phase 5: US3 — Button Hierarchy & Sticky CTA (Priority: P1)

**Goal**: Generate button always visible, three-tier visual hierarchy
**Independent Test**: Scroll through settings on generate screen → button stays pinned at bottom

- [ ] T018 [US4] Create StickyCtaOverlay — ZStack bottom overlay with frosted glass extension, wraps ThemeButton primary tier. Includes loading state (progress description text + thin progress bar) in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/StickyCtaOverlay.swift`
- [ ] T019 [US4] Integrate StickyCtaOverlay into ImageGenerateView — replace current bottom button with sticky overlay, ensure it stays above scroll content in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`
- [ ] T020 [P] [US4] Integrate StickyCtaOverlay into VideoGenerateView in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/VideoGenerateView.swift`
- [ ] T021 [US4] Audit and apply three-tier button hierarchy across all views — ensure no screen has >1 primary CTA, secondary actions use Tier 2/3 in all feature packages

**Checkpoint**: US3 independently functional — button hierarchy enforced

---

## Phase 6: US4 — Prism Panel Selectors (Priority: P1)

**Goal**: Replace all .pickerStyle(.menu) with visual pill bar + fan-open panels
**Independent Test**: Tap aspect ratio pill → panel opens with visual ratio cards → select one → panel closes

- [ ] T022 [US5] Create PanelPicker generic component — horizontal pill bar showing current values, tap pill to fan-open panel above bar, matchedGeometryEffect transition, only one panel open at a time in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/PanelPicker.swift`
- [ ] T023 [US5] Create AspectRatioPanelView — proportional rectangle cards with labels (Square/Wide/Tall/Cinema), selected = accent border in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/Panels/AspectRatioPanelView.swift`
- [ ] T024 [P] [US5] Create QualityPanelView — three mini-cards (Standard/High/Ultra) with icons, descriptions, credit cost badges, selected = accent left border in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/Panels/QualityPanelView.swift`
- [ ] T025 [P] [US5] Create ProviderPanelView — logo cards with provider name + "recommended" badge, selected = accent underline in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/Panels/ProviderPanelView.swift`
- [ ] T026 [P] [US5] Create DurationStepperView — custom stepper [ - ] 5.0s [ + ] with SF Mono centered value, accent buttons, haptic on step in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/Panels/DurationStepperView.swift`
- [ ] T027 [US5] Integrate all panels into ImageGenerateView and VideoGenerateView — replace all .pickerStyle(.menu) Pickers with PanelPicker + specific panel views in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift` and `VideoGenerateView.swift`

**Checkpoint**: US4 independently functional — selectors transformed

---

## Phase 7: US5 — Card System & Visual Polish (Priority: P2)

**Goal**: Restyle all card-based views with editorial aesthetic
**Independent Test**: Project cards show New York serif titles + warm shadows. Scene cards 300pt with film-frame. Generation results in masonry grid.

- [ ] T028 [P] [US6] Restyle ProjectListView cards — white ThemeCard, 3:4 hero image (8pt corner radius), New York serif title below, warm shadow deepens on press in `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/ProjectListView.swift`
- [ ] T029 [P] [US6] Restyle SceneCardView — 300pt width, thin dark border (film-frame), scene number in serif type, narration in New York Italic, visual prompt in regular weight in `ios/C4/Packages/StoryboardFeature/Sources/StoryboardFeature/SceneCardView.swift`
- [ ] T030 [P] [US6] Add accent-colored connector lines between scene cards in StoryboardTimelineView and dashed "Add Scene" card at end in `ios/C4/Packages/StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift`
- [ ] T031 [P] [US6] Restyle generation result cards — masonry grid (2 columns, 12pt gutters), fade-up + scale entrance animation (0.95→1.0, spring) in `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/AssetPreviewView.swift` or relevant view
- [ ] T032 [US6] Restyle CreditView transactions — clean table with hairline separators, sage green positive / warm gray negative amounts, SF Mono numbers in `ios/C4/Packages/CreditFeature/Sources/CreditFeature/CreditView.swift`

**Checkpoint**: US5 independently functional — all cards restyled

---

## Phase 8: US6 — Floating Credit Pill & Micro-Interactions (Priority: P2)

**Goal**: Persistent credit indicator + delightful micro-interactions
**Independent Test**: Credit pill visible in top-right on all screens. Spend credits → strike-through animation. Balance changes → mechanical counter roll.

- [ ] T033 [US7] Create CreditPill component — small translucent pill, shows balance, tappable to open credit detail, spend animation (expand + strike-through + contract) in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CreditPill.swift`
- [ ] T034 [US7] Create MechanicalCounter animation component — individual digit roll animation using interpolatingSpring in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/MechanicalCounter.swift`
- [ ] T035 [US7] Create CompletionToast component — warm banner sliding from top with thumbnail + "View" button, auto-dismiss after 4s in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CompletionToast.swift`
- [ ] T036 [US7] Wire CreditPill into root navigation as persistent overlay on all screens. Connect to CreditReducer for real-time balance updates in `ios/C4App/C4App.swift` or `ios/C4/C4App.swift`
- [ ] T037 [US7] Wire CompletionToast into generate flow — trigger on generation completion in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/ImageGenerateReducer.swift` and `VideoGenerateReducer.swift`

**Checkpoint**: US6 independently functional — micro-interactions live

---

## Phase 9: US7 — Content-Adaptive Accent Color (Priority: P3, Phase 2)

**Goal**: Optional accent color that shifts based on content
**Independent Test**: Enable "Adaptive Color" → view warm-toned project → accent shifts to warm → navigate to cool project → accent morphs over 0.8s

- [ ] T038 [US8] Create AdaptiveColorEngine — CIAreaAverage extraction on background queue with 2s debounce, WCAG AA contrast check, fallback to configured default in `ios/C4/Packages/DesignKit/Sources/DesignKit/Theme/AdaptiveColorEngine.swift`
- [ ] T039 [US8] Add "Adaptive Color" toggle to Settings (default off), persisted via @AppStorage in appropriate settings view
- [ ] T040 [US8] Wire AdaptiveColorEngine into SynthesisTheme — when enabled, override accent color with extracted color, animate with 0.8s easeInOut morph in `ios/C4/Packages/DesignKit/Sources/DesignKit/Theme/SynthesisTheme.swift`

---

## Phase 10: US8 — Command Palette (Priority: P3, Phase 2)

**Goal**: Spotlight-style search accessible from any screen
**Independent Test**: Double-tap status bar → palette opens → type "gen" → fuzzy match shows Generate → select → navigates

- [ ] T041 [US9] Create CommandPaletteView — full-screen overlay, search field, fuzzy matching with accent-highlighted match characters, recent actions list in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CommandPaletteView.swift`
- [ ] T042 [US9] Create searchable index of all app entities (projects, prompts, styles, generations, settings actions) with fuzzy search algorithm in `ios/C4/Packages/DesignKit/Sources/DesignKit/Components/CommandPaletteIndex.swift`
- [ ] T043 [US9] Wire double-tap status bar gesture trigger and navigation handling in app root in `ios/C4App/C4App.swift`

---

## Phase 11: US9 — Activity-Responsive Opacity (Priority: P3, Phase 2)

**Goal**: UI elements fade based on creative activity
**Independent Test**: Focus prompt → non-essential UI fades to 50%. Start generation → other elements at 70% with pulse on generating card.

- [ ] T044 [US10] Create ActivityMode enum (idle/composing/generating/reviewing) in TCA shared state, update on prompt focus, generation start/complete in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/`
- [ ] T045 [US10] Create ActivityResponder ViewModifier — reads ActivityMode from environment, adjusts view opacity with 0.4s easeInOut transition in `ios/C4/Packages/DesignKit/Sources/DesignKit/Modifiers/ActivityResponder.swift`
- [ ] T046 [US10] Apply ActivityResponder to non-essential elements in ImageGenerateView and VideoGenerateView in `ios/C4/Packages/GenerateFeature/Sources/GenerateFeature/`

---

## Phase 12: Accessibility & Polish

**Purpose**: Cross-cutting accessibility verification and fixes

- [ ] T047 [P] Implement Reduce Motion fallbacks — wrap all spring/bounce animations in `withAnimation(UIAccessibility.isReduceMotionEnabled ? .easeOut(duration: 0.2) : .spring(...))` across all DesignKit components
- [ ] T048 [P] Implement Reduce Transparency fallbacks — replace .ultraThinMaterial with solid fills when reduceTransparency is enabled in CreditPill, ContextualToolbar, StickyCtaOverlay
- [ ] T049 [P] Dynamic Type XXXL testing — verify all text scales, horizontal layouts wrap to vertical at accessibility sizes, no text clipping in all feature views
- [ ] T050 Add VoiceOver semantic grouping — accessibilityLabel/Hint/Value for all custom components (CreativeStageView, PanelPicker, CreditPill, ThemeCard, SceneCardView) across DesignKit and feature packages

---

## Dependencies

- Setup (Phase 1) → Foundational (Phase 2) → blocks all user stories
- US1 (Phase 3) and US2 (Phase 4) can run in parallel after Foundational
- US3 (Phase 5) depends on US1 (touches same generate views)
- US4 (Phase 6) depends on US1 (touches same generate views)
- US5 (Phase 7) can run in parallel with US1-US4 (different feature packages)
- US6 (Phase 8) depends on Foundational only
- US7, US8, US9 (Phases 9-11) are Phase 2 — depend on Phase 1 completion
- Accessibility (Phase 12) depends on all Phase 1 stories

## Parallel Opportunities

- Tasks marked [P] within a phase can run simultaneously
- After Foundational: US1 + US2 + US5 can run in parallel (different files)
- After US1: US3 + US4 must be sequenced or tightly coordinated (same generate views)
- Phase 2 stories (US7-US9) are independent of each other
- Accessibility tasks are all [P]
