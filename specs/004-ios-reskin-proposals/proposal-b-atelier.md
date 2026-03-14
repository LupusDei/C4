# Proposal B: Atelier — Warm Tactile Craftspace

**Type**: Product / UI-UX Re-Skin
**Author**: Nova
**Date**: 2026-03-11
**Project**: C4 iOS App

---

## Design Philosophy

Atelier (French for "artist's workshop") reimagines C4 as a **physical creative studio translated into pixels**. Where Aurora is futuristic and luminous, Atelier is warm, textured, and grounded. Inspired by Dieter Rams' functionalism meets a Kinfolk editorial spread — every element feels like it has weight, texture, and intention.

**Mood**: Warm, confident, editorial. Think: a beautifully lit design studio with a perfect espresso.

---

## Current Problems Addressed

| Problem | Current State | Atelier Fix |
|---------|--------------|-------------|
| Bland visual identity | Generic blue accent, system grays, stock icons | Terracotta accent, New York serif headings, hand-crafted icon set |
| Button placement | CTAs lost in scrollable forms | Three-tier visual hierarchy with pinned primary CTA and text-link secondary actions |
| Option selectors | Identical `.menu` pickers everywhere | Tasteful inline controls: ratio cards, quality mini-cards, stepper widgets |
| Text input expansion | Fixed min-heights, unpredictable sizing | "Manuscript Card" with drag-to-resize handle and haptic detents |
| No design system | Copy-pasted inline styles | `AtelierTheme` with warm paper-and-shadow aesthetic throughout |

---

## Color System

```
Background:       #FAF8F5  (warm off-white, paper-like, never sterile)
Surface Cards:    #FFFFFF  with warm shadow rgba(120, 90, 50, 0.08)
Primary Accent:   #C2410C  (deep terracotta — warm, bold, used sparingly for CTAs only)
Secondary:        #65A30D  (sage green, success states)
Tertiary:         #1E3A5F  (deep navy, information states)
Text Primary:     #292524  (charcoal — never pure black)
Text Secondary:   #78716C  (warm gray)
Borders:          #E7E5E4  (1px, cornerRadius: 16 for organic softness)
Error:            #DC2626  (warm red, text-only, tucked in context menus)

Dark Mode:
Background:       #1C1917  (rich espresso)
Surface:          #292524  (dark warm gray)
Text:             #FAF8F5  (cream-on-dark)
Accent:           #C2410C  (terracotta persists — brand anchor)
```

---

## Typography

| Role | Font | Size | Notes |
|------|------|------|-------|
| Display | New York (serif) Bold | varies | Editorial gravitas. "Generate Image" becomes a statement. |
| Body | SF Pro Text Regular | 15pt | Clean and functional for UI chrome |
| Prompt Text | New York Regular | 17pt | 1.5 line height — prompts feel like manuscript text |
| Captions | SF Pro Text Medium | 12pt | Warm gray — metadata recedes gracefully |
| Credit Numbers | New York (tabular lining) | varies | Elegant, not clinical |

The serif/sans-serif pairing creates a clear hierarchy: **New York for creative content, SF Pro for interface controls**. This separation helps users intuitively distinguish "my work" from "app chrome."

---

## Iconography

- Custom icon set: slightly rounded, 2pt stroke weight
- Default: warm gray. Active: terracotta
- Tab icons: **tiny line drawings** instead of generic SF Symbols
  - Sketchbook for Projects
  - Wand with sparkle for Generate
  - Coin with laurel for Credits
  - House with chimney for Studio (new tab)

---

## Navigation — Sidebar + Studio Tab

### iPad / Large iPhone
Collapsible sidebar (Apple Notes/Files pattern):
- Projects list with thumbnails
- Recent Generations section
- Storyboards section
- Collapses to icon-only rail, expands on hover/tap

### Compact iPhone
Keep bottom tabs but redesign:
- Larger 28pt icons with labels always visible
- Active tab: terracotta dot indicator below icon (not filled-icon style)
- **Add 4th tab: "Studio"**

