# API Contract Tests - Beads

**Feature**: 007-api-contract-tests
**Generated**: 2026-03-12
**Source**: specs/007-api-contract-tests/tasks.md

## Root Epic

- **ID**: C4-006
- **Title**: API Contract Tests — Verify Frontend/iOS Types Match Backend Responses
- **Type**: epic
- **Priority**: 1
- **Description**: Shared Zod schemas defining every C4 API response shape, contract tests using supertest, and JSON fixture export for iOS XCTest Codable verification. Catches iOS-backend mismatches at CI time.

## Epics

### Phase 1 — Setup: Test Infrastructure
- **ID**: C4-006.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 2 — US1: Storyboard & Scene Contracts
- **ID**: C4-006.2
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Tasks**: 6

### Phase 3 — US2: Style Preset & Prompt History Contracts
- **ID**: C4-006.3
- **Type**: epic
- **Priority**: 2
- **Tasks**: 5

### Phase 4 — US3: Project & Generation Contracts
- **ID**: C4-006.4
- **Type**: epic
- **Priority**: 2
- **Tasks**: 5

### Phase 5 — Polish: CI Integration
- **ID**: C4-006.5
- **Type**: epic
- **Priority**: 3
- **Depends**: US1, US2, US3
- **Tasks**: 3

## Tasks

### Phase 1 — Setup

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Install zod + supertest devDependencies | `backend/package.json` | C4-006.1.1 |
| T002 | Create test app factory | `backend/tests/helpers/app.js` | C4-006.1.2 |
| T003 | Create seed helpers | `backend/tests/helpers/seeds.js` | C4-006.1.3 |
| T004 | Create fixture export utility | `backend/tests/helpers/export-fixtures.js` | C4-006.1.4 |

### Phase 2 — US1: Storyboard & Scene Contracts

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T005 | Zod schemas for storyboard responses | `backend/types/contracts/storyboards.js` | C4-006.2.1 |
| T006 | Zod schemas for scene responses | `backend/types/contracts/scenes.js` | C4-006.2.2 |
| T007 | Contract tests for storyboard endpoints | `backend/tests/contracts/storyboards.test.js` | C4-006.2.3 |
| T008 | Contract tests for scene endpoints | `backend/tests/contracts/scenes.test.js` | C4-006.2.4 |
| T009 | Export storyboard & scene JSON fixtures | `backend/tests/fixtures/` | C4-006.2.5 |
| T010 | iOS XCTest fixture decode tests (Storyboard, Scene) | `ios/.../CoreKitTests/` | C4-006.2.6 |

### Phase 3 — US2: Style Preset & Prompt History Contracts

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T011 | Zod schemas for style preset responses | `backend/types/contracts/styles.js` | C4-006.3.1 |
| T012 | Zod schemas for prompt history responses | `backend/types/contracts/prompts.js` | C4-006.3.2 |
| T013 | Contract tests for style endpoints | `backend/tests/contracts/styles.test.js` | C4-006.3.3 |
| T014 | Contract tests for prompt endpoints | `backend/tests/contracts/prompts.test.js` | C4-006.3.4 |
| T015 | Export style/prompt fixtures + iOS decode tests | `backend/tests/fixtures/` + `ios/.../CoreKitTests/` | C4-006.3.5 |

### Phase 4 — US3: Project & Generation Contracts

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T016 | Zod schemas for project/asset/credit/note responses | `backend/types/contracts/` | C4-006.4.1 |
| T017 | Zod schemas for generation responses | `backend/types/contracts/generate.js` | C4-006.4.2 |
| T018 | Contract tests for project/asset/credit/note endpoints | `backend/tests/contracts/` | C4-006.4.3 |
| T019 | Contract tests for generation endpoints | `backend/tests/contracts/generate.test.js` | C4-006.4.4 |
| T020 | Export remaining fixtures + iOS decode tests | `backend/tests/fixtures/` + `ios/.../CoreKitTests/` | C4-006.4.5 |

### Phase 5 — Polish: CI Integration

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T021 | Add test:contracts npm script + CI wiring | `backend/package.json` | C4-006.5.1 |
| T022 | Add export:fixtures npm script | `backend/package.json` | C4-006.5.2 |
| T023 | Verify iOS fixture tests in Xcode scheme | `ios/C4.xcodeproj` | C4-006.5.3 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Setup | 4 | 1 | C4-006.1 |
| 2: US1 — Storyboard & Scene (MVP) | 6 | 1 | C4-006.2 |
| 3: US2 — Style & Prompt | 5 | 2 | C4-006.3 |
| 4: US3 — Project & Generation | 5 | 2 | C4-006.4 |
| 5: Polish — CI Integration | 3 | 3 | C4-006.5 |
| **Total** | **23** | | |

## Dependency Graph

```
Phase 1: Setup (C4-006.1)
    |
    +--blocks--> Phase 2: US1 (C4-006.2, MVP)
    +--blocks--> Phase 3: US2 (C4-006.3)        [parallel]
    +--blocks--> Phase 4: US3 (C4-006.4)        [parallel]
                    |           |           |
                    +-----+-----+-----+-----+
                          |
                  Phase 5: Polish (C4-006.5)
```

## Improvements

Improvements (Level 4: C4-006.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered.
