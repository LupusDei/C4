# Tasks: API Contract Tests

**Input**: Design documents from `/specs/007-api-contract-tests/`
**Epic**: `C4-006`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-006.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1, US2, US3)

## Phase 1: Setup

**Purpose**: Install dependencies and create test infrastructure

- [ ] T001 Install zod and supertest as devDependencies in `backend/package.json`
- [ ] T002 Create test app factory (`backend/tests/helpers/app.js`) — builds Fastify instance with test DB config, runs migrations, registers all routes
- [ ] T003 Create seed helpers (`backend/tests/helpers/seeds.js`) — `createTestProject()`, `createTestStoryboard()`, `createTestScene()`, `seedCredits(amount)`, `createTestStylePreset()`, `createTestPromptHistory()`
- [ ] T004 Create fixture export utility (`backend/tests/helpers/export-fixtures.js`) — validates response JSON through Zod schema, writes to `backend/tests/fixtures/`

**Checkpoint**: Test infrastructure ready — contract tests can begin

---

## Phase 2: US1 - Storyboard & Scene Contracts (Priority: P1, MVP)

**Goal**: Full contract coverage for the highest-bug-rate endpoints
**Independent Test**: `node --test backend/tests/contracts/storyboards.test.js backend/tests/contracts/scenes.test.js`

- [ ] T005 [US1] Zod schemas for storyboard responses in `backend/types/contracts/storyboards.js` — list, create, update, delete, splitScript, assembly, variations
- [ ] T006 [P] [US1] Zod schemas for scene responses in `backend/types/contracts/scenes.js` — list, create, update, delete, reorder, batch generate
- [ ] T007 [US1] Contract tests for storyboard endpoints in `backend/tests/contracts/storyboards.test.js` — 10+ tests covering CRUD, split, assemble, variations
- [ ] T008 [P] [US1] Contract tests for scene endpoints in `backend/tests/contracts/scenes.test.js` — 8+ tests covering CRUD, reorder, batch generation
- [ ] T009 [US1] Export storyboard & scene JSON fixtures to `backend/tests/fixtures/storyboards/` and `backend/tests/fixtures/scenes/`
- [ ] T010 [US1] iOS XCTest fixture decode tests in `ios/C4/Packages/CoreKit/Tests/CoreKitTests/StoryboardContractTests.swift` and `SceneContractTests.swift`

**Checkpoint**: US1 independently functional — storyboard/scene mismatches caught at CI time

---

## Phase 3: US2 - Style Preset & Prompt History Contracts (Priority: P2)

**Goal**: Contract coverage for style and prompt APIs
**Independent Test**: `node --test backend/tests/contracts/styles.test.js backend/tests/contracts/prompts.test.js`

- [ ] T011 [US2] Zod schemas for style preset responses in `backend/types/contracts/styles.js` — CRUD, search, extract
- [ ] T012 [P] [US2] Zod schemas for prompt history responses in `backend/types/contracts/prompts.js` — history, enhance, remix
- [ ] T013 [US2] Contract tests for style endpoints in `backend/tests/contracts/styles.test.js` — 6+ tests
- [ ] T014 [P] [US2] Contract tests for prompt endpoints in `backend/tests/contracts/prompts.test.js` — 5+ tests
- [ ] T015 [US2] Export style & prompt JSON fixtures; iOS decode tests in `ios/C4/Packages/CoreKit/Tests/CoreKitTests/StyleContractTests.swift` and `PromptContractTests.swift`

---

## Phase 4: US3 - Project & Generation Contracts (Priority: P2)

**Goal**: Contract coverage for project, generation, credit, asset, and note APIs
**Independent Test**: `node --test backend/tests/contracts/projects.test.js backend/tests/contracts/generate.test.js`

- [ ] T016 [US3] Zod schemas for project, asset, credit, and note responses in `backend/types/contracts/projects.js`, `assets.js`, `credits.js`, `notes.js`
- [ ] T017 [P] [US3] Zod schemas for generation responses in `backend/types/contracts/generate.js` — image gen, video gen, extend, cost estimation
- [ ] T018 [US3] Contract tests for project/asset/credit/note endpoints in `backend/tests/contracts/projects.test.js`, `assets.test.js`, `credits.test.js`, `notes.test.js` — 15+ tests total
- [ ] T019 [P] [US3] Contract tests for generation endpoints in `backend/tests/contracts/generate.test.js` — 6+ tests
- [ ] T020 [US3] Export all remaining JSON fixtures; iOS decode tests for Project, Asset, Credit, Note, GenerationJob models

---

## Phase 5: Polish & CI Integration

- [ ] T021 Add `test:contracts` npm script and wire into CI (`backend/package.json`)
- [ ] T022 [P] Add `export:fixtures` npm script that runs all contract tests and exports fixtures
- [ ] T023 Verify iOS fixture tests run in Xcode scheme; add to CI if applicable

---

## Dependencies

- Setup (Phase 1) → blocks all contract phases (2, 3, 4)
- US1 (Phase 2), US2 (Phase 3), US3 (Phase 4) can run in parallel after Setup
- Polish (Phase 5) depends on all US phases complete

## Parallel Opportunities

- Tasks marked [P] within a phase can run simultaneously (they touch different schema/test files)
- After Phase 1, all three US phases can run in parallel across different agents
- iOS fixture tests can be written concurrently with backend contract tests within each phase
