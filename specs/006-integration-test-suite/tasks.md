# Tasks: Integration Test Suite

**Input**: Design documents from `/specs/006-integration-test-suite/`
**Epic**: `C4-005`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-005.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1, US2, etc.)

## Phase 1: Backend Test Infrastructure

**Purpose**: Extend existing test harness to support all route groups, add factories and mocks

- [ ] T001 [US1] Extend mock DB in `backend/tests/setup.js` with storyboards, scenes, assets, style_presets, prompt_history tables and register all route plugins (storyboards, scenes, notes, styles, prompts)
- [ ] T002 [US1] Create test factory helpers in `backend/tests/helpers.js` — `createTestProject()`, `createTestStoryboard()`, `createTestScene()`, `createTestAsset()`, `seedCredits(amount)`
- [ ] T003 [P] [US1] Create mock provider modules in `backend/tests/mocks/` — openai (canned scene splits), fal (test image URLs), deepgram (test SRT), creatomate (test video URL)
- [ ] T004 [US1] Add coverage reporting to `backend/package.json` test script (`--experimental-test-coverage` or c8)

**Checkpoint**: `npm test` runs with extended harness, all existing tests still pass

---

## Phase 2: Backend Happy Path Tests

**Purpose**: Test every API endpoint with valid input and verify correct responses

- [ ] T005 [P] [US1] Projects CRUD tests (5 tests) in `backend/tests/routes/projects.test.js`
- [ ] T006 [P] [US1] Storyboards CRUD + split + generate + assemble + variations tests (15 tests) in `backend/tests/routes/storyboards.test.js`
- [ ] T007 [P] [US1] Scenes CRUD + reorder tests (8 tests) in `backend/tests/routes/scenes.test.js`
- [ ] T008 [P] [US1] Assets list + get + delete tests (5 tests) in `backend/tests/routes/assets.test.js`
- [ ] T009 [P] [US1] Credits balance + history + allocate tests (5 tests) in `backend/tests/routes/credits.test.js`
- [ ] T010 [P] [US1] Notes CRUD tests (5 tests) in `backend/tests/routes/notes.test.js`
- [ ] T011 [P] [US1] Generation endpoint tests — image, video, extend (6 tests) in `backend/tests/routes/generate.test.js`
- [ ] T012 [P] [US1] Assembly endpoint tests (3 tests) in `backend/tests/routes/assemble.test.js`

**Checkpoint**: 52+ happy path tests passing, all routes covered

---

## Phase 3: Backend Error Path Tests

**Purpose**: Verify correct error handling for all invalid/edge-case input

- [ ] T013 [P] [US2] 404 tests for nonexistent project/storyboard/scene/asset IDs in `backend/tests/routes/*.test.js`
- [ ] T014 [P] [US2] 400 tests for malformed input, missing required fields, invalid enums in `backend/tests/routes/*.test.js`
- [ ] T015 [P] [US2] 402 tests for insufficient credits on generation/assembly in `backend/tests/routes/generate.test.js` and `assemble.test.js`
- [ ] T016 [US2] Concurrent access and partial failure tests — two batch generates on same storyboard, 3-of-5 scene failures in `backend/tests/routes/storyboards.test.js`
- [ ] T017 [US2] Credit refund verification tests — verify refund on failed generation in `backend/tests/routes/credits.test.js`
- [ ] T018 [P] [US2] Empty state edge case tests — empty project, storyboard with no scenes, scene with no asset in `backend/tests/routes/*.test.js`

**Checkpoint**: 40+ error path tests passing, all error categories covered

---

## Phase 4: Worker Integration Tests

**Purpose**: Test BullMQ worker job processing with mocked AI providers

- [ ] T019 [P] [US2] Image generation worker tests — success → asset created, scene updated, credits deducted; failure → asset failed, credits refunded, WS error broadcast in `backend/tests/workers/generation.test.js`
- [ ] T020 [P] [US2] Video generation worker tests — success → asset + thumbnail created in `backend/tests/workers/generation.test.js`
- [ ] T021 [US2] Batch generation worker tests — all scenes get assets, progress broadcasts sent in `backend/tests/workers/generation.test.js`
- [ ] T022 [US2] Assembly worker tests — clips combined, SRT generated, output asset created in `backend/tests/workers/assembly.test.js`

**Checkpoint**: 15+ worker tests passing, all job types covered

---

## Phase 5: iOS TCA Reducer Tests

**Purpose**: Test every reducer with TCA TestStore and mocked dependencies

- [ ] T023 [P] [US3] StoryboardReducer tests — split script, add/delete/reorder scenes, generate all, assemble, variations (15 tests) in `ios/.../StoryboardFeature/Tests/StoryboardFeatureTests/StoryboardReducerTests.swift`
- [ ] T024 [P] [US3] ProjectReducer tests — load, create, delete (5 tests) in `ios/.../ProjectFeature/Tests/ProjectFeatureTests/ProjectReducerTests.swift`
- [ ] T025 [P] [US3] CreditReducer tests — load balance, load history (3 tests) in `ios/.../CreditFeature/Tests/CreditFeatureTests/CreditReducerTests.swift`
- [ ] T026 [P] [US3] GenerateReducer tests — image generate, video generate, variations (5 tests) in `ios/.../GenerateFeature/Tests/GenerateFeatureTests/GenerateReducerTests.swift`

**Checkpoint**: 28 reducer tests passing across all feature packages

---

## Phase 6: iOS APIClient & WebSocket Tests

**Purpose**: Verify network client URL construction, encoding, decoding, and WebSocket handling

- [ ] T027 [US4] Create MockURLProtocol helper in `ios/.../CoreKit/Tests/CoreKitTests/MockURLProtocol.swift`
- [ ] T028 [US4] APIClient tests — verify URL construction, HTTP methods, request encoding, response decoding for all endpoints (20 tests) in `ios/.../CoreKit/Tests/CoreKitTests/APIClientTests.swift`
- [ ] T029 [US4] WebSocketClient tests — verify message parsing, filtering by jobId/sceneId, reconnection logic (8 tests) in `ios/.../CoreKit/Tests/CoreKitTests/WebSocketClientTests.swift`

**Checkpoint**: 28 iOS client tests passing

---

## Dependencies

- Phase 1 (Setup) → blocks Phase 2, 3, 4
- Phase 2 (Happy Paths) → blocks Phase 3 (error tests build on happy path patterns)
- Phase 3, Phase 4 can run in parallel after Phase 2
- Phase 5, Phase 6 are independent of all backend phases — can start immediately
- Phase 5 and Phase 6 can run in parallel with each other
- T027 → blocks T028, T029

## Parallel Opportunities

- **Backend track** (Phases 1-4) and **iOS track** (Phases 5-6) are fully parallel
- Within Phase 2: all 8 route test files (T005-T012) can be written in parallel
- Within Phase 3: T013, T014, T015, T018 can run in parallel
- Within Phase 5: all 4 reducer test tasks (T023-T026) can run in parallel
- T028 and T029 can run in parallel after T027
