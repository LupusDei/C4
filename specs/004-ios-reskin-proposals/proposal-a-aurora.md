# Proposal A: Aurora — Luminous Creative Canvas

**Type**: Product / UI-UX Re-Skin
**Author**: Nova
**Date**: 2026-03-11
**Project**: C4 iOS App

---

## Design Philosophy

Aurora treats the C4 app as a **living canvas** — a space where creative energy radiates from the content itself. Inspired by bioluminescent organisms and aurora borealis, the UI recedes into darkness so that the user's creations glow as the visual focal point. Every interaction produces subtle light — taps ripple, generations pulse, completions bloom.

**Mood**: Immersive, futuristic, cinematic. Think: a creative studio floating in space.

---

## Current Problems Addressed

| Problem | Current State | Aurora Fix |
|---------|--------------|------------|
| Bland visual identity | Stock `.accentColor` blue, `.quaternary` backgrounds, default SF Symbols | Dark canvas with aurora gradient accents, custom thin-line icon set |
| Button placement | Primary CTAs at bottom of scrollable VStack forms, pushed off-screen by settings pickers | Sticky floating CTA bar pinned to safe area bottom, always visible |
| Option selectors | Every picker uses `.pickerStyle(.menu)` — identical appearance, requires multiple taps | Visual chip selectors showing all options at once with visual differentiation |
| Text input expansion | TextEditor with fixed `minHeight: 100/80/200` inside ScrollView — unpredictable sizing | Two-state input: collapsed chat bar ↔ full-screen takeover with dynamic height tracking |
| No design system | Inline styles per-view, copy-pasted card/button/badge patterns | Shared `DesignSystem/` package with `AuroraTheme` and reusable components |

---

## Color System

```
Background:       #0D0D12 → #16161F  (deep charcoal-black gradient, blue undertone)
Surface Cards:    ultraThinMaterial over subtle gradient meshes
Primary Accent:   Animated gradient cycling:
                  Electric Violet  #8B5CF6
                  Cyan             #06B6D4
                  Magenta          #EC4899
                  Warm Amber       #F59E0B
Text Primary:     #FAFAFA (pure white)
Text Secondary:   #A3A3B8 (lavender-gray)
Success:          Mint green (neon)
Error:            Coral (neon)
In-Progress:      Electric blue (neon)
```

The accent gradient is **alive** — it slowly cycles through the aurora palette. Active elements pulse gently. Generating cards emit a soft glow ring.

---

## Typography

| Role | Font | Size | Notes |
|------|------|------|-------|
| Display/Headings | SF Pro Rounded Bold | varies | Softer, more approachable than default SF Pro |
| Body | SF Pro Text Regular | 15pt | Slightly larger for dark-background readability |
| Mono/Data | SF Mono | varies | Credit amounts, durations, counters — technical precision |
| Prompt Text | SF Pro Text | 17pt | 1.4 line height, slight letter spacing — the "creative voice" |

---

## Iconography

- Replace all SF Symbols with **custom thin-line icons** with gradient fills
- Tab bar: outlined when inactive, filled with aurora gradient when active
- 0.3s spring micro-animations on every state change
- Generation-in-progress: icon pulses with `.symbolEffect(.pulse)`

---

## Navigation — Single Canvas + Floating Action

**Kill the 3-tab TabView.** Replace with a unified creative workspace:

### Home Canvas
Full-screen scrollable feed with **staggered masonry grid** layout. Recent projects and generations mixed together chronologically. Each card is a portal into that piece of work.

### Floating Action Button (FAB)
- Bottom-right corner, 56pt diameter
- Aurora-gradient circle with `+` icon
- Tap opens **radial menu** that fans out:
  - ✦ New Image
  - ✦ New Video
  - ✦ New Storyboard
  - ✦ New Project
- Menu items appear with staggered spring animation (0.1s delay between items)

### Bottom Drawer
- Swipe up from bottom edge reveals persistent drawer
- Contains: Credits balance (pill badge), Settings gear, History clock icon
- Always accessible, never obstructs creative work
- Drawer has frosted glass background with aurora accent line at top

### Project Context Bar
- When inside a project: slim 44pt bar pins to top
- Shows: project name + style badge + credit balance
- Tapping opens project detail sheet
- Animates in/out with matched geometry effect

---

## Prompt Input — The "Creative Stage"

The prompt is the soul of the creative act. It deserves a dedicated experience, not a form field.

### Collapsed State
- Slim 48pt frosted glass bar at screen bottom (chat-input metaphor)
- Left side: microphone icon + current style pill (tappable)
- Right side: send/generate arrow
- Placeholder text cycles through inspiring suggestions with crossfade

### Expanded State (tap to activate)
1. Dark overlay dims the background (0.5 opacity, spring animation)
2. Text field grows upward to fill top 60% of screen
3. Below the field: horizontally scrollable style chips, recent prompts carousel
4. "Enhance" button pulses gently with aurora gradient border
5. Keyboard rises with custom input accessory toolbar

### Auto-Resize Engine
```swift
// UIViewRepresentable wrapping UITextView
// Tracks intrinsicContentSize changes
// Grows line-by-line with spring animation
// Caps at 60% screen height, then scrolls internally
// Each new line triggers UIImpactFeedbackGenerator(.light)
```

### Dismiss
- Swipe down on the text area, or tap the dimmed background
- Text field collapses back to slim bar with spring animation
- All entered text is preserved

---

## Button Placement — Thumb-Zone Optimization

