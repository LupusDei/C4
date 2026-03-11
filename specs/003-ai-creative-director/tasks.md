# Tasks: AI Creative Director — Trend-Aware Prompt Intelligence

**Input**: Design documents from `/specs/003-ai-creative-director/`
**Epic**: `C4-003`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-003.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1-US5)

## Phase 1: Setup

**Purpose**: Database schema, seed data, and data models

- [ ] T001 Create style_presets, prompt_history tables and add default_style_preset_id to projects in `backend/src/db/migrations/003_creative_director.js`
- [ ] T002 [P] Create StylePreset model in `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/StylePreset.swift`
- [ ] T003 [P] Create PromptHistory model in `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/PromptHistory.swift`

---

## Phase 2: Foundational

**Purpose**: Backend CRUD routes, seed data, and iOS API client wiring — blocks all user stories

- [ ] T004 Create style preset routes (list with category filter, get, create custom, update, delete) in `backend/src/routes/styles.js`
- [ ] T005 Create prompt history routes (list paginated/searchable, get, delete) in `backend/src/routes/prompts.js`
- [ ] T006 Seed 30+ curated style presets with categories in `backend/src/db/seeds/001_style_presets.js`
- [ ] T007 Register styles and prompts routes in `backend/src/server.js`
- [ ] T008 Add style and prompt history API methods to `ios/C4/Packages/CoreKit/Sources/CoreKit/APIClient.swift`
- [ ] T009 Create PromptFeature SPM package scaffold in `ios/C4/Packages/PromptFeature/`

**Checkpoint**: CRUD works end-to-end — user stories can begin

---

## Phase 3: US1 - Smart Prompt Enhancement (Priority: P1, MVP)

**Goal**: User types rough prompt, AI enhances it with provider-aware optimization
**Independent Test**: POST rough prompt + provider, verify enhanced prompt returns with provider-specific terminology

- [ ] T010 [US1] Create prompt-enhancer service with Claude API call and provider templates in `backend/src/services/prompt-enhancer.js`
- [ ] T011 [US1] Add POST `/api/prompts/enhance` endpoint in `backend/src/routes/prompts.js`
- [ ] T012 [US1] Create PromptEnhancerView with text input, Enhance button, and before/after display in `PromptFeature/Sources/PromptFeature/PromptEnhancerView.swift`
- [ ] T013 [US1] Create PromptEnhancerReducer with enhance action and API effect in `PromptFeature/Sources/PromptFeature/PromptEnhancerReducer.swift`
- [ ] T014 [US1] Integrate PromptEnhancerView into ImageGenerateView replacing plain TextField in `GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`
- [ ] T015 [US1] Integrate PromptEnhancerView into VideoGenerateView in `GenerateFeature/Sources/GenerateFeature/VideoGenerateView.swift`

**Checkpoint**: US1 independently functional — prompts can be enhanced with provider awareness

---

## Phase 4: US2 - Visual Style Library (Priority: P1)

**Goal**: Gallery of style presets that modify prompts, with custom styles and project lock
**Independent Test**: Browse presets, select one, verify prompt is modified. Save custom style. Set project lock.

- [ ] T016 [US2] Create StylePickerView with gallery grid and category tabs in `PromptFeature/Sources/PromptFeature/StylePickerView.swift`
- [ ] T017 [US2] Create StylePickerReducer for loading presets and applying selection in `PromptFeature/Sources/PromptFeature/StylePickerReducer.swift`
- [ ] T018 [US2] Add style extraction endpoint using Claude (extract style from full prompt) in `backend/src/routes/styles.js`
- [ ] T019 [US2] Add "Save as Style" action to asset preview flow in `GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`
- [ ] T020 [US2] Add project style lock setting to ProjectDetailView in `ProjectFeature/Sources/ProjectFeature/ProjectDetailView.swift`
- [ ] T021 [US2] Wire style picker into ImageGenerateView and VideoGenerateView in `GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`
- [ ] T022 [US2] Update project update route to accept default_style_preset_id in `backend/src/routes/projects.js`

**Checkpoint**: US2 independently functional — full style library with custom styles and project lock

---

## Phase 5: US3 - Prompt History & Remix (Priority: P1)

