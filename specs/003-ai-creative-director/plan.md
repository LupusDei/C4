# Implementation Plan: AI Creative Director — Trend-Aware Prompt Intelligence

**Branch**: `003-ai-creative-director` | **Date**: 2026-03-11
**Epic**: `C4-003` | **Priority**: P2

## Summary

Add an AI creative director layer to C4 that enhances rough prompts into production-quality prompts, provides a visual style library with 30+ presets, and maintains a searchable prompt history with remix capabilities. Uses Claude API for all AI operations. Content intelligence (trends, niche suggestions) and the learning loop (analytics, "more like this") are deferred to P2 sub-epics.

## Bead Map

- `C4-003` - Root epic: AI Creative Director — Trend-Aware Prompt Intelligence
  - `C4-003.1` - Setup — Database Schema & Models
    - `C4-003.1.1` - Create style_presets, prompt_history tables migration
    - `C4-003.1.2` - Create StylePreset iOS model
    - `C4-003.1.3` - Create PromptHistory iOS model
  - `C4-003.2` - Foundational — Backend CRUD & API Client
    - `C4-003.2.1` - Create style preset CRUD routes
    - `C4-003.2.2` - Create prompt history routes
    - `C4-003.2.3` - Seed 30+ curated style presets
    - `C4-003.2.4` - Register styles and prompts routes
    - `C4-003.2.5` - Add style/history API methods to iOS APIClient
    - `C4-003.2.6` - Create PromptFeature SPM package scaffold
  - `C4-003.3` - US1: Smart Prompt Enhancement
    - `C4-003.3.1` - Create prompt-enhancer service with Claude API
    - `C4-003.3.2` - Add prompt enhance endpoint
    - `C4-003.3.3` - Create PromptEnhancerView
    - `C4-003.3.4` - Create PromptEnhancerReducer
    - `C4-003.3.5` - Integrate enhancer into ImageGenerateView
    - `C4-003.3.6` - Integrate enhancer into VideoGenerateView
  - `C4-003.4` - US2: Visual Style Library
    - `C4-003.4.1` - Create StylePickerView gallery
    - `C4-003.4.2` - Create StylePickerReducer
    - `C4-003.4.3` - Add style extraction endpoint
    - `C4-003.4.4` - Add Save as Style action
    - `C4-003.4.5` - Add project style lock UI
    - `C4-003.4.6` - Wire style picker into generation views
    - `C4-003.4.7` - Update project route for style lock
  - `C4-003.5` - US3: Prompt History & Remix
    - `C4-003.5.1` - Auto-record prompt history on generation
    - `C4-003.5.2` - Track kept/regenerated status
    - `C4-003.5.3` - Add remix endpoint
    - `C4-003.5.4` - Create PromptHistoryView
    - `C4-003.5.5` - Create PromptHistoryReducer
    - `C4-003.5.6` - Add history access to generation screens
  - `C4-003.6` - US4: Content Intelligence (P2)
    - `C4-003.6.1` - Add niche field migration
    - `C4-003.6.2` - Add suggest endpoint
    - `C4-003.6.3` - Add series ideation endpoint
    - `C4-003.6.4` - Create ContentSuggestionsView
    - `C4-003.6.5` - Create SeriesGeneratorView
    - `C4-003.6.6` - Create content intelligence reducer
  - `C4-003.7` - US5: Learning Loop (P2)
    - `C4-003.7.1` - Add analytics aggregation queries
    - `C4-003.7.2` - Add More Like This endpoint
    - `C4-003.7.3` - Create GenerationAnalyticsView
    - `C4-003.7.4` - Add More Like This button to asset preview
    - `C4-003.7.5` - Create learning loop reducer

## Technical Context

**Stack**: Node.js/Fastify backend (plain JS, ESM), iOS SwiftUI + TCA, PostgreSQL + Knex, BullMQ + Redis
**LLM**: Claude API (Anthropic SDK) — used for prompt enhancement, provider optimization, remix, and series ideation
**Storage**: PostgreSQL for style presets, prompt history, generation analytics
**Testing**: Backend — Fastify inject; iOS — TCA test store
**Constraints**: Enhancement must be synchronous (< 3s). Style presets seeded via migration. Prompt history must handle 1000+ entries with pagination.

## Architecture Decisions

1. **Claude-only for all AI operations**: Consistent with the storyboard pipeline's scene-splitter. Single LLM dependency simplifies prompt engineering and error handling.

2. **Provider-aware prompt templates**: Each provider (FLUX, OpenAI, Grok, Nano Banana) has a prompt template in the enhancement service that adapts the AI output to provider-specific terminology. Stored as config, not database.

