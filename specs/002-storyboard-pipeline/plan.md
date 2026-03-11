# Implementation Plan: Script-to-Scene Storyboard Pipeline

**Branch**: `002-storyboard-pipeline` | **Date**: 2026-03-11
**Epic**: `C4-002` | **Priority**: P1

## Summary

Add a storyboard system to C4 that lets users paste a script, have AI split it into scenes, batch-generate visuals for all scenes, and assemble the result into a final video. This builds on the existing generation and assembly infrastructure, adding two new database entities (storyboards, scenes) and a new iOS feature package (StoryboardFeature).

## Bead Map

- `C4-002` — Root: Script-to-Scene Storyboard Pipeline
  - `C4-002.1` — Setup: Database & Models
    - `C4-002.1.1` — Create storyboards/scenes migration
    - `C4-002.1.2` — Create Storyboard iOS model
    - `C4-002.1.3` — Create Scene iOS model
  - `C4-002.2` — Foundational: Backend CRUD & API Client
    - `C4-002.2.1` — Storyboard CRUD routes
    - `C4-002.2.2` — Scene CRUD + reorder routes
    - `C4-002.2.3` — Register storyboard routes in server.js
    - `C4-002.2.4` — iOS API client storyboard methods
    - `C4-002.2.5` — StoryboardFeature SPM package scaffold
  - `C4-002.3` — US1: Script Input & AI Scene Splitting (MVP)
    - `C4-002.3.1` — Scene-splitter service (LLM call)
    - `C4-002.3.2` — Script splitting route
    - `C4-002.3.3` — ScriptInputView
    - `C4-002.3.4` — Script splitting reducer actions
  - `C4-002.4` — US2: Storyboard Timeline & Scene Card UI
    - `C4-002.4.1` — SceneCardView component
    - `C4-002.4.2` — StoryboardTimelineView
    - `C4-002.4.3` — Drag-and-drop reorder + add/delete reducer
    - `C4-002.4.4` — StoryboardListView
    - `C4-002.4.5` — Wire into ProjectDetailView
    - `C4-002.4.6` — Add StoryboardFeature to C4App
  - `C4-002.5` — US3: Batch Generation
    - `C4-002.5.1` — Batch generate endpoint
    - `C4-002.5.2` — Worker: accept sceneId, update scene asset
    - `C4-002.5.3` — Scene-level WebSocket progress
    - `C4-002.5.4` — Generate All UI with provider picker
    - `C4-002.5.5` — Per-scene progress indicators
    - `C4-002.5.6` — Batch generation reducer effects
  - `C4-002.6` — US4: One-Click Assembly
    - `C4-002.6.1` — Storyboard assemble route
    - `C4-002.6.2` — captionsFromScript() function
    - `C4-002.6.3` — Assembly service: accept SRT content directly
    - `C4-002.6.4` — Assemble button + options UI
    - `C4-002.6.5` — Assembly progress + result reducer
  - `C4-002.7` — US5: Scene Variations
    - `C4-002.7.1` — Scene variations endpoint
    - `C4-002.7.2` — Prompt perturbation logic
    - `C4-002.7.3` — SceneVariationsView comparison grid
    - `C4-002.7.4` — Variation generation + winner selection reducer

## Technical Context

**Stack**: Node.js/Fastify backend (plain JS, ESM), iOS SwiftUI + TCA, PostgreSQL + Knex, BullMQ + Redis
**Storage**: PostgreSQL for storyboard/scene metadata, existing asset storage for generated files
**Testing**: Backend — Fastify inject; iOS — TCA test store
**Constraints**: AI scene splitting requires an LLM API call (Claude or OpenAI). Batch generation must respect BullMQ concurrency (currently 2 workers). Assembly uses existing Creatomate pipeline.

## Architecture Decisions

1. **Storyboard as first-class entity** (not a project subtype): Storyboards belong to projects but have their own CRUD lifecycle. A project can have multiple storyboards (e.g., different video concepts).

2. **Scenes reference assets via foreign key**: Scenes point to the existing `assets` table rather than duplicating storage. This lets scene assets appear in both the storyboard timeline and the project's asset gallery.

