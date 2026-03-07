# C4 Content Creation Coordinator - Beads

**Feature**: 001-c4-content-creation-coordinator
**Generated**: 2026-03-07
**Source**: specs/001-c4-content-creation-coordinator/tasks.md

## Root Epic

- **ID**: C4-001
- **Title**: C4 Content Creation Coordinator
- **Type**: epic
- **Priority**: 1
- **Description**: Build the foundational C4 platform: iOS app + Node.js backend on localhost with AI image generation, AI video generation, content project management, basic video assembly, and credit-based usage tracking.

## Epics

### Phase 1 — Setup: Project Scaffolding
- **ID**: C4-001.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 3

### Phase 2 — Foundational: Database, API, Job Queue, Credits
- **ID**: C4-001.2
- **Type**: epic
- **Priority**: 1
- **Blocks**: US1, US2, US3, US4, US5
- **Tasks**: 9

### Phase 3 — US1: AI Image Generation
- **ID**: C4-001.3
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Tasks**: 7

### Phase 4 — US2: AI Video Generation
- **ID**: C4-001.4
- **Type**: epic
- **Priority**: 1
- **Tasks**: 10

### Phase 5 — US3: Content Project Management
- **ID**: C4-001.5
- **Type**: epic
- **Priority**: 1
- **Tasks**: 7

### Phase 6 — US4: Basic Video Assembly
- **ID**: C4-001.6
- **Type**: epic
- **Priority**: 2
- **Depends**: US2
- **Tasks**: 6

### Phase 7 — US5: Credit System UI
- **ID**: C4-001.7
- **Type**: epic
- **Priority**: 1
- **Tasks**: 6

### Phase 8 — Polish: Cross-Cutting
- **ID**: C4-001.8
- **Type**: epic
- **Priority**: 3
- **Depends**: US1, US2, US3, US4, US5
- **Tasks**: 6

## Tasks

### Phase 1 — Setup

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Initialize Node.js backend with Fastify | backend/ | C4-001.1.1 |
| T002 | Create iOS Xcode project with SPM modules | ios/C4/ | C4-001.1.2 |
| T003 | Create config loader and .env.example | backend/src/config.js | C4-001.1.3 |

### Phase 2 — Foundational

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T004 | Create PostgreSQL schema migration | backend/src/db/migrations/ | C4-001.2.1 |
| T005 | Create database plugin (pg pool) | backend/src/plugins/database.js | C4-001.2.2 |
| T006 | Create Redis + BullMQ plugin | backend/src/plugins/redis.js | C4-001.2.3 |
| T007 | Create local storage plugin | backend/src/plugins/storage.js | C4-001.2.4 |
| T008 | Create WebSocket plugin | backend/src/plugins/websocket.js | C4-001.2.5 |
| T009 | Create credit accounting service | backend/src/services/credits.js | C4-001.2.6 |
| T010 | Create Fastify server entry point | backend/src/server.js | C4-001.2.7 |
| T011 | Create iOS CoreKit module | ios/C4/Packages/CoreKit/ | C4-001.2.8 |
| T012 | Create Knex config | backend/knexfile.js | C4-001.2.9 |

### Phase 3 — US1: AI Image Generation

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T013 | Create multi-provider image service | backend/src/services/ai-image.js | C4-001.3.1 |
| T014 | Create image generation BullMQ worker | backend/src/workers/generation.js | C4-001.3.2 |
| T015 | Create /api/generate/image route | backend/src/routes/generate.js | C4-001.3.3 |
| T016 | Create iOS image generation UI | ios/.../ImageGenerateView.swift | C4-001.3.4 |
| T017 | Create iOS image generation TCA reducer | ios/.../ImageGenerateReducer.swift | C4-001.3.5 |
| T018 | Wire WebSocket progress to iOS UI | ios/.../WebSocketClient.swift | C4-001.3.6 |
| T049 | Add Grok Imagine provider to image service | backend/src/services/ai-image.js | C4-001.3.7 |

### Phase 4 — US2: AI Video Generation

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T019 | Create multi-provider video service | backend/src/services/ai-video.js | C4-001.4.1 |
| T020 | Add video job type to BullMQ worker | backend/src/workers/generation.js | C4-001.4.2 |
| T021 | Create /api/generate/video route | backend/src/routes/generate.js | C4-001.4.3 |
| T022 | Create iOS video generation UI | ios/.../VideoGenerateView.swift | C4-001.4.4 |
| T023 | Create iOS video generation TCA reducer | ios/.../VideoGenerateReducer.swift | C4-001.4.5 |
| T024 | Create video thumbnail utility | backend/src/services/thumbnails.js | C4-001.4.6 |
| T050 | Add Grok Imagine Video provider to video service | backend/src/services/ai-video.js | C4-001.4.7 |
| T051 | Create video extension service with Grok Imagine | backend/src/services/video-extend.js | C4-001.4.8 |
| T052 | Create /api/generate/video/extend route | backend/src/routes/generate.js | C4-001.4.9 |
| T053 | Add video extension UI to iOS GenerateFeature | ios/.../VideoExtendView.swift | C4-001.4.10 |