### Studio Tab (New)
A personal creative dashboard — the app's "home":
- **Current Project Spotlight**: Hero card of active project with quick actions
- **Recent Generations**: Horizontal carousel of latest 10 generations
- **Credit Balance**: Warm card with balance, last transaction, "Add Credits" button
- **Continue Where You Left Off**: Smart section showing last-edited storyboard, draft prompt, etc.
- **Prompt of the Day**: Inspirational creative prompt with "Try This" button

### Breadcrumb Navigation
Within project views, a slim breadcrumb bar:
```
Projects  ›  My Film  ›  Storyboard  ›  Scene 3
```
Each segment is tappable. Always know where you are. Never feel lost.

---

## Prompt Input — The "Manuscript"

The prompt input is a **standalone white card** with subtle shadow, sitting on the warm background like a piece of paper on a desk.

### Visual Design
- Pure white card on warm off-white background
- Generous 20pt internal padding
- Subtle warm shadow underneath
- Optional faint horizontal rules behind text (notebook paper effect, toggle in settings)
- Word count pill in bottom-right corner, updates live

### Resize Behavior
**Drag handle** at the bottom edge of the manuscript card:
- User drags to resize manually
- **Haptic detents** at three heights:
  - Compact (100pt) — for quick edits
  - Medium (200pt) — default working height
  - Full (400pt) — deep writing mode
- System remembers preferred height per screen
- No unexpected expansion or contraction — the user is always in control

### Enhanced Prompt Display
After enhancement, editorial markup style:
- Original text shows in muted strikethrough above
- Enhanced text in bold New York serif below
- "Revert" link to go back
- Clear visual diff of what changed

### Style Tag
Selected style appears as a small tag pinned to top-right corner of manuscript card:
```
┌─────────────────────────────────────[Cinematic]─┐
│                                                  │
│  A vast desert landscape at golden hour,         │
│  with a lone figure walking toward...            │
│                                                  │
│                                          42 words│
└──────────────────────────────────────────────────┘
```

---

## Button Placement — Content-First Hierarchy

### Tier 1: Primary CTA
- Full-width terracotta button pinned 16pt above safe area bottom
- Rounded corners (16pt), 52pt height
- New York Bold white text
- Pressed state: darken 10%, scale 0.98, medium haptic impact
- Only ONE Tier 1 button per screen. Ever.

### Tier 2: Contextual Tools
- **Slim toolbar strip** directly below the manuscript card
- Icon buttons only, 36pt touch targets
- Labels appear on long-press (tooltip style)
- Contains: Style Picker, History, Enhance, Camera
- Keeps the generate screen focused: **Prompt → Tools → Settings → Generate**

### Tier 3: Quiet Actions
- Text-only buttons in charcoal. No background, semibold weight.
- "Clear", "Reset", "More Options"
- Visible but never distracting
- Destructive actions: warm red text-only, tucked in context menus or swipe actions

---

## Option Selectors — Tasteful Inline Controls

### Aspect Ratio
Horizontal row of **proportional rectangles** rendered at actual ratios:
```
 ┌──┐   ┌──────┐   ┌──┐   ┌────────────┐
 │  │   │      │   │  │   │            │
 │  │   │ Wide │   │  │   │  Cinema    │
 │Sq│   │      │   │Ta│   │            │
 │  │   └──────┘   │ll│   └────────────┘
 └──┘              │  │
                   └──┘
```
Labels below each. Selected = terracotta border.

