# Proposal D: Synthesis — The Best of All Worlds

**Type**: Product / UI-UX Re-Skin
**Author**: Nick (synthesized from Nova's Aurora, Atelier, and Prism proposals)
**Date**: 2026-03-12
**Project**: C4 iOS App

---

## Design Philosophy

Synthesis takes the strongest elements from all three proposals and assembles them into a cohesive, phased design that ships fast and evolves over time. The foundation is Atelier's warm editorial confidence — a design that immediately feels premium and professional. Layered on top are Aurora's best interaction patterns and Prism's most innovative features, introduced as Phase 2 enhancements once the foundation is solid.

**Mood**: Warm, confident, and alive. A world-class creative studio that subtly responds to your work.

**Core principle**: Ship taste fast. Add magic later.

---

## Current Problems Addressed

| Problem | Current State | Synthesis Fix |
|---------|--------------|---------------|
| Bland visual identity | Stock `.accentColor` blue, `.quaternary` backgrounds, default SF Symbols | New York serif headings + configurable accent color (default: deep terracotta) + SF Symbols with hierarchical rendering |
| Button placement | Primary CTAs at bottom of scrollable VStack forms, pushed off-screen | Sticky CTA pinned to safe area bottom with frosted glass extension. ONE primary button per screen. Three-tier visual hierarchy |
| Option selectors | Every picker uses `.pickerStyle(.menu)` — identical, requires multiple taps | Settings pill bar showing current config at a glance. Tap any pill to fan-open a panel with all options. One panel open at a time |
| Text input expansion | TextEditor with fixed `minHeight` inside ScrollView — unpredictable sizing | Two-state "Creative Stage" input: collapsed 48pt chat bar ↔ expanded creative canvas with drag-to-resize + haptic detents |
| No design system | Inline styles per-view, copy-pasted patterns | Shared `DesignKit/` package (sibling to CoreKit) with theme, typography, components |

---

## Phased Delivery

### Phase 1: Foundation (2-3 weeks)
Ship the core design system, typography, navigation, prompt input, button hierarchy, and option selectors. This alone transforms the app from "bland default SwiftUI" to "premium creative tool."

### Phase 2: Intelligence (1-2 weeks)
Add content-adaptive accent color, Command Palette, and activity-responsive opacity adjustments. These features layer on top of the Phase 1 foundation without requiring architectural changes.

**Total: 3-5 weeks** — faster than Prism alone, more innovative than Atelier alone.

---

## Color System

### Phase 1 Colors (Atelier foundation)

```
Light Mode:
Background:       #FAF8F5  (warm off-white, paper-like, never sterile)
Surface Cards:    #FFFFFF  with warm shadow rgba(120, 90, 50, 0.08)
Primary Accent:   Configurable — default #C2410C (deep terracotta)
Secondary:        #65A30D  (sage green — success states)
Tertiary:         #1E3A5F  (deep navy — information states)
Text Primary:     #292524  (charcoal — never pure black)
Text Secondary:   #78716C  (warm gray)
Borders:          #E7E5E4  (1px, cornerRadius: 16)
Error:            #DC2626  (warm red)

Dark Mode:
Background:       #1C1917  (rich espresso)
Surface:          #292524  (dark warm gray)
Text Primary:     #FAF8F5  (cream-on-dark)
Text Secondary:   #A8A29E  (warm gray)
Accent:           Persists from light mode — brand anchor
```

### Phase 2 Enhancement: Content-Adaptive Accent
When the user is viewing content (project with images, generation results), the accent color can optionally shift to a color extracted from their content:
- `CIAreaAverage` + Apple's palette extraction for dominant vibrant color
- WCAG AA contrast check against current background
- 0.8s ease color morph when navigating between projects
- Fallback: configured accent color (terracotta default)
- User toggle in Settings: "Adaptive Color" on/off — some users will love it, some will prefer consistency

---

## Typography (from Atelier)

| Role | Font | Size | Notes |
|------|------|------|-------|
| Display/Headings | New York (serif) Bold | varies | Editorial gravitas — "Generate Image" becomes a statement |
| Body | SF Pro Text Regular | 15pt | Clean and functional for UI chrome |
| Prompt Text | New York Regular | 17pt | 1.5 line height — prompts feel like manuscript text |
| Captions/Labels | SF Pro Text Medium | 12pt | Warm gray — metadata recedes gracefully |
| Numerical Data | SF Mono Light | varies | Credits, durations, dimensions — technical precision (from Prism) |
| Large Display | SF Pro Display Thin | 48pt | Credit balance, generation count — dramatic and modern (from Prism) |

The serif/sans-serif pairing creates a clear hierarchy: **New York for creative content, SF Pro for interface controls, SF Mono for data**. This three-font system helps users intuitively distinguish "my work" from "app chrome" from "numbers."

---

## Iconography

SF Symbols with **`.symbolRenderingMode(.hierarchical)`** using accent color hierarchy (from Prism — avoids the custom icon maintenance burden of Aurora while still feeling premium):
- `.symbolEffect(.pulse)` on active generation indicators
- `.symbolEffect(.bounce)` on completion
- Tab bar: animated SF Symbols that morph between states
- Default: warm gray. Active: accent color

---

## Navigation — Tabs + Studio + Command Palette

### Bottom Tabs (Phase 1 — from Atelier)
Keep bottom tabs but redesign:
- Four tabs: **Studio** (home) | **Generate** | **Projects** | **Credits**
- Larger 28pt icons with labels always visible
- Active tab: accent-colored dot indicator below icon
- Familiar iOS pattern — zero learning curve for new users

### Studio Tab (Phase 1 — from Atelier)
A personal creative dashboard — the app's "home":
- **Current Project Spotlight**: Hero card of active project with quick actions
- **Recent Generations**: Horizontal carousel of latest 10 generations
- **Credit Balance**: Warm card with balance, last transaction, "Add Credits" button
- **Continue Where You Left Off**: Smart section showing last-edited storyboard, draft prompt
- **Quick Presets**: Three one-tap generation shortcuts (from Aurora):
  - Quick Draft (low quality, fast, cheap)
  - Standard (balanced)
  - Max Quality (highest settings)

### Breadcrumb Navigation (Phase 1 — from Atelier)
Within project views, a slim breadcrumb bar:
```
Projects  ›  My Film  ›  Storyboard  ›  Scene 3
```
Each segment tappable. Always know where you are.

### Floating Credit Pill (Phase 1 — from Prism)
Small translucent pill in top-right corner:
- Shows credit balance
- Tap opens credit detail sheet
- On spend: pill briefly expands, shows "-5" with strike-through animation, contracts to new balance

### Command Palette (Phase 2 — from Prism)
Double-tap status bar reveals Spotlight-style search:
- Search across projects, prompts, styles, generations, settings
- Every action reachable in 2 keystrokes
- Fuzzy matching with accent-colored highlights
- Recent actions shown by default

---

## Prompt Input — "Creative Stage" (Aurora's interaction + Atelier's aesthetics)

The best prompt input combines Aurora's two-state model (clearest interaction pattern) with Atelier's warm editorial aesthetics and manuscript feel.

### Collapsed State (Phase 1)
Slim 48pt card bar at screen bottom (chat-input metaphor):
- Warm shadow, accent-colored left border (2pt)
- Left side: style pill showing current style (tappable)
- Right side: generate arrow button
- Placeholder text cycles through inspiring suggestions with crossfade (from Prism)

### Expanded State (Phase 1 — tap to activate)
1. Background dims (0.5 opacity, spring animation)
2. Text area expands upward as a **Manuscript Card** (white card with warm shadow)
3. **Drag-to-resize handle** at bottom with haptic detents at three heights (from Atelier):
   - Compact (100pt) — quick edits
   - Medium (200pt) — default working height
   - Full (60% screen) — deep writing mode
4. Word count pill in bottom-right corner, updates live
5. Below the card: contextual toolbar (from Prism)

### Contextual Toolbar (Phase 1)
Slides in between manuscript card and keyboard when prompt is focused:
```
[Style]  [History]  [Enhance]  [Camera]
```
Icon buttons with labels, frosted glass background. Consolidates the currently scattered buttons.

### Auto-Resize Engine
```swift
// UIViewRepresentable wrapping UITextView
// Tracks intrinsicContentSize changes via delegate
// Grows line-by-line with spring animation within current detent
// User can drag handle to override height
// Each new line: UIImpactFeedbackGenerator(.light)
// System remembers preferred height per screen
```

### Enhanced Prompt Display (from Atelier)
After enhancement, editorial markup style:
- Original text shows in muted strikethrough above
- Enhanced text in bold New York serif below
- "Revert" link to go back
- Clear visual diff of what changed

### Style Tag (from Atelier)
Selected style appears as a small tag pinned to top-right corner of manuscript card.

### Dismiss
- Swipe down on the card, or tap the dimmed background
- Card collapses back to slim bar with spring animation
- All entered text preserved

---

## Button Placement — Three-Tier Gravitational Hierarchy (from Atelier + Aurora)

### Tier 1: Primary CTA (ONE per screen. Ever.)
- Full-width, 56pt height, pinned 16pt above safe area bottom
- Accent-colored fill (solid in Phase 1; content-adaptive gradient in Phase 2)
- New York Bold white text
- Frosted glass extension behind it to screen edge (from Aurora)
- Pressed state: darken 10%, scale 0.98, medium haptic impact
- Loading state: text becomes progress description, thin progress bar at top of button

### Tier 2: Contextual Actions (2-4 per screen)
- Frosted glass capsule buttons or icon-only toolbar strip
- Accent-colored text on glass background
- 36pt height / touch targets
- Labels appear on long-press (tooltip style)

### Tier 3: Quiet Actions (unlimited)
- Text-only in charcoal. No background, semibold weight
- "Clear", "Reset", "More Options"
- Visible but never distracting
- Destructive: warm red text-only, tucked in context menus or swipe actions

---

## Option Selectors — Prism Panels with Atelier Aesthetics

### Settings Pill Bar (Phase 1 — from Prism)
Single horizontal strip below prompt area showing current config as small pills:
```
[16:9]  [High]  [1080p]  [Flux]
```
Each pill is tappable. Warm card aesthetic, accent-colored text on selected pill.

### Panel Expansion (Phase 1 — from Prism)
Tapping a pill **fans open a panel** above the bar:
- Warm white card with shadow (Atelier aesthetic, not glass)
- Shows all options for that setting
- Only one panel open at a time
- Tap outside or same pill to collapse
- Panel folds back into pill with satisfying spring animation

### Aspect Ratio Panel
Visual ratio cards showing **actual proportions** as colored rectangles (shared across all three proposals):
```
 ┌──┐   ┌──────┐   ┌──┐   ┌────────────┐
 │  │   │      │   │  │   │            │
 │  │   │ Wide │   │  │   │  Cinema    │
 │Sq│   │      │   │Ta│   │            │
 │  │   └──────┘   │ll│   └────────────┘
 └──┘              │  │
                   └──┘
```
Labels below each. Selected = accent border.

### Quality Panel
Three mini-cards with credit cost badges (shared concept):
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ ⚡ Standard  │  │ ⚖️  High     │  │ 👑 Ultra    │
│             │  │             │  │             │
│ Fast, lower │  │ Balanced    │  │ Maximum     │
│ detail      │  │ quality     │  │ detail      │
│        2 cr │  │        5 cr │  │       12 cr │
└─────────────┘  └─────────────┘  └─────────────┘
```
Selected card: accent left border accent (bookmark style from Atelier).

### Provider Panel
Logo cards with provider name + "recommended" badge on best option for selected quality (from Prism). Selected = accent underline.

### Duration Panel (Video)
Custom stepper with large centered value in SF Mono: `[ - ]  5.0s  [ + ]`
Haptic feedback on each step. Accent color on stepper buttons.

### Mode Toggle (Text-to-Video vs Image-to-Video)
Full-width segmented control with smooth sliding indicator animation. Not the stock iOS segmented style. Spring physics on indicator movement.

---

## Card System — Paper and Shadow (Atelier) with Smart Touches

### Project Cards
- White card on warm background
- 3:4 hero image with 8pt corner radius (editorial feel)
- Title below image in New York serif
- Warm shadow that deepens on press (2→6 radius)
- No border — shadow alone creates depth

### Scene Cards (Storyboard Timeline)
- Horizontal scroll, **300pt width** for readability
- Film-frame aesthetic with thin border
- Scene number in serif type, top-left
- Narration in New York Italic, visual prompt in regular weight
- Connected by thin accent-colored lines between cards
- **"Add Scene"**: Dashed-border empty card at end — "Tap to create"

### Generation Result Cards
- Masonry grid (2 columns), 12pt gutters
- Full-bleed image, no padding
- Metadata bar at bottom on glass overlay (tap to reveal)
- New results enter with fade-up + slight scale animation (0.95→1.0)

### Credit Transactions
- Clean table layout with hairline separators
- Positive credits: sage green text
- Negative credits: warm gray text
- Mechanical counter animation on balance change (from Atelier)

---

## Phase 2 Enhancements

### Content-Adaptive Accent Color (from Prism)
- Toggle in Settings: "Adaptive Color" (default: off)
- When enabled, accent color shifts based on content being viewed
- `CIAreaAverage` + vibrant palette extraction on background queue with 2s debounce
- WCAG AA contrast check with fallback to configured default
- 0.8s ease color morph on navigation transitions
- The entire UI breathes a new personality for each creative context

### Activity-Responsive Opacity (from Prism, simplified)
Lighter-weight version of Prism's full adaptive layout — no layout changes, only opacity:
- **Composing** (prompt focused): non-essential UI elements fade to 50% opacity. Prompt + tools dominate.
- **Generating**: subtle pulse on generating card. Other elements at 70% opacity.
- **Reviewing**: result card has visual emphasis via increased shadow/scale.
- Implemented via TCA state-driven `ActivityMode` enum modifying opacity only (not spacing or layout).

### Command Palette (from Prism)
- Double-tap status bar to invoke
- Full-screen overlay with fuzzy search
- Searches: projects, prompts, styles, generations, settings
- Recent actions shown by default
- Accent-colored match highlights

---

## Micro-Interactions and Delight

| Moment | Animation | Source |
|--------|-----------|--------|
| Generation starts | Progress bar with organic leading edge + medium haptic | Atelier |
| Generation completes | Warm banner slides from top with thumbnail + "View" button + success haptic | Atelier |
| Credit spend | Mechanical counter — digits roll individually | Atelier |
| Credit pill update | Pill briefly expands, shows deduction with strike-through, contracts | Prism |
| Card entrance | Paper-sliding-onto-desk ease-out with slight bounce | Atelier |
| Pull to refresh | Simple pull-down with standard iOS spinner (skip custom animation — rarely noticed) | Simplified |
| Empty state | Hand-drawn illustration + warm copy: "Your studio is empty. Every masterpiece starts with a blank canvas." | Atelier |
| Error | Gentle shake + warm red flash on affected element | Atelier |
| Style selected | Chip pulses once with accent glow | Aurora |
| Quick Preset tap | Cards briefly glow with accent border, settings animate to new values | New |

---

## Accessibility

- All custom components: `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`
- All interactive elements meet **4.5:1 contrast ratio** on warm backgrounds
- Custom accent-colored focus indicators (2pt outlines)
- **Reduce Motion**: All spring animations → simple opacity crossfades. No parallax.
- **Reduce Transparency**: Glass materials → solid fills matching underlying color
- **Dynamic Type**: All text scales through XXXL. Horizontal layouts wrap to vertical at accessibility sizes. Cards become list rows.
- **VoiceOver**: Cards announce as single semantic units with rotor actions for context menu items
- **Switch Control**: All custom gestures have button-based alternatives
- **Haptic Language**:
  - Selection: light impact
  - Generation start: medium impact
  - Completion: success notification
  - Credit spend: soft impact
  - Drag handle detent: rigid impact

---

## Technical Implementation

### New Package: `DesignKit/` (sibling to CoreKit, not nested)
Located at `ios/C4/Packages/DesignKit/`:

**Phase 1 Components:**
- `SynthesisTheme` — `ThemeColors`, `ThemeTypography`, `ThemeSpacing` with configurable accent
- `CreativeStageTextField` — UIViewRepresentable with two-state expand/collapse, drag-to-resize handle, haptic detents, intrinsicContentSize tracking
- `ThemeButton` — three tiers (primary/contextual/quiet) with haptic + press animation
- `PanelPicker<T>` — generic pill bar with fan-open panel expansion (from Prism's Prism Panels)
- `ThemeCard` — base card component with warm shadow system + configurable accent border
- `CollapsibleSection` — smooth height animation for settings panels
- `CreditPill` — floating balance indicator with spend animation

**Phase 2 Components:**
- `AdaptiveColorEngine` — extracts dominant colors from images, adjusts for contrast, manages transitions
- `CommandPaletteView` — full-screen overlay with fuzzy search
- `ActivityResponder` — ViewModifier that adjusts opacity based on TCA ActivityMode state

### Animation Standard
```swift
// Default movement
Animation.easeOut(duration: 0.25)

// Scale/press effects
Animation.spring(response: 0.4, dampingFraction: 0.8)

// Card entrance
Animation.spring(response: 0.5, dampingFraction: 0.8).delay(index * 0.05)

// Counter roll (credit balance)
Animation.interpolatingSpring(stiffness: 120, damping: 15)

// Phase 2: color morph
Animation.easeInOut(duration: 0.8)
```

### Color Mode
- Light mode is the **default** experience (warm, editorial, paper-like)
- Dark mode: rich espresso backgrounds, cream text, accent color persists
- Controlled via `@Environment(\.colorScheme)`
- Phase 2: content-adaptive color works in both modes

---

## What Was Deliberately Excluded

| Excluded Element | Source | Why |
|-----------------|--------|-----|
| Custom thin-line icon set | Aurora | SF Symbols with hierarchical rendering achieves 80% of the effect with 20% of the effort and zero maintenance burden |
| Animated cycling gradient accent | Aurora | High risk of "gaming PC RGB" aesthetic. Content-adaptive color (Phase 2) is a more tasteful version of the same idea |
| Kill TabView entirely | Aurora | Too high risk for discoverability. Studio tab achieves the "home canvas" vision within familiar iOS patterns |
| Masonry grid home mixing projects + generations | Aurora | Chaotic. Studio tab provides a curated home without mixing content types |
| Lottie empty state animations | Aurora | Adds dependency for rarely-seen states. Static illustrations are sufficient |
| Zoomable Spatial Canvas navigation | Prism | Too experimental. Horizontal paged scroll with parallax confuses users expecting tabs |
| Full activity-responsive layout changes | Prism | Cross-cutting concern touching every component. Simplified to opacity-only adjustments |
| Notebook paper ruled lines | Atelier | Gimmicky. Clean manuscript card is better |
| Custom pull-to-refresh illustrations | Atelier | Implementation cost for a rarely-noticed interaction |

---

## Impact Assessment

| Dimension | Phase 1 | Phase 1+2 |
|-----------|---------|-----------|
| **Effort** | 2-3 weeks | 3-5 weeks |
| **Risk** | Low | Medium (adaptive color needs testing) |
| **Delight** | High | Very High |
| **Differentiation** | High (typography + editorial feel) | Very High (content-adaptive color is a standout) |
| **Accessibility** | Very Good | Very Good |
| **Ship Confidence** | Very High | High |

---

## Summary

Synthesis delivers the **best ideas from all three proposals** in a pragmatic, phased approach:

- **From Atelier**: Typography system, warm color palette, three-tier button hierarchy, Studio tab, breadcrumb navigation, manuscript card aesthetics, editorial card system, mechanical counter animations
- **From Aurora**: Two-state prompt input interaction model, Quick Presets, sticky CTA with frosted glass extension, collapsible settings
- **From Prism**: Settings pill bar with fan-open panels, Command Palette, floating credit pill, content-adaptive accent color, activity-responsive opacity, SF Symbols with hierarchical rendering

Phase 1 alone is a transformative upgrade. Phase 2 adds the "show your friends" features that make C4 genuinely innovative.
