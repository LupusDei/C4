# Feature Specification: iOS Re-Skin — Synthesis

**Feature Branch**: `005-ios-reskin-synthesis`
**Created**: 2026-03-12
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - Design System Foundation (Priority: P1)

As a developer, I need a shared DesignKit package providing theme colors, typography, spacing, and reusable components so that all views use a consistent, premium design language instead of inline ad-hoc styles.

**Why this priority**: Every other story depends on these shared components existing.

**Independent Test**: Import DesignKit in any feature package. Verify ThemeColors, ThemeTypography, ThemeSpacing, and ThemeButton are accessible. Render a ThemeButton in a preview — confirm it shows New York Bold text, accent fill, correct sizing.

**Acceptance Scenarios**:

1. **Given** a new `DesignKit` SPM package, **When** imported by any feature package, **Then** it provides `SynthesisTheme`, `ThemeColors`, `ThemeTypography`, `ThemeSpacing` with configurable accent color (default terracotta #C2410C)
2. **Given** dark mode is active, **When** rendering any themed component, **Then** colors switch to espresso background (#1C1917), cream text (#FAF8F5), accent persists
3. **Given** `ThemeButton` rendered in primary tier, **When** user taps, **Then** it shows darken-10% + scale-0.98 press animation with medium haptic impact

---

### User Story 2 - Creative Stage Prompt Input (Priority: P1)

As a content creator, I need a prompt input that feels like a creative workspace — not a form field — with predictable resize behavior and quick access to style, history, enhance, and camera tools.

**Why this priority**: The prompt input is the core creative interaction. Current TextEditor is the biggest UX pain point.

**Independent Test**: Open Generate screen. Tap collapsed prompt bar — verify it expands to manuscript card with drag handle. Type multi-line text — verify auto-resize grows line-by-line. Drag handle to change height — verify haptic detents at compact/medium/full. Tap dimmed background — verify collapse preserves text.

**Acceptance Scenarios**:

1. **Given** the generate screen is shown, **When** user sees the prompt area, **Then** a slim 48pt card bar appears at the bottom with style pill (left) and generate arrow (right)
2. **Given** collapsed prompt bar, **When** user taps it, **Then** background dims (0.5 opacity, spring animation) and a manuscript card expands upward with 20pt padding
3. **Given** expanded manuscript card, **When** user types text exceeding the current height, **Then** card grows line-by-line with spring animation up to the current detent height, then scrolls internally
4. **Given** expanded manuscript card, **When** user drags the bottom handle, **Then** card resizes with haptic feedback at three detents (compact 100pt, medium 200pt, full 60%)
5. **Given** expanded manuscript card, **When** user taps dimmed background or swipes down, **Then** card collapses to slim bar preserving all text
6. **Given** prompt is focused, **When** keyboard appears, **Then** a contextual toolbar slides in between card and keyboard with [Style] [History] [Enhance] [Camera] buttons

---

### User Story 3 - Navigation & Studio Dashboard (Priority: P1)

As a content creator, I need a Studio home tab that shows my creative dashboard, redesigned tab bar with accent indicators, and breadcrumb navigation within projects so I always know where I am.

**Why this priority**: Navigation is the skeleton of the app experience. The Studio tab replaces the bland default landing.

**Independent Test**: Launch app — verify Studio tab is first/default. Verify it shows project spotlight, recent generations carousel, credit balance card. Navigate into a project — verify breadcrumb trail appears. Verify all four tabs have redesigned icons with accent dot indicators.

**Acceptance Scenarios**:

1. **Given** app launches, **When** user sees the tab bar, **Then** four tabs appear: Studio, Generate, Projects, Credits with 28pt icons, labels always visible, active tab has accent-colored dot indicator
2. **Given** Studio tab is active, **When** user views the dashboard, **Then** they see: current project spotlight hero card, recent generations horizontal carousel (up to 10), credit balance card with last transaction, and "Continue Where You Left Off" section
3. **Given** user is inside Project > Storyboard > Scene 3, **When** they look at the top of the screen, **Then** a breadcrumb bar shows: Projects > My Film > Storyboard > Scene 3, each segment tappable

---

### User Story 4 - Button Hierarchy & Sticky CTA (Priority: P1)

As a content creator, I need the Generate button to always be visible and the most prominent element on screen, with settings and secondary actions clearly subordinated.

**Why this priority**: Users currently lose the Generate button when scrolling through settings. The flat visual hierarchy makes the app feel unfocused.

**Independent Test**: Open Image Generate screen. Scroll down through all settings — verify Generate button stays pinned at bottom. Verify only ONE primary CTA on screen. Verify secondary actions (Enhance, Style, History) appear as capsule buttons or toolbar icons.

**Acceptance Scenarios**:

1. **Given** the generate screen, **When** user scrolls through settings, **Then** the primary CTA remains pinned 16pt above safe area bottom with frosted glass extension, never scrolling away
2. **Given** generation is in progress, **When** user watches the CTA, **Then** the button text changes to progress description and a thin progress bar appears at the top of the button
3. **Given** secondary actions exist, **When** user looks at the screen, **Then** they appear as Tier 2 frosted glass capsules (accent text, 36pt height) or Tier 3 text-only buttons, never competing with the primary CTA

---

### User Story 5 - Prism Panel Selectors (Priority: P1)

As a content creator, I need to see all my generation options at a glance in a settings pill bar, with each pill opening a visual panel showing all choices — not hidden behind identical dropdown menus.

**Why this priority**: Current `.pickerStyle(.menu)` pickers all look identical, hide options, and require multiple taps.

**Independent Test**: Open Image Generate screen. Verify settings pill bar shows current config as pills: [16:9] [High] [1080p] [Flux]. Tap [16:9] — verify aspect ratio panel fans open showing visual ratio rectangles. Tap [High] — verify quality panel shows three mini-cards with credit costs. Verify only one panel open at a time.

**Acceptance Scenarios**:

1. **Given** the generate screen below the prompt, **When** user sees the settings area, **Then** a horizontal pill bar displays current config: aspect ratio, quality, resolution, provider
2. **Given** the pill bar, **When** user taps [16:9], **Then** an aspect ratio panel fans open above the bar showing proportional rectangles with labels (Square, Wide, Tall, Cinema), selected option has accent border
3. **Given** the pill bar, **When** user taps [High], **Then** a quality panel opens showing three mini-cards (Standard/High/Ultra) with icons, descriptions, and credit cost badges
4. **Given** one panel is open, **When** user taps a different pill, **Then** the current panel collapses and the new one opens
5. **Given** an open panel, **When** user taps outside or the same pill, **Then** the panel folds back into the pill with spring animation

---

### User Story 6 - Card System & Visual Polish (Priority: P2)

As a content creator, I need project cards, scene cards, and generation result cards to feel premium — with editorial typography, warm shadows, and meaningful entrance animations.

**Why this priority**: Cards are the primary content containers. Upgrading them completes the visual transformation.

**Independent Test**: View Projects list — verify white cards with New York serif titles, warm shadows, 3:4 hero images. View Storyboard timeline — verify 300pt scene cards with film-frame aesthetic, accent connector lines. View generation results — verify masonry grid with fade-up entrance animation.

**Acceptance Scenarios**:

1. **Given** the Projects list, **When** user sees project cards, **Then** each is a white card with 3:4 hero image (8pt corner radius), New York serif title below, warm shadow that deepens on press
2. **Given** the Storyboard timeline, **When** user sees scene cards, **Then** each is 300pt wide with thin dark border (film-frame), scene number in serif type, narration in italics, connected by thin accent lines
3. **Given** generation results, **When** new cards appear, **Then** they enter with fade-up + scale animation (0.95→1.0, spring)

---

### User Story 7 - Floating Credit Pill & Micro-Interactions (Priority: P2)

As a content creator, I need a persistent credit balance indicator and delightful micro-interactions that make the app feel alive and responsive without being distracting.

**Why this priority**: Polish layer that elevates the experience from "functional" to "delightful."

**Independent Test**: Verify floating credit pill visible in top-right corner on all screens. Generate an image — verify pill shows "-5" strike-through animation. Verify credit balance uses mechanical counter animation. Verify generation completion shows warm banner toast.

**Acceptance Scenarios**:

1. **Given** any screen, **When** user looks at top-right corner, **Then** a small translucent pill shows credit balance, tappable to open credit detail
2. **Given** credits are spent, **When** deduction occurs, **Then** pill briefly expands, shows deduction with strike-through animation, contracts to new balance
3. **Given** credit balance changes, **When** the number updates, **Then** digits roll individually (mechanical counter animation)
4. **Given** generation completes, **When** result is ready, **Then** a warm banner slides from top with thumbnail + "View" button, auto-dismisses after 4s

---

### User Story 8 - Content-Adaptive Accent Color (Priority: P3)

As a content creator, I want the app's accent color to optionally shift based on my content, so the UI feels like it reflects my creative work.

**Why this priority**: Phase 2 feature — innovative but not essential for core experience.

**Independent Test**: Enable "Adaptive Color" in Settings. View a project with warm-toned images — verify UI accent shifts to warm color extracted from content. Navigate to a cool-toned project — verify accent morphs over 0.8s. Disable toggle — verify accent returns to configured default.

**Acceptance Scenarios**:

1. **Given** Settings screen, **When** user sees "Adaptive Color" toggle, **Then** it defaults to off
2. **Given** Adaptive Color is on, **When** user views content with a dominant warm palette, **Then** the UI accent color shifts to the extracted color (WCAG AA checked)
3. **Given** Adaptive Color is on, **When** navigating between projects, **Then** the accent morphs smoothly over 0.8s

---

### User Story 9 - Command Palette (Priority: P3)

As a power user, I want a Spotlight-style command palette so I can reach any action in 2 keystrokes without navigating through tabs.

**Why this priority**: Phase 2 power-user feature. Deepens engagement for advanced users.

**Independent Test**: Double-tap status bar — verify command palette appears. Type "gen" — verify fuzzy matches for Generate Image, Generate Video. Select an option — verify navigation to that screen.

**Acceptance Scenarios**:

1. **Given** any screen, **When** user double-taps status bar, **Then** a full-screen overlay appears with search field and recent actions
2. **Given** the palette is open, **When** user types a query, **Then** fuzzy matching returns results from projects, prompts, styles, generations, settings with accent-colored match highlights
3. **Given** results are shown, **When** user selects one, **Then** palette dismisses and navigates to the selected action/screen

---

### User Story 10 - Activity-Responsive Opacity (Priority: P3)

As a content creator, I want non-essential UI elements to fade when I'm focused on composing or generating, so the interface adapts to my creative flow.

**Why this priority**: Phase 2 polish that makes the UI feel intelligent.

**Independent Test**: Focus the prompt input — verify non-essential UI fades to 50% opacity. Start generation — verify other elements at 70% with subtle pulse on generating card. Exit focus — verify UI returns to full opacity.

**Acceptance Scenarios**:

1. **Given** prompt input is focused, **When** user is composing, **Then** non-essential elements fade to 50% opacity
2. **Given** generation is in progress, **When** waiting for result, **Then** other elements at 70% opacity, generating card has subtle pulse
3. **Given** activity ends, **When** user returns to browsing, **Then** all elements return to full opacity with 0.4s ease

---

### Edge Cases

- What happens when content-adaptive color extraction returns a low-contrast color? → Fallback to configured accent (terracotta default)
- What happens when user has Dynamic Type set to XXXL? → Horizontal chip/pill layouts wrap to vertical stacks
- What happens when Reduce Motion is enabled? → All spring animations become simple opacity fades, no parallax
- What happens when Reduce Transparency is enabled? → Glass materials replaced with solid fills
- What happens when prompt text is extremely long (1000+ characters)? → CreativeStageTextField scrolls internally after hitting max detent height
- What happens when there are no projects/generations for the Studio tab? → Hand-drawn empty state illustration with warm copy

## Requirements

### Functional Requirements

- **FR-001**: App MUST use New York serif for headings and creative content, SF Pro for UI chrome, SF Mono for numerical data
- **FR-002**: All screens MUST have exactly one Tier 1 (primary) CTA button
- **FR-003**: Primary CTA MUST be pinned to bottom safe area, never scrolling away
- **FR-004**: Prompt input MUST support two states: collapsed (48pt bar) and expanded (manuscript card with drag-to-resize)
- **FR-005**: Settings MUST be displayed as a pill bar with tap-to-expand panels
- **FR-006**: App MUST include Studio tab as default home with creative dashboard
- **FR-007**: All card components MUST use warm shadow system with press-to-deepen effect
- **FR-008**: Credit balance MUST be visible on all screens via floating pill
- **FR-009**: All views MUST use components from DesignKit package (no inline ad-hoc styles for themed elements)
- **FR-010**: Phase 2: Content-adaptive color MUST check WCAG AA contrast before applying

### Key Entities

- **SynthesisTheme**: Central theme configuration (colors, typography, spacing, accent)
- **CreativeStageTextField**: Two-state prompt input component
- **ThemeButton**: Three-tier button component (primary/contextual/quiet)
- **PanelPicker**: Settings pill bar with expandable option panels
- **ThemeCard**: Base card component with warm shadow system
- **CreditPill**: Floating credit balance indicator
- **AdaptiveColorEngine**: (Phase 2) Extracts dominant colors from content images

## Success Criteria

- **SC-001**: Zero inline color/font/spacing constants in feature views — all from DesignKit
- **SC-002**: Generate button always visible on Image and Video generate screens regardless of scroll position
- **SC-003**: Prompt input expand/collapse is smooth (no frame drops) on iPhone 13 and newer
- **SC-004**: All interactive elements meet 4.5:1 contrast ratio on both light and dark backgrounds
- **SC-005**: All animations respect Reduce Motion accessibility setting
- **SC-006**: Studio tab loads in under 1 second with cached data
