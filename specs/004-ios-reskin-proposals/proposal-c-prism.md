# Proposal C: Prism — Adaptive Kinetic Interface

**Type**: Product / UI-UX Re-Skin
**Author**: Nova
**Date**: 2026-03-11
**Project**: C4 iOS App

---

## Design Philosophy

Prism is built on one radical idea: **the interface should feel alive and respond to the creative energy flowing through it**. Inspired by refracted light, crystalline structures, and Apple's visionOS design language, Prism creates a UI that shifts, adapts, and transforms based on what the user is doing. Idle? The interface is calm and minimal. Generating? It pulses with anticipation. Viewing results? It opens up to celebrate the work.

**Mood**: Intelligent, alive, responsive. Think: an AI that anticipates your creative flow and shapes itself around it.

---

## Current Problems Addressed

| Problem | Current State | Prism Fix |
|---------|--------------|-----------|
| Bland visual identity | Static blue accent, one look for all states | Content-adaptive accent color extracted from user's images; UI literally reflects their work |
| Button placement | Flat visual hierarchy, all elements compete equally | Three-tier gravitational hierarchy: Attractor → Contextual → Quiet |
| Option selectors | Hidden behind `.menu` pickers | "Prism Panels" that fan out from a settings bar on tap |
| Text input expansion | Fixed heights, unpredictable behavior | "The Lens" — ambient bar that expands with intrinsicContentSize tracking, smart line-by-line growth |
| No design system | Scattered inline styles | `PrismTheme` with `AdaptiveColorEngine`, `GlassCard`, and activity-responsive layout system |

---

## The Defining Feature: Content-Adaptive Color

The accent color is **extracted from the user's content** in real-time:

```
User views warm sunset image    →  UI accent shifts to amber/coral
User works on noir storyboard   →  UI accent shifts to cool silver/blue
User has no content yet          →  Default: prismatic indigo-to-teal gradient
```

### How It Works
- `CIAreaAverage` filter extracts dominant color from the visible image/project thumbnail
- Color is adjusted for contrast (minimum WCAG AA against current background)
- Transition: 0.8s ease color morph when navigating between projects
- The entire UI breathes a new personality for each creative context