3. **Style presets in database with seed migration**: A `style_presets` table holds both curated (system) and custom (user) presets. Curated presets are inserted via a Knex seed migration. Custom styles share the same table with an `is_custom` flag.

4. **Prompt history as automatic tracking**: Every generation automatically creates a prompt_history record. No user action required. The `kept` field is updated when the user regenerates (marking the old one as not kept) or keeps the result.

5. **Synchronous enhancement endpoint**: Prompt enhancement returns inline (not queued). A single Claude API call with structured output takes < 3s. This keeps the UX snappy — user types, taps enhance, sees result immediately.

6. **New iOS package: PromptFeature**: Contains the enhanced prompt input, style picker, and prompt history views. Integrates with the existing GenerateFeature by providing an enhanced prompt to the generation flow.

## Files Changed

### Backend — New Files
| File | Purpose |
|------|---------|
| `backend/src/db/migrations/003_creative_director.js` | Create style_presets, prompt_history tables |
| `backend/src/db/seeds/001_style_presets.js` | Seed 30+ curated style presets |
| `backend/src/routes/prompts.js` | Prompt enhancement, history, remix endpoints |
| `backend/src/routes/styles.js` | Style preset CRUD (list, get, create custom, update, delete) |
| `backend/src/services/prompt-enhancer.js` | Claude-powered prompt enhancement with provider awareness |

### Backend — Modified Files
| File | Change |
|------|--------|
| `backend/src/server.js` | Register prompts and styles routes |
| `backend/src/workers/generation.js` | Record prompt history on generation start, update `kept` on regeneration |
| `backend/src/routes/generate.js` | Accept optional `stylePresetId` and `enhanced_prompt` fields |
| `backend/src/routes/projects.js` | Add `default_style_preset_id` to project update |

### iOS — New Files
| File | Purpose |
|------|---------|
| `ios/C4/Packages/PromptFeature/` | New SPM package |
| `PromptFeature/Sources/PromptFeature/PromptEnhancerView.swift` | Enhanced prompt input with before/after display |
| `PromptFeature/Sources/PromptFeature/PromptEnhancerReducer.swift` | TCA reducer for enhancement flow |
| `PromptFeature/Sources/PromptFeature/StylePickerView.swift` | Style preset gallery with thumbnails |
| `PromptFeature/Sources/PromptFeature/StylePickerReducer.swift` | TCA reducer for style selection |
| `PromptFeature/Sources/PromptFeature/PromptHistoryView.swift` | Searchable prompt history list |
| `PromptFeature/Sources/PromptFeature/PromptHistoryReducer.swift` | TCA reducer for history browsing/remix |

### iOS — New Models
| File | Purpose |
|------|---------|
| `CoreKit/Sources/CoreKit/Models/StylePreset.swift` | StylePreset model |
| `CoreKit/Sources/CoreKit/Models/PromptHistory.swift` | PromptHistory model |

### iOS — Modified Files
| File | Change |
|------|--------|
| `CoreKit/Sources/CoreKit/APIClient.swift` | Add prompt enhancement, style, and history API methods |
| `GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift` | Replace plain prompt field with PromptEnhancerView, add style picker |
| `GenerateFeature/Sources/GenerateFeature/ImageGenerateReducer.swift` | Integrate prompt enhancement and style selection into generation flow |
| `GenerateFeature/Sources/GenerateFeature/VideoGenerateView.swift` | Add PromptEnhancerView and style picker to video generation |
| `GenerateFeature/Sources/GenerateFeature/VideoGenerateReducer.swift` | Same integration as image |
| `ios/C4/C4App.swift` | Add PromptFeature dependency |

## Phase 1: Setup — Database & Models

Create the database schema and data models on both sides.

- Migration: `style_presets` table (id, name, description, prompt_modifier, category, thumbnail_url, is_custom, user_id nullable, timestamps)
- Migration: `prompt_history` table (id, original_prompt, enhanced_prompt, provider, style_preset_id nullable, asset_id nullable, kept boolean default true, timestamps)
- Migration: Add `default_style_preset_id` column to `projects` table
- iOS models: `StylePreset` and `PromptHistory` Codable structs in CoreKit

## Phase 2: Foundational — Backend Endpoints & API Client

Build the REST endpoints and wire the iOS API client.

- Backend: Style preset endpoints — list (with category filter), get by ID, create custom, update custom, delete custom
- Backend: Prompt history endpoints — list (paginated, searchable), get by ID, delete
- Backend: Seed 30+ curated style presets via Knex seed file
- Backend: Register routes in server.js
- iOS: APIClient extensions for all style and history endpoints
- iOS: Create PromptFeature SPM package scaffold