### Phase 5 — US3: Content Project Management

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T025 | Create project CRUD routes | backend/src/routes/projects.js | C4-001.5.1 |
| T026 | Create asset management routes | backend/src/routes/assets.js | C4-001.5.2 |
| T027 | Create notes CRUD routes | backend/src/routes/notes.js | C4-001.5.3 |
| T028 | Create iOS project list view | ios/.../ProjectListView.swift | C4-001.5.4 |
| T029 | Create iOS project detail view | ios/.../ProjectDetailView.swift | C4-001.5.5 |
| T030 | Create iOS project TCA reducers | ios/.../ProjectReducer.swift | C4-001.5.6 |
| T031 | Create iOS asset preview views | ios/.../AssetPreviewView.swift | C4-001.5.7 |

### Phase 6 — US4: Basic Video Assembly

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T032 | Create Creatomate assembly service | backend/src/services/assembly.js | C4-001.6.1 |
| T033 | Create Deepgram captioning service | backend/src/services/captions.js | C4-001.6.2 |
| T034 | Create /api/assemble route | backend/src/routes/assemble.js | C4-001.6.3 |
| T035 | Add assembly job type to BullMQ worker | backend/src/workers/generation.js | C4-001.6.4 |
| T036 | Create iOS assembly UI | ios/.../AssemblyView.swift | C4-001.6.5 |
| T037 | Create iOS assembly TCA reducer | ios/.../AssemblyReducer.swift | C4-001.6.6 |

### Phase 7 — US5: Credit System UI

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T038 | Create credit routes | backend/src/routes/credits.js | C4-001.7.1 |
| T039 | Define credit cost matrix | backend/src/config/credit-costs.js | C4-001.7.2 |
| T040 | Create iOS credit view | ios/.../CreditView.swift | C4-001.7.3 |
| T041 | Create iOS credit TCA reducer | ios/.../CreditReducer.swift | C4-001.7.4 |
| T042 | Integrate credits into generation screens | ios/.../GenerateFeature/ | C4-001.7.5 |
| T054 | Add Grok Imagine to credit cost matrix | backend/src/config/credit-costs.js | C4-001.7.6 |

### Phase 8 — Polish

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T043 | Add error handling middleware | backend/src/plugins/errors.js | C4-001.8.1 |
| T044 | Add retry logic for AI providers | backend/src/services/ | C4-001.8.2 |
| T045 | Add credit refund on failure | backend/src/workers/generation.js | C4-001.8.3 |
| T046 | Create iOS empty/loading states | ios/.../CoreKit/SharedViews/ | C4-001.8.4 |
| T047 | Add backend integration tests | backend/tests/ | C4-001.8.5 |
| T048 | Create iOS navigation shell (tab bar) | ios/C4/C4App.swift | C4-001.8.6 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Setup | 3 | 1 | C4-001.1 |
| 2: Foundational | 9 | 1 | C4-001.2 |
| 3: US1 Image Gen (MVP) | 7 | 1 | C4-001.3 |
| 4: US2 Video Gen | 10 | 1 | C4-001.4 |
| 5: US3 Projects | 7 | 1 | C4-001.5 |
| 6: US4 Assembly | 6 | 2 | C4-001.6 |
| 7: US5 Credits UI | 6 | 1 | C4-001.7 |
| 8: Polish | 6 | 3 | C4-001.8 |
| **Total** | **54** | | |

## Dependency Graph

```
Phase 1: Setup (C4-001.1)
    |
Phase 2: Foundational (C4-001.2) --blocks--> US1, US2, US3, US5
    |
    +---> Phase 3: US1 Image Gen (C4-001.3)  [parallel]
    +---> Phase 4: US2 Video Gen (C4-001.4)  [parallel]
    +---> Phase 5: US3 Projects (C4-001.5)   [parallel]
    +---> Phase 7: US5 Credits UI (C4-001.7) [parallel]
              |
              Phase 4 --blocks--> Phase 6: US4 Assembly (C4-001.6)
              |
              +-------+-------+-------+-------+
                      |
              Phase 8: Polish (C4-001.8)
```

## Improvements

Improvements (Level 4: C4-001.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered. See
SKILL.md "Improvements (Post-Planning)" section for the workflow.