### The Sticky CTA
The generate button **never scrolls away**. It pins to the bottom safe area as a floating bar:
- 60pt height, full-width with 16pt horizontal padding
- Aurora gradient background (animated)
- Bold white text: "Generate Image" / "Generate Video"
- Frosted glass extension behind it to screen edge
- Loading state: gradient accelerates, text becomes progress description

### Settings Drawer
All settings (quality, provider, aspect ratio, resolution) move into a **collapsible panel** above the CTA:
- **Collapsed**: Single-line summary: `High · 16:9 · 1080p · Flux`
- **Expanded**: Full picker grid with visual selectors (see below)
- Smooth height animation with spring physics

### Quick Presets
Three one-tap configuration buttons above the settings panel:
- ⚡ Quick Draft (low quality, fast, cheap)
- ⚖️ Standard (balanced)
- 👑 Max Quality (highest settings)

---

## Option Selectors — Visual Chips

### Aspect Ratio
Visual ratio cards showing **actual proportions** as colored rectangles:
```
┌──┐  ┌────────┐  ┌──┐  ┌──────────────┐
│  │  │        │  │  │  │              │
│  │  │  16:9  │  │  │  │   21:9       │
│1:│  │        │  │9:│  │              │
│1 │  └────────┘  │16│  └──────────────┘
│  │              │  │
└──┘              └──┘
```
Selected = aurora gradient border + checkmark overlay

### Quality Tier
Three horizontal cards:
- ⚡ **Standard** — "Fast, good enough" — 2 credits
- ⚖️ **High** — "Balanced quality" — 5 credits
- 👑 **Ultra** — "Maximum detail" — 12 credits

Selected card glows with aurora accent. Credit cost badge in top-right.

### Provider
Icon-based horizontal scroll with provider logos/initials. Selected state: logo glows with aurora ring, slight scale-up (1.05).

### Duration (Video)
Custom haptic slider:
- Track shows gradient from short→long
- Tick marks at valid durations
- Value label follows thumb with spring physics
- Each tick triggers haptic feedback

### Mode Toggle (Text-to-Video vs Image-to-Video)
Full-width segmented control with smooth **sliding indicator** animation. The indicator bar slides between options with spring physics. Not the stock iOS segmented style.

---

## Card System — Depth Through Light

### Project Cards
- 3:4 aspect ratio
- Hero image fills entire card
- Project name overlaid at bottom with gradient scrim (black→transparent)
- Long-press: card lifts (shadow grows from 4→12), action buttons fade in
- Tap: matched geometry transition into project detail

### Scene Cards (Storyboard Timeline)
- Horizontal scroll, increased to **280pt width** (from 240pt)
- Subtle parallax effect on scroll (background moves slightly slower)
- Scene number in aurora gradient circle badge
- Active scene has brighter border glow

### Generation Result Cards
- Full-bleed image, no padding
- `.ultraThinMaterial` metadata bar at bottom (prompt snippet, dimensions, provider)
- Swipe up on card to reveal full details panel
- New results enter with "light bloom" animation

---

## Micro-Interactions and Delight

| Moment | Animation |
|--------|-----------|
| Generation starts | Aurora gradient begins orbiting around the card as a progress ring |
| Generation completes | Brief white flash bloom that fades to reveal content (polaroid developing) |
| Credit spend | Particle animation: tiny coins dissolve upward from balance display |
| Pull to refresh | Aurora wave washes down the screen |
| Card appears | Fades up from below with slight scale (0.95→1.0) |
| Empty state | Animated Lottie illustration (rocket launching, paint splashing) |
| Error | Card briefly tints red, shakes horizontally (2 oscillations) |
| Style selected | Chip pulses once with aurora glow |

---

## Accessibility

- All custom components: `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`
- **Reduce Motion**: All animations respect `UIAccessibility.isReduceMotionEnabled` → fall back to simple opacity fades
- **Dynamic Type**: All text scales through XXXL. Horizontal chip layouts wrap to vertical stacks at largest sizes.
- **Haptic Language**:
  - Generation start: heavy impact
  - Completion: success notification
  - Credit spend: soft impact
  - Selection: light impact
- **VoiceOver**: Cards announce as single semantic units with rotor actions

---

## Technical Implementation

### New Package: `DesignSystem/`
Lives in CoreKit. Provides:
- `AuroraTheme` — all colors, fonts, spacing constants
- `AuroraButton` — primary/secondary/ghost variants with haptic + animation
- `AuroraCard` — glass card with configurable glow, shadow, corner radius
- `AuroraTextField` — two-state expanding text input with UITextView bridge
- `AuroraChipPicker<T>` — generic visual selector for any option set
- `GlowModifier` — ViewModifier for animated glow border effect

### Animation Standard
```swift
// Default transition
Animation.spring(response: 0.35, dampingFraction: 0.75)

// Card entrance
Animation.spring(response: 0.5, dampingFraction: 0.8).delay(index * 0.05)

// Glow pulse
Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
```

### Color Mode
- Dark mode is the **default and primary** experience
- Light mode variant available: cream backgrounds, warm white surfaces, same aurora accents
- Controlled via `@Environment(\.colorScheme)`

---

## Impact Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Effort** | Large (3-4 weeks) | New design system, custom components, animation work |
| **Risk** | Medium | Custom components need device-size testing |
| **Delight** | Very High | Dark canvas + glow = immersive creative studio |
| **Differentiation** | High | No competitor has this aesthetic |
| **Accessibility** | Good | Reduce Motion support, Dynamic Type, haptics |
