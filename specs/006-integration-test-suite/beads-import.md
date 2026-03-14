# Integration Test Suite - Beads

**Feature**: 006-integration-test-suite
**Generated**: 2026-03-12
**Source**: specs/006-integration-test-suite/tasks.md

## Root Epic

- **ID**: C4-005
- **Title**: Integration Test Suite — End-to-End Workflow Validation
- **Type**: epic
- **Priority**: 1
- **Description**: Add ~163 integration tests across backend and iOS, taking coverage from <5% to ~70% (backend) and 0% to ~50% (iOS). All tests use mocked providers — zero external API calls, <30s runtime.

## Epics

### Phase 1 — Setup: Backend Test Infrastructure
- **ID**: C4-005.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 2 — US1: Backend Happy Path Tests
- **ID**: C4-005.2
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Blocks**: Phase 3
- **Tasks**: 8

### Phase 3 — US2: Backend Error Path Tests
- **ID**: C4-005.3
- **Type**: epic
- **Priority**: 1
- **Tasks**: 6

### Phase 4 — US2: Worker Integration Tests
- **ID**: C4-005.4
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 5 — US3: iOS TCA Reducer Tests
- **ID**: C4-005.5
- **Type**: epic
- **Priority**: 2
- **Tasks**: 4

### Phase 6 — US4: iOS APIClient & WebSocket Tests
- **ID**: C4-005.6
- **Type**: epic
- **Priority**: 2
- **Tasks**: 3

## Tasks

### Phase 1 — Setup: Backend Test Infrastructure

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Extend mock DB with all tables + register all route plugins | `backend/tests/setup.js` | C4-005.1.1 |
| T002 | Create test factory helpers | `backend/tests/helpers.js` | C4-005.1.2 |
| T003 | Create mock provider modules (openai, fal, deepgram, creatomate) | `backend/tests/mocks/` | C4-005.1.3 |
| T004 | Add coverage reporting to test script | `backend/package.json` | C4-005.1.4 |

### Phase 2 — US1: Backend Happy Path Tests

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T005 | Projects CRUD tests (5 tests) | `backend/tests/routes/projects.test.js` | C4-005.2.1 |
| T006 | Storyboards CRUD + split + generate + assemble tests (15 tests) | `backend/tests/routes/storyboards.test.js` | C4-005.2.2 |
| T007 | Scenes CRUD + reorder tests (8 tests) | `backend/tests/routes/scenes.test.js` | C4-005.2.3 |
| T008 | Assets list + get + delete tests (5 tests) | `backend/tests/routes/assets.test.js` | C4-005.2.4 |
| T009 | Credits balance + history + allocate tests (5 tests) | `backend/tests/routes/credits.test.js` | C4-005.2.5 |
| T010 | Notes CRUD tests (5 tests) | `backend/tests/routes/notes.test.js` | C4-005.2.6 |
| T011 | Generation endpoint tests (6 tests) | `backend/tests/routes/generate.test.js` | C4-005.2.7 |
| T012 | Assembly endpoint tests (3 tests) | `backend/tests/routes/assemble.test.js` | C4-005.2.8 |

### Phase 3 — US2: Backend Error Path Tests

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T013 | 404 tests for all resource types | `backend/tests/routes/*.test.js` | C4-005.3.1 |
| T014 | 400 tests for malformed/missing input | `backend/tests/routes/*.test.js` | C4-005.3.2 |
| T015 | 402 tests for insufficient credits | `backend/tests/routes/generate.test.js` | C4-005.3.3 |
| T016 | Concurrent access + partial failure tests | `backend/tests/routes/storyboards.test.js` | C4-005.3.4 |
| T017 | Credit refund verification tests | `backend/tests/routes/credits.test.js` | C4-005.3.5 |
| T018 | Empty state edge case tests | `backend/tests/routes/*.test.js` | C4-005.3.6 |

### Phase 4 — US2: Worker Integration Tests

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T019 | Image generation worker success/failure tests | `backend/tests/workers/generation.test.js` | C4-005.4.1 |
| T020 | Video generation worker tests | `backend/tests/workers/generation.test.js` | C4-005.4.2 |
| T021 | Batch generation worker tests | `backend/tests/workers/generation.test.js` | C4-005.4.3 |
| T022 | Assembly worker tests | `backend/tests/workers/assembly.test.js` | C4-005.4.4 |

### Phase 5 — US3: iOS TCA Reducer Tests

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T023 | StoryboardReducer tests (15 tests) | `ios/.../StoryboardFeature/Tests/.../StoryboardReducerTests.swift` | C4-005.5.1 |
| T024 | ProjectReducer tests (5 tests) | `ios/.../ProjectFeature/Tests/.../ProjectReducerTests.swift` | C4-005.5.2 |
| T025 | CreditReducer tests (3 tests) | `ios/.../CreditFeature/Tests/.../CreditReducerTests.swift` | C4-005.5.3 |
| T026 | GenerateReducer tests (5 tests) | `ios/.../GenerateFeature/Tests/.../GenerateReducerTests.swift` | C4-005.5.4 |

### Phase 6 — US4: iOS APIClient & WebSocket Tests

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T027 | Create MockURLProtocol helper | `ios/.../CoreKit/Tests/CoreKitTests/MockURLProtocol.swift` | C4-005.6.1 |
| T028 | APIClient URL/encoding/decoding tests (20 tests) | `ios/.../CoreKit/Tests/CoreKitTests/APIClientTests.swift` | C4-005.6.2 |
| T029 | WebSocketClient message parsing + reconnection tests (8 tests) | `ios/.../CoreKit/Tests/CoreKitTests/WebSocketClientTests.swift` | C4-005.6.3 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Setup | 4 | 1 | C4-005.1 |
| 2: Happy Paths (MVP) | 8 | 1 | C4-005.2 |
| 3: Error Paths | 6 | 1 | C4-005.3 |
| 4: Worker Tests | 4 | 1 | C4-005.4 |
| 5: iOS Reducers | 4 | 2 | C4-005.5 |
| 6: iOS Clients | 3 | 2 | C4-005.6 |
| **Total** | **29** | | |

## Dependency Graph

```
Phase 1: Setup (C4-005.1)
    |
Phase 2: Happy Paths (C4-005.2, MVP)     Phase 5: iOS Reducers (C4-005.5)  [parallel]
    |                                      Phase 6: iOS Clients (C4-005.6)   [parallel]
    |
Phase 3: Error Paths (C4-005.3)  Phase 4: Workers (C4-005.4)  [parallel]
```

Backend track: 1 → 2 → 3,4 (parallel)
iOS track: 5,6 (parallel, independent of backend)

## Improvements

Improvements (Level 4: C4-005.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered. See
SKILL.md "Improvements (Post-Planning)" section for the workflow.
