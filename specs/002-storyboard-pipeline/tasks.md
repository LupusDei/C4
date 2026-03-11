# Tasks: Script-to-Scene Storyboard Pipeline

**Input**: Design documents from `/specs/002-storyboard-pipeline/`
**Epic**: `C4-002`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-002.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1-US5)

## Phase 1: Setup

**Purpose**: Database schema and data models

- [ ] T001 Create storyboards and scenes migration in `backend/src/db/migrations/002_storyboards.js`
- [ ] T002 [P] Create Storyboard model in `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/Storyboard.swift`
- [ ] T003 [P] Create Scene model in `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/Scene.swift`

---

## Phase 2: Foundational

**Purpose**: Backend CRUD routes and iOS API client wiring — blocks all user stories

- [ ] T004 Create storyboard CRUD routes (create, list by project, get, update, delete) in `backend/src/routes/storyboards.js`
- [ ] T005 Add scene CRUD routes (create, list by storyboard, get, update, delete, reorder) in `backend/src/routes/storyboards.js`
- [ ] T006 Register storyboard routes in `backend/src/server.js`
- [ ] T007 Add storyboard/scene API methods to `ios/C4/Packages/CoreKit/Sources/CoreKit/APIClient.swift`
- [ ] T008 Create StoryboardFeature SPM package scaffold in `ios/C4/Packages/StoryboardFeature/`

**Checkpoint**: CRUD works end-to-end — user stories can begin

---

## Phase 3: US1 - Script Input & AI Scene Splitting (Priority: P1, MVP)

**Goal**: User pastes a script, AI returns structured scenes
**Independent Test**: POST script text, verify AI returns 4-8 scenes with narration, prompts, and durations

- [ ] T009 [US1] Create scene-splitter service with LLM call in `backend/src/services/scene-splitter.js`
- [ ] T010 [US1] Add POST `/api/storyboards/:id/split` route in `backend/src/routes/storyboards.js`
- [ ] T011 [US1] Create ScriptInputView with text editor and "Split" button in `StoryboardFeature/Sources/StoryboardFeature/ScriptInputView.swift`
- [ ] T012 [US1] Add script splitting action/effect to StoryboardReducer in `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift`

**Checkpoint**: US1 independently functional — scripts can be split into scenes

---

## Phase 4: US2 - Storyboard Timeline & Scene Card UI (Priority: P1)

**Goal**: Visual timeline for managing scenes with drag-and-drop
**Independent Test**: Open storyboard with 6 scenes, verify timeline renders, drag to reorder, add/delete scenes

- [ ] T013 [US2] Create SceneCardView component in `StoryboardFeature/Sources/StoryboardFeature/SceneCardView.swift`
- [ ] T014 [US2] Create StoryboardTimelineView with horizontal ScrollView of cards in `StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift`
- [ ] T015 [US2] Add drag-and-drop reorder and add/delete scene actions to StoryboardReducer in `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift`
- [ ] T016 [US2] Create StoryboardListView (list per project) in `StoryboardFeature/Sources/StoryboardFeature/StoryboardListView.swift`
- [ ] T017 [US2] Wire StoryboardListView into ProjectDetailView in `ios/C4/Packages/ProjectFeature/Sources/ProjectFeature/ProjectDetailView.swift`
- [ ] T018 [US2] Add StoryboardFeature dependency to C4App in `ios/C4/C4App.swift`

**Checkpoint**: US2 independently functional — full scene management UI

---

## Phase 5: US3 - Batch Generation (Priority: P1)

**Goal**: "Generate All" queues generation for every scene, with per-scene progress
**Independent Test**: Storyboard with 5 scenes → Generate All → 5 jobs queued → progress on each card → assets attached

- [ ] T019 [US3] Add POST `/api/storyboards/:id/generate` batch endpoint in `backend/src/routes/storyboards.js`
- [ ] T020 [US3] Update generation worker to accept sceneId and update scene asset_id on completion in `backend/src/workers/generation.js`
- [ ] T021 [US3] Add scene-level WebSocket progress broadcasts (storyboardId + sceneId) in `backend/src/plugins/websocket.js`
- [ ] T022 [US3] Add "Generate All" UI with provider picker to StoryboardTimelineView in `StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift`
- [ ] T023 [US3] Add per-scene progress indicators driven by WebSocket to SceneCardView in `StoryboardFeature/Sources/StoryboardFeature/SceneCardView.swift`
- [ ] T024 [US3] Add batch generation and per-scene regeneration effects to StoryboardReducer in `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift`

**Checkpoint**: US3 independently functional — batch generation works end-to-end

---

## Phase 6: US4 - One-Click Assembly (Priority: P2)

**Goal**: Assemble all scene assets into a single video with script-based captions
**Independent Test**: 4 scenes with video assets → Assemble with crossfade + captions → output video in correct order with narration captions

- [ ] T025 [US4] Add POST `/api/storyboards/:id/assemble` route in `backend/src/routes/storyboards.js`
- [ ] T026 [US4] Create captionsFromScript() function in `backend/src/services/captions.js` — narration text + cumulative durations → SRT
- [ ] T027 [US4] Modify assembly service to accept SRT content directly (not just Deepgram) in `backend/src/services/assembly.js`
- [ ] T028 [US4] Add "Assemble" button with transition/caption options to StoryboardTimelineView in `StoryboardFeature/Sources/StoryboardFeature/StoryboardTimelineView.swift`
- [ ] T029 [US4] Add assembly progress and result display to StoryboardReducer in `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift`

**Checkpoint**: US4 independently functional — storyboard → assembled video

---

## Phase 7: US5 - Scene Variations (Priority: P2)

**Goal**: Generate 2-3 alternatives per scene and pick the best
**Independent Test**: Scene with 1 asset → Generate 3 variations → comparison grid → pick winner → asset updates

- [ ] T030 [US5] Add POST `/api/storyboards/:storyboardId/scenes/:sceneId/variations` endpoint in `backend/src/routes/storyboards.js`
- [ ] T031 [US5] Add prompt perturbation logic (AI rewrites prompt N ways) to scene-splitter service in `backend/src/services/scene-splitter.js`
- [ ] T032 [US5] Create SceneVariationsView with comparison grid in `StoryboardFeature/Sources/StoryboardFeature/SceneVariationsView.swift`
- [ ] T033 [US5] Add variation generation and winner selection to StoryboardReducer in `StoryboardFeature/Sources/StoryboardFeature/StoryboardReducer.swift`

---

## Dependencies

- Setup (Phase 1) → Foundational (Phase 2) → blocks all user stories
- Phase 3 (AI Splitting) and Phase 4 (Timeline UI) can run in parallel after Foundational
- Phase 5 (Batch Gen) depends on Phase 3 + Phase 4
- Phase 6 (Assembly) depends on Phase 5
- Phase 7 (Variations) depends on Phase 5, independent of Phase 6

## Parallel Opportunities

- T002, T003 within Phase 1 (different files)
- Phase 3 and Phase 4 entirely (backend AI vs iOS UI)
- T013, T014, T016 within Phase 4 (independent view components)
- T019, T020, T021 within Phase 5 have some parallelism (route vs worker vs websocket)
- Phase 7 can run in parallel with Phase 6
