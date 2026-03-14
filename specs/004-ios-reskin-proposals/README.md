# C4 iOS App — Re-Skin Proposals

Three thematic re-skin proposals for the C4 iOS app, crafted from a thorough audit of every SwiftUI view in the codebase.

## Proposals

| | Aurora | Atelier | Prism |
|---|--------|---------|-------|
| **File** | [proposal-a-aurora.md](proposal-a-aurora.md) | [proposal-b-atelier.md](proposal-b-atelier.md) | [proposal-c-prism.md](proposal-c-prism.md) |
| **Mood** | Futuristic, immersive, cinematic | Warm, editorial, tactile | Intelligent, alive, adaptive |
| **Background** | Dark charcoal-black | Warm off-white (paper) | System-adaptive (cool white/slate-navy) |
| **Accent** | Aurora gradient (violet→cyan→magenta→amber) | Deep terracotta (#C2410C) | Content-adaptive (extracted from user's images) |
| **Typography** | SF Pro Rounded Bold | New York serif + SF Pro | SF Pro Display + SF Mono |
| **Navigation** | FAB + radial menu + bottom drawer | 4-tab with sidebar + Studio dashboard | Spatial zones + Command Palette |
| **Prompt Input** | Collapsed bar ↔ full-screen takeover | Manuscript card with drag-to-resize | "The Lens" with smart line-by-line growth |
| **Selectors** | Visual chip cards | Inline mini-cards + stepper widgets | Fan-out "Prism Panels" |
| **Signature Feature** | Glow-on-dark aesthetic, generation glow ring | Serif editorial style, mechanical counter credits | UI color adapts to content, activity-responsive layout |
| **Effort** | 3-4 weeks | 2-3 weeks | 4-5 weeks |
| **Risk** | Medium | Low | Medium-High |
| **Delight** | Very High | High | Exceptional |

## Problems All Three Address

1. **Bland identity** — stock blue accent, system grays, default SF Symbols
2. **Bad button placement** — CTAs lost at bottom of scrollable forms
3. **Identical pickers** — every option uses `.pickerStyle(.menu)`
4. **Text input bugs** — fixed `minHeight` in ScrollView causes unpredictable expansion
5. **No design system** — inline styles copy-pasted across views