## Phase 3: US1 — Smart Prompt Enhancement (MVP)

The core AI capability: enhance rough prompts into production-quality prompts.

- Backend: `prompt-enhancer.js` service — calls Claude with the rough prompt + selected provider, returns enhanced prompt with provider-specific adaptations
- Backend: `POST /api/prompts/enhance` endpoint — accepts `{ prompt, provider }`, returns `{ original, enhanced, provider_hints }`
- Backend: Provider template configs — mapping of provider names to their preferred prompt terminology
- iOS: `PromptEnhancerView` — text input with "Enhance" button, before/after display, editable enhanced prompt
- iOS: `PromptEnhancerReducer` — handles enhance action, API call, displays result
- iOS: Integrate PromptEnhancerView into ImageGenerateView replacing the plain TextField

## Phase 4: US2 — Visual Style Library

Style presets that modify prompts automatically.

- iOS: `StylePickerView` — scrollable gallery grid with preset thumbnails, name, and category tabs (All, Cinematic, Illustration, Photography, Abstract, etc.)
- iOS: `StylePickerReducer` — loads presets, handles selection, applies prompt modifier
- iOS: "Save as Style" action on asset preview — extracts style elements from the prompt and creates a custom preset
- iOS: Project style lock — setting in project detail to set default style, applied automatically on generation screens
- Backend: Add custom style creation endpoint with style extraction prompt (Claude call to extract style elements from a full prompt)
- Integrate style picker into ImageGenerateView and VideoGenerateView

## Phase 5: US3 — Prompt History & Remix

Save and remix past prompts.

- Backend: Auto-record prompt history on every generation (hook into generate route or worker)
- Backend: Track `kept` field — mark as not-kept when the same user regenerates with the same asset slot
- Backend: `POST /api/prompts/remix` endpoint — takes a prompt, uses Claude to generate a meaningful variation
- iOS: `PromptHistoryView` — searchable list with prompt text, provider badge, result thumbnail, and date
- iOS: `PromptHistoryReducer` — load paginated history, search, tap to load, remix action
- iOS: History access from generation screens (e.g., clock icon in prompt bar)

## Phase 6: US4 — Content Intelligence (P2, deferred)

Trend suggestions and series ideation.

- Backend: Niche configuration on projects (enum field: tech, fitness, cooking, comedy, education, general)
- Backend: `POST /api/prompts/suggest` — Claude generates niche-aware content ideas
- Backend: `POST /api/prompts/series` — Claude generates 5-10 episode series from a theme
- iOS: Suggestions panel accessible from generation screen
- iOS: Series generator view with theme input and episode card output

## Phase 7: US5 — Learning Loop (P2, deferred)

Generation analytics and "More Like This".

- Backend: Analytics aggregation query — keep/regenerate ratios by provider, style, prompt keywords
- Backend: `POST /api/prompts/more-like-this` — takes an asset ID, extracts effective elements, generates variation prompt
- iOS: Analytics dashboard (simple stats view in prompt history)
- iOS: "More Like This" button on asset preview → generates similar content

## Parallel Execution

After Phase 2 (Foundational), the following can run in parallel:
- **Phase 3** (Prompt Enhancement) and **Phase 4** (Style Library) are independent — one is AI service logic, the other is UI/preset management
- **Phase 5** (Prompt History) depends on Phase 3 (needs enhancement to record history of) but can start scaffolding in parallel
- **Phase 6** (Content Intelligence) depends on Phase 2 only — independent of Phases 3-5
- **Phase 7** (Learning Loop) depends on Phase 5 (needs history data)

```
Phase 1 → Phase 2 → Phase 3 (Enhancement)  ──→ Phase 5 (History) ──→ Phase 7 (Learning Loop)
                   → Phase 4 (Style Library)
                   → Phase 6 (Content Intelligence, P2)
```

## Verification Steps

- [ ] Type rough prompt, tap Enhance → detailed prompt with lighting/composition/style appears
- [ ] Switch provider, enhance same prompt → terminology adapts to provider strengths
- [ ] Browse style gallery, select "Cinematic" → prompt modified with cinematic terms
- [ ] Save custom style from a generation → appears in custom styles section
- [ ] Set project style lock → new generations auto-apply the locked style
- [ ] Generate 3 images → all appear in prompt history with thumbnails
- [ ] Tap Remix on a past prompt → meaningful variation generated
- [ ] Search prompt history → results filtered correctly