### Quality Tier
Three mini-cards in a horizontal row:
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ ⚡ Standard  │  │ ⚖️  High     │  │ 👑 Ultra    │
│             │  │             │  │             │
│ Fast, lower │  │ Balanced    │  │ Maximum     │
│ detail      │  │ quality     │  │ detail      │
│        2 cr │  │        5 cr │  │       12 cr │
└─────────────┘  └─────────────┘  └─────────────┘
```
Selected card: terracotta left border accent (bookmark style).

### Provider
Horizontal scroll of logo cards with provider name below. Selected = subtle elevation increase + terracotta underline.

### Duration
Custom stepper: `[ - ]  5.0s  [ + ]` with terracotta accent on buttons. Haptic on each step. Large centered value in New York Bold.

### Resolution
Capsule pills in horizontal group with smooth selection indicator slide:
```
( 720p )  (( 1080p ))  ( 4K )
```
Selected pill filled with terracotta.

### Collapsible Wrapper
All selectors grouped under a collapsible "Options" section:
- Disclosure triangle + one-line summary when collapsed: `16:9 · High · Flux · 1080p`
- Remembers open/closed state per user preference

---

## Card System — Paper and Shadow

### Project Cards
- White card on warm background
- 1:1 hero image with 8pt corner radius (slightly less rounded = more editorial)
- Title below image in New York serif
- Subtle warm shadow that deepens on press (2→6 radius, 0.08→0.15 opacity)
- No border — shadow alone creates depth

### Scene Cards (Storyboard)
- Increased to **300pt width** for better readability
- Film-frame aesthetic: thin dark border (#292524, 1pt)
- Scene number in small serif type, top-left
- Narration text in **italics** (New York Italic)
- Visual prompt in regular weight
- Connected by thin terracotta lines between cards

### Generation History
- Masonry grid (2 columns), generous 12pt gutters
- Cards have no border — just image + shadow
- Press lifts card (shadow deepens, scale 1.02)
- Metadata only shows on tap/hold

### Credit Transactions
- Clean table layout: date | description | amount
- Positive credits: sage green text
- Negative credits: warm gray text
- Hairline separators (#E7E5E4)
- No card wrappers — clean typography carries the design

---

## The "Workbench" — Storyboard Reimagined

The storyboard timeline transforms into a **horizontal workbench**:

- Scenes laid out like physical cards on a wooden table
- Drag handles are visible grips with subtle texture
- Scene connections shown as thin terracotta connector lines
- **"Add Scene"**: Dashed-border empty card at the end — "Drop a scene here or tap to create"
- Scene variations: displayed as a **deck** — cards fanned out slightly, tap to spread and compare side-by-side

---

## Micro-Interactions and Delight

| Moment | Animation |
|--------|-----------|
| Generation progress | Horizontal ink-spread progress bar — left to right with organic leading edge |
| Credit balance change | Mechanical counter animation — digits roll individually |
| Card entrance | Paper-sliding-onto-desk feel (ease-out with slight bounce) |
| Pull to refresh | Pencil illustration draws a circle, completes on release |
| Completion toast | Warm banner slides from top: "Your image is ready" + thumbnail + "View" |
| Empty state | Hand-drawn illustration (Dropbox style) + warm copy: "Your studio is empty. Every masterpiece starts with a blank canvas." |
| Error | Gentle shake + warm red flash on affected element |

---

## Accessibility

- All interactive elements meet **4.5:1 contrast ratio** on warm backgrounds
- Custom focus indicators: terracotta outlines (2pt) instead of default blue
- VoiceOver: Every card announces content, status, and available actions
- Dynamic Type: Serif headings scale beautifully. Layout shifts from horizontal to vertical at accessibility sizes.
- Haptics: gentle and purposeful. Light impact on selections, medium on generation start, notification on completion.

---

## Technical Implementation

### New Package: `DesignSystem/`
- `AtelierTheme` — `AtelierColors`, `AtelierTypography`, `AtelierSpacing`
- `ManuscriptTextEditor` — UITextView with ruled-line background drawing and drag-to-resize
- `TactileButton` — press animation, haptic integration, three style tiers
- `ChipPicker<T>` — generic horizontal selector with selection state
- `CollapsibleSection` — smooth height animation for settings panels
- `AtelierCard` — base card component with warm shadow system

### Animation Standard
```swift
// Movements
Animation.easeOut(duration: 0.25)

// Scale effects
Animation.spring(response: 0.4, dampingFraction: 0.8)

// Counter roll
Animation.interpolatingSpring(stiffness: 120, damping: 15)
```

---

## Impact Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Effort** | Medium-Large (2-3 weeks) | Less custom animation than Aurora, more typography precision |
| **Risk** | Low | Builds on familiar iOS patterns (sidebar, cards, buttons) |
| **Delight** | High | Warm editorial aesthetic stands out from dark/neon creative tools |
| **Differentiation** | High | Appeals to professional creatives who value taste and restraint |
| **Accessibility** | Very Good | High contrast on warm backgrounds, serif scales well |