3. **AI scene splitting as a synchronous endpoint**: The script-to-scenes call returns immediately (< 10s for typical scripts). No need for a job queue — it's a single LLM API call that returns structured JSON.

4. **Batch generation reuses existing job queue**: "Generate All" creates one BullMQ job per scene, using the same `generate-image` / `generate-video` job types. A new `storyboardId` and `sceneId` field on jobs links results back to scenes.

5. **Script-based captions for assembly**: Instead of Deepgram transcription, captions are built from scene narration text + scene durations. This is more accurate (it's the actual script) and costs 0 credits.

6. **New iOS package: StoryboardFeature**: Follows the existing modular package pattern (like GenerateFeature, AssemblyFeature). Depends on CoreKit for models and API client.

## Files Changed

### Backend — New Files
| File | Purpose |
|------|---------|
| `backend/src/db/migrations/002_storyboards.js` | Create storyboards and scenes tables |
| `backend/src/routes/storyboards.js` | CRUD routes + scene splitting + batch generate + assemble |
| `backend/src/services/scene-splitter.js` | AI script-to-scenes logic (LLM call + structured output) |

### Backend — Modified Files
| File | Change |
|------|--------|
| `backend/src/server.js` | Register storyboards routes |
| `backend/src/workers/generation.js` | Accept sceneId on jobs, update scene asset_id on completion |
| `backend/src/routes/assemble.js` | Accept storyboardId param, build clip list from scene order |
| `backend/src/services/assembly.js` | Support script-based caption generation from scene narration text |
| `backend/src/services/captions.js` | Add `captionsFromScript()` function (narration text + timings → SRT) |
| `backend/src/config/credit-costs.js` | Add scene-splitting cost (if any — may be free) |

### iOS — New Files
| File | Purpose |
|------|---------|
| `ios/C4/Packages/StoryboardFeature/` | New SPM package |
| `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift` | TCA reducer for storyboard state |
| `StoryboardFeature/Sources/StoryboardFeature/StoryboardListView.swift` | List of storyboards in a project |
| `StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift` | Horizontal scene card timeline |
| `StoryboardFeature/Sources/StoryboardFeature/SceneCardView.swift` | Individual scene card component |
| `StoryboardFeature/Sources/StoryboardFeature/ScriptInputView.swift` | Script paste/edit screen |
| `StoryboardFeature/Sources/StoryboardFeature/SceneVariationsView.swift` | Variation comparison grid |

### iOS — New Models
| File | Purpose |
|------|---------|
| `CoreKit/Sources/CoreKit/Models/Storyboard.swift` | Storyboard model |
| `CoreKit/Sources/CoreKit/Models/Scene.swift` | Scene model |

### iOS — Modified Files
| File | Change |
|------|--------|
| `CoreKit/Sources/CoreKit/APIClient.swift` | Add storyboard API methods |
| `ios/C4/C4App.swift` | Add storyboard access from project detail |
| `ProjectFeature/Sources/ProjectFeature/ProjectDetailView.swift` | Add "Storyboards" section linking to StoryboardListView |

## Phase 1: Setup — Database & Models

Create the database schema and data models on both sides.

- Migration: `storyboards` table (id, project_id, title, script_text, status, timestamps) and `scenes` table (id, storyboard_id, order_index, narration_text, visual_prompt, duration_seconds, asset_id nullable, variations JSONB, timestamps)
- iOS models: `Storyboard` and `Scene` Codable structs in CoreKit

## Phase 2: Foundational — Backend CRUD & API Client

Build the REST endpoints for storyboard and scene management, and wire the iOS API client.

- Backend: Full CRUD for storyboards (scoped to project) and scenes (scoped to storyboard)
- Backend: Scene reordering endpoint (PATCH with new order array)
- iOS: APIClient extensions for all storyboard/scene endpoints
- Server.js: Register the new routes

## Phase 3: US1 — Script Input & AI Scene Splitting (MVP)

The core AI capability: paste a script, get structured scenes back.

- Backend: `scene-splitter.js` service — calls Claude/OpenAI with the script, returns structured JSON (scenes array with narration, visual_prompt, duration)
- Backend: `POST /api/storyboards/:id/split` endpoint that calls the splitter and creates scene records
- iOS: `ScriptInputView` — text editor for pasting/writing scripts, "Split into Scenes" button
- iOS: Basic `StoryboardReducer` handling script input → API call → scene list state

## Phase 4: US2 — Storyboard Timeline & Scene Card UI

The visual interface for managing scenes.

- iOS: `StoryboardTimelineView` — horizontal ScrollView of SceneCardViews
- iOS: `SceneCardView` — shows scene number, narration excerpt, visual prompt, duration, generation status badge
- iOS: Scene editing (tap card to edit narration/prompt/duration)
- iOS: Drag-and-drop reorder via `onMove` modifier
- iOS: Add/delete scene actions
- iOS: `StoryboardListView` — list of storyboards within a project
- iOS: Wire into `ProjectDetailView` with "Storyboards" navigation

## Phase 5: US3 — Batch Generation

Queue generation for all scenes at once with per-scene progress.

- Backend: `POST /api/storyboards/:id/generate` — queues one job per scene, returns job IDs
- Backend: Worker update — accept `sceneId`, update scene's `asset_id` on completion
- Backend: WebSocket — broadcast scene-level progress (storyboardId + sceneId + progress)
- iOS: "Generate All" button on timeline, provider/quality picker
- iOS: Per-card progress indicators driven by WebSocket
- iOS: "Regenerate" button on individual scene cards
- Credit deduction: per-scene based on provider, same as existing generation costs

## Phase 6: US4 — One-Click Assembly

Assemble all scene assets into a final video.

- Backend: `POST /api/storyboards/:id/assemble` — builds clip list from scenes in order, calls existing assembly pipeline
- Backend: Script-based captions — `captionsFromScript()` generates SRT from scene narration + cumulative duration offsets
- Backend: Modify `assembly.js` to accept SRT content directly (not just Deepgram transcription)
- iOS: "Assemble" button on timeline (enabled only when all scenes have assets)
- iOS: Transition picker (none/crossfade/fade) and caption toggle
- iOS: Assembly progress via WebSocket, result displayed as storyboard's output asset

## Phase 7: US5 — Scene Variations

Generate alternatives for individual scenes and pick the best.

- Backend: `POST /api/storyboards/:storyboardId/scenes/:sceneId/variations` — generates N variations with prompt perturbation
- Backend: Prompt perturbation logic — AI rewrites the visual prompt N ways, preserving core concept
- iOS: `SceneVariationsView` — 2x2 grid comparing original + variations
- iOS: "Use This" action to set a variation as the scene's primary asset
- Store variation asset IDs in scene's `variations` JSONB field

## Parallel Execution

After Phase 2 (Foundational), the following can run in parallel:
- **Phase 3** (AI Scene Splitting) and **Phase 4** (Timeline UI) are independent — one is backend AI logic, the other is iOS UI
- **Phase 5** (Batch Generation) depends on both Phase 3 (scenes must exist) and Phase 4 (UI to trigger it)
- **Phase 6** (Assembly) depends on Phase 5 (assets must exist)
- **Phase 7** (Variations) depends on Phase 5 (generation infrastructure) but is independent of Phase 6

```
Phase 1 → Phase 2 → Phase 3 (AI Splitting)  ──┐
                   → Phase 4 (Timeline UI)   ──┤
                                                ├→ Phase 5 (Batch Gen) → Phase 6 (Assembly)
                                                └→ Phase 7 (Variations, after Phase 5)
```

## Verification Steps

- [ ] Create a project, create a storyboard, paste a 60-second script → AI returns 4-8 scenes
- [ ] Edit a scene's visual prompt, reorder scenes, add/delete scenes → all persist correctly
- [ ] "Generate All" with budget image provider → all scenes show progress → all get assets
- [ ] Regenerate one scene → only that scene's asset changes
- [ ] "Assemble" with crossfade + captions → output video has scenes in order with transitions and narration-based captions
- [ ] Generate 3 variations for a scene → comparison grid shows 3 options → pick winner → scene updates