### Fallback
Default gradient: indigo (#6366F1) → teal (#14B8A6). Used when no content is present or when extracted color fails contrast check.

---

## Color System

```
Light Mode:
Background:       #F8FAFC  (cool white)
Surface Cards:    ultraThinMaterial with 0.5pt border of extracted accent at 20% opacity
Text Primary:     #0F172A  (deep slate)
Text Secondary:   #64748B  (medium slate)

Dark Mode:
Background:       #0F172A  (deep slate-navy)
Surface Cards:    ultraThinMaterial with 0.5pt border of extracted accent at 20% opacity
Text Primary:     #F1F5F9  (bright slate)
Text Secondary:   #94A3B8  (medium slate)

Semantic:
Success:          Emerald (slightly desaturated)
Warning:          Amber (slightly desaturated)
Error:            Rose (slightly desaturated)
```

---

## Typography

| Role | Font | Size | Notes |
|------|------|------|-------|
| Headings | SF Pro Display Medium | varies | Clean, modern, not heavy |
| Body | SF Pro Text Regular | 15pt | Standard excellence |
| Prompt Text | SF Pro Text | 16pt | -0.2pt letter spacing — slightly tighter, intentional |
| Numerical | SF Mono Light | varies | Credits, durations, dimensions — technical precision |
| Large Display | SF Pro Display Thin | 48pt | Credit balance, generation count — dramatic and modern |

---

## Iconography

- SF Symbols with **`.symbolRenderingMode(.hierarchical)`** — multi-layer icons using accent color hierarchy
- `.symbolEffect(.pulse)` on active generation indicators
- `.symbolEffect(.bounce)` on completion
- Tab bar: animated SF Symbols that **morph between states** (folder closed → open when viewing projects)

---

## Navigation — Fluid Context Switching

### Zoomable Spatial Canvas
Three "zones" arranged spatially:
```
┌──────────┐  ┌──────────────────┐  ┌──────────┐
│          │  │                  │  │          │
│ Projects │  │    Generate      │  │ Credits  │
│          │  │    (center,      │  │          │
│  (peek)  │  │     largest)     │  │  (peek)  │
│          │  │                  │  │          │
└──────────┘  └──────────────────┘  └──────────┘
```

On iPhone: horizontal paged scroll with peek previews of adjacent zones. Swiping uses **parallax depth** — current zone recedes while next zooms in.

### Command Palette
Double-tap status bar reveals a **Spotlight-style Command Palette**:
- Search across projects, prompts, styles, generations, settings
- Every action reachable in 2 keystrokes
- Fuzzy matching with accent-colored highlights on match characters
- Recent actions shown by default

### Context Persistence
Navigate away from Generate screen → come back → **exact state preserved**:
- Scroll position
- Expanded sections
- Typed prompt text
- Selected settings
- Animate back with matched geometry effect

### Floating Credit Pill
Small translucent pill always visible in top-right corner:
- Shows credit balance
- Tap opens credit detail sheet
- When credits spent: pill briefly expands, shows "-5" with strike-through animation, contracts to new balance

---

## Prompt Input — "The Lens"

### Ambient State
Single-line frosted glass bar at bottom of generate zone:
- Placeholder text **cycles through inspiring suggestions** with crossfade:
  - "A cathedral made of light..."
  - "Two dancers in zero gravity..."
  - "A forest that remembers..."
- Microphone icon on left, generate arrow on right

### Focus State
Tapping the bar triggers smooth expansion:
1. Bar grows upward (spring animation)
2. Background dims to 70% opacity
3. Text area becomes generous multi-line (40% of screen)
4. Content-adaptive accent color appears as **4pt left border** (blockquote style)
5. Keyboard rises

### Smart Resize
```swift
// UIViewRepresentable wrapping UITextView
// Tracks intrinsicContentSize changes via delegate
// Grows line-by-line with spring animation
// Caps at 40% screen height, then scrolls internally
// Each new line: UIImpactFeedbackGenerator(.light).impactOccurred()
```

### Contextual Toolbar
When prompt field is focused, toolbar slides in between prompt and keyboard:
```
[🎨 Style]  [📜 History]  [✨ Enhance]  [📷 Camera]
```
Icon buttons with labels, frosted glass background. Replaces the scattered buttons currently spread across the form.

### Rich Preview (Bonus)
As you type, if prompt contains recognizable style keywords ("cinematic", "watercolor"), small preview thumbnails float above the text as tappable pills → apply as style preset.

---

## Button Placement — Gravitational Hierarchy

### Tier 1: The Attractor (ONE per screen)
The most visually dominant element:
- Full-width, 56pt height
- Filled with content-adaptive gradient
- White text, SF Pro Display Semibold 17pt
- **Subtle constant animation**: gradient slowly shifts (Dynamic Island-style shimmer)
- Pinned to bottom safe area with frosted glass extension
- Loading state: gradient accelerates, text becomes progress description, thin progress bar at top of button

### Tier 2: Contextual Actions (2-4 per screen)
- Frosted glass capsule buttons
- `ultraThinMaterial` background, accent-colored text
- 36pt height
- Positioned in contextual toolbar or inline within settings cards

### Tier 3: Quiet Actions (unlimited)
- Text-only in secondary color
- "Clear", "Reset", "More Options"
- Visible but never distracting

---

## Option Selectors — "Prism Panels"

### The Settings Bar
Single horizontal strip below prompt area showing current config as small pills:
```
[16:9]  [High]  [1080p]  [Flux]
```
Each pill is tappable.

### Panel Expansion
Tapping a pill **fans open a panel** above the bar:
- Frosted glass card showing all options for that setting
- Only one panel open at a time
- Tap outside or same pill to collapse
- Panel folds back into the pill with satisfying collapse animation

### Aspect Ratio Panel
Live-proportioned rectangles in 2×3 grid with labels. Selected = animated prismatic border.

### Quality Panel
Three cards arranged horizontally with depth progression:
```
Shadow depth:  shallow → medium → deep
                 ↓         ↓        ↓
            Standard     High     Ultra
```
Visual metaphor: higher quality = more visual weight.

### Provider Panel
Logo cards with provider name + "recommended" badge on best option for selected quality.

### Duration Panel
Custom slider with **cost curve track** — track thickness varies to show where credits are consumed faster. Value label follows thumb with spring physics.

---

## Card System — Living Glass

### Project Cards
- 16:10 aspect ratio
- Glass card with full-bleed image
- Title and metadata float below image on glass surface
- **Scroll parallax**: subtle 3D rotation responding to scroll velocity
- Content-adaptive accent border (extracted from project's hero image)

### Scene Cards (Storyboard)
- Horizontal scroll with **snap-to-center** behavior
- Active (centered) card: full opacity, 1.05 scale
- Adjacent cards: 0.7 opacity, 0.95 scale
- Creates carousel/deck feel with depth
- Connected by translucent filmstrip between cards

### Generation Result Cards
**"Refraction" entrance animation**:
- Image starts as prismatic blur
- Sharpens into focus over 0.5s
- Like light resolving through a crystal
- Final state: clean image with glass metadata overlay

---

## Adaptive Layout — Responsive to Activity

The interface adapts its density and mood to the current activity:

| Activity | UI Response |
|----------|------------|
| **Idle/Browsing** | Generous spacing, large cards, calm colors. The interface breathes. |
| **Composing** (prompt focused) | UI contracts. Non-essential elements fade to 40% opacity. Prompt + style options dominate. Maximum focus. |
| **Generating** | Subtle pulse radiates from generating card. Other UI elements reduce to 60% opacity. Attention drawn to pending creation. |
| **Reviewing Results** | Result card expands to near-full-screen. Translucent action overlay at bottom (Save, Remix, Share, Variations). Swipe between results. |
| **Managing** (projects, credits) | Clean list layouts, minimal decoration. Functional mode — efficiency over delight. |

This is implemented via a TCA state-driven `ActivityMode` enum that modifies spacing, opacity, and animation parameters across the view hierarchy.

---

## Micro-Interactions and Delight

| Moment | Animation |
|--------|-----------|
| Generation progress | Card's glass border becomes progress ring — fills clockwise with prismatic gradient |
| Content-adaptive transition | When navigating between projects, accent color morphs smoothly (0.8s ease) — whole UI breathes new color |
| Credit spend | Floating pill briefly expands, shows deduction with strike-through, contracts to new balance |
| Pull to refresh | Small prism icon descends, refracts (splits into rainbow briefly), resolves |
| New content | Lens-flare bloom animation fading to reveal final image |
| Haptic language | Generation start: 3-beat ascending pattern. Completion: resolved chord. Error: single dull thud. |
| Inspiring empty states | Animated gradients with rotating prompts: "What will you create today?" → "The only limit is your imagination." with prismatic text gradient |

---

## Accessibility

- Content-adaptive colors always checked against **WCAG AA minimum**; fallback to default indigo-teal if extracted color fails
- **Reduce Motion**: All parallax, morphing, gradient animations → simple opacity crossfades
- **Reduce Transparency**: Glass materials → solid fills matching underlying color
- **VoiceOver**: Full semantic grouping. Cards announced as single units with rotor actions for context menu items.
- **Dynamic Type**: Tested through XXXL. Layout shifts from horizontal to vertical at largest sizes. Cards become list rows.
- **Switch Control**: All custom gestures have button-based alternatives via contextual toolbar

---

## Technical Implementation

### New Package: `DesignSystem/`
- `PrismTheme` — adaptive color system, typography, spacing
- `AdaptiveColorEngine` — extracts dominant colors from images using `CIAreaAverage`, adjusts for contrast, manages transitions
- `PrismButton` — three tiers (attractor/contextual/quiet) with haptic + animation
- `PanelPicker` — generic expandable panel system with fan-open animation
- `GlassCard` — `ultraThinMaterial` + accent border + shadow system
- `AdaptiveLayout` — monitors TCA state for activity mode, adjusts spacing/opacity
- `LensTextField` — `UIViewRepresentable` with dynamic height, placeholder cycling, toolbar management
- `CommandPalette` — full-screen overlay with fuzzy search

### Animation Engine
```swift
// Continuous gradient shifts on primary CTA
TimelineView(.animation) { ... }

// Panel expand/collapse
.matchedGeometryEffect(id: settingId, in: namespace)

// Activity mode transitions
withAnimation(.easeInOut(duration: 0.4)) { activityMode = .composing }
```

### Performance
- Color extraction: background queue with 2s debounce
- Gradient animations: `drawingGroup()` for Metal acceleration
- Parallax: `CADisplayLink`-driven for 60fps on all devices

---

## Impact Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Effort** | Large (4-5 weeks) | Adaptive color system and activity-responsive layout need significant engineering |
| **Risk** | Medium-High | Color extraction needs extensive contrast testing. Continuous animation performance. |
| **Delight** | Exceptional | No creative iOS app adapts its UI to content. This is "show your friends" territory. |
| **Differentiation** | Very High | Genuinely innovative — positions C4 as more than "another AI art app" |
| **Accessibility** | Good | Strong fallbacks for Reduce Motion/Transparency. WCAG-checked adaptive colors. |