**Goal**: Automatic prompt tracking, searchable history, and remix variations
**Independent Test**: Generate 3 images → history shows 3 entries with thumbnails → Remix produces meaningful variation

- [ ] T023 [US3] Add auto-recording of prompt history to generation routes in `backend/src/routes/generate.js`
- [ ] T024 [US3] Add `kept` tracking — update on regeneration in `backend/src/workers/generation.js`
- [ ] T025 [US3] Add POST `/api/prompts/remix` endpoint with Claude variation in `backend/src/routes/prompts.js`
- [ ] T026 [US3] Create PromptHistoryView with searchable list and thumbnails in `PromptFeature/Sources/PromptFeature/PromptHistoryView.swift`
- [ ] T027 [US3] Create PromptHistoryReducer with load, search, tap-to-load, and remix actions in `PromptFeature/Sources/PromptFeature/PromptHistoryReducer.swift`
- [ ] T028 [US3] Add history access (clock icon) to generation screens in `GenerateFeature/Sources/GenerateFeature/ImageGenerateView.swift`

**Checkpoint**: US3 independently functional — prompt history and remix work end-to-end

---

## Phase 6: US4 - Content Intelligence (Priority: P2, Deferred)

**Goal**: Niche-aware suggestions and series idea generation
**Independent Test**: Set niche to "tech" → suggestions panel shows tech ideas → series generator produces 5-10 episodes

- [ ] T029 [US4] Add niche field to projects table migration in `backend/src/db/migrations/003_creative_director.js` (or new migration)
- [ ] T030 [US4] Add POST `/api/prompts/suggest` endpoint with niche-aware Claude suggestions in `backend/src/routes/prompts.js`
- [ ] T031 [US4] Add POST `/api/prompts/series` endpoint for series ideation in `backend/src/routes/prompts.js`
- [ ] T032 [US4] Create ContentSuggestionsView with niche selector and suggestion cards in `PromptFeature/Sources/PromptFeature/ContentSuggestionsView.swift`
- [ ] T033 [US4] Create SeriesGeneratorView with theme input and episode cards in `PromptFeature/Sources/PromptFeature/SeriesGeneratorView.swift`
- [ ] T034 [US4] Add content intelligence reducers in `PromptFeature/Sources/PromptFeature/ContentIntelligenceReducer.swift`

**Checkpoint**: US4 independently functional — niche suggestions and series generation work

---

## Phase 7: US5 - Learning Loop (Priority: P2, Deferred)

**Goal**: Generation analytics and "More Like This" functionality
**Independent Test**: Generate 5 assets, keep 3, regenerate 2 → analytics shows ratios → "More Like This" produces similar variation

- [ ] T035 [US5] Add analytics aggregation queries (keep/regenerate by provider, style) in `backend/src/routes/prompts.js`
- [ ] T036 [US5] Add POST `/api/prompts/more-like-this` endpoint in `backend/src/routes/prompts.js`
- [ ] T037 [US5] Create GenerationAnalyticsView with stats display in `PromptFeature/Sources/PromptFeature/GenerationAnalyticsView.swift`
- [ ] T038 [US5] Add "More Like This" button to asset preview in `ProjectFeature/Sources/ProjectFeature/AssetPreviewView.swift`
- [ ] T039 [US5] Add learning loop reducers in `PromptFeature/Sources/PromptFeature/LearningLoopReducer.swift`

---

## Dependencies

- Setup (Phase 1) → Foundational (Phase 2) → blocks all user stories
- Phase 3 (Enhancement) and Phase 4 (Style Library) can run in parallel after Foundational
- Phase 5 (History) depends on Phase 3 (needs enhancement data to record)
- Phase 6 (Content Intelligence) depends on Phase 2 only — independent of Phases 3-5
- Phase 7 (Learning Loop) depends on Phase 5 (needs history data)

## Parallel Opportunities

- T002, T003 within Phase 1 (different files)
- T004, T005, T006 within Phase 2 (different files)
- Phase 3 and Phase 4 entirely (AI service vs style UI)
- T016, T017 within Phase 4 (independent view + reducer)
- T026, T027 within Phase 5 (independent view + reducer)
- Phase 6 and Phase 7 can run in parallel (independent P2 features)
