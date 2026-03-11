# Script-to-Scene Storyboard Pipeline - Beads

**Feature**: 002-storyboard-pipeline
**Generated**: 2026-03-11
**Source**: specs/002-storyboard-pipeline/tasks.md

## Root Epic

- **ID**: C4-002
- **Title**: Script-to-Scene Storyboard Pipeline
- **Type**: epic
- **Priority**: 1
- **Description**: Add storyboard system to C4: script input → AI scene splitting → batch generation → one-click assembly → scene variations. Builds on existing generation and assembly infrastructure.

## Epics

### Phase 1 — Setup: Database & Models
- **ID**: C4-002.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 3

### Phase 2 — Foundational: Backend CRUD & API Client
- **ID**: C4-002.2
- **Type**: epic
- **Priority**: 1
- **Blocks**: US1, US2, US3, US4, US5
- **Tasks**: 5

### Phase 3 — US1: Script Input & AI Scene Splitting (MVP)
- **ID**: C4-002.3
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Tasks**: 4

### Phase 4 — US2: Storyboard Timeline & Scene Card UI
- **ID**: C4-002.4
- **Type**: epic
- **Priority**: 1
- **Tasks**: 6

### Phase 5 — US3: Batch Generation
- **ID**: C4-002.5
- **Type**: epic
- **Priority**: 1
- **Depends**: Phase 3, Phase 4
- **Tasks**: 6

### Phase 6 — US4: One-Click Assembly
- **ID**: C4-002.6
- **Type**: epic
- **Priority**: 2
- **Depends**: Phase 5
- **Tasks**: 5

### Phase 7 — US5: Scene Variations
- **ID**: C4-002.7
- **Type**: epic
- **Priority**: 2
- **Depends**: Phase 5
- **Tasks**: 4

## Tasks

### Phase 1 — Setup

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Create storyboards/scenes migration | `backend/src/db/migrations/002_storyboards.js` | C4-002.1.1 |
| T002 | Create Storyboard iOS model | `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/Storyboard.swift` | C4-002.1.2 |
| T003 | Create Scene iOS model | `ios/C4/Packages/CoreKit/Sources/CoreKit/Models/Scene.swift` | C4-002.1.3 |

### Phase 2 — Foundational

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T004 | Storyboard CRUD routes | `backend/src/routes/storyboards.js` | C4-002.2.1 |
| T005 | Scene CRUD + reorder routes | `backend/src/routes/storyboards.js` | C4-002.2.2 |
| T006 | Register storyboard routes | `backend/src/server.js` | C4-002.2.3 |
| T007 | iOS API client storyboard methods | `ios/.../CoreKit/APIClient.swift` | C4-002.2.4 |
| T008 | StoryboardFeature SPM package scaffold | `ios/C4/Packages/StoryboardFeature/` | C4-002.2.5 |

### Phase 3 — US1: Script Input & AI Scene Splitting

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T009 | Scene-splitter service (LLM call) | `backend/src/services/scene-splitter.js` | C4-002.3.1 |
| T010 | Script splitting route | `backend/src/routes/storyboards.js` | C4-002.3.2 |
| T011 | ScriptInputView | `StoryboardFeature/.../ScriptInputView.swift` | C4-002.3.3 |
| T012 | Script splitting reducer actions | `StoryboardFeature/.../StoryboardReducer.swift` | C4-002.3.4 |

### Phase 4 — US2: Storyboard Timeline & Scene Card UI

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T013 | SceneCardView component | `StoryboardFeature/.../SceneCardView.swift` | C4-002.4.1 |
| T014 | StoryboardTimelineView | `StoryboardFeature/.../StoryboardTimelineView.swift` | C4-002.4.2 |
| T015 | Drag-and-drop reorder + add/delete reducer | `StoryboardFeature/.../StoryboardReducer.swift` | C4-002.4.3 |
| T016 | StoryboardListView | `StoryboardFeature/.../StoryboardListView.swift` | C4-002.4.4 |
| T017 | Wire into ProjectDetailView | `ProjectFeature/.../ProjectDetailView.swift` | C4-002.4.5 |
| T018 | Add StoryboardFeature to C4App | `ios/C4/C4App.swift` | C4-002.4.6 |

### Phase 5 — US3: Batch Generation

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T019 | Batch generate endpoint | `backend/src/routes/storyboards.js` | C4-002.5.1 |
| T020 | Worker: accept sceneId, update scene asset | `backend/src/workers/generation.js` | C4-002.5.2 |
| T021 | Scene-level WebSocket progress | `backend/src/plugins/websocket.js` | C4-002.5.3 |
| T022 | "Generate All" UI with provider picker | `StoryboardFeature/.../StoryboardTimelineView.swift` | C4-002.5.4 |
| T023 | Per-scene progress indicators | `StoryboardFeature/.../SceneCardView.swift` | C4-002.5.5 |
| T024 | Batch generation reducer effects | `StoryboardFeature/.../StoryboardReducer.swift` | C4-002.5.6 |

### Phase 6 — US4: One-Click Assembly

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T025 | Storyboard assemble route | `backend/src/routes/storyboards.js` | C4-002.6.1 |
| T026 | captionsFromScript() function | `backend/src/services/captions.js` | C4-002.6.2 |
| T027 | Assembly service: accept SRT content directly | `backend/src/services/assembly.js` | C4-002.6.3 |
| T028 | "Assemble" button + options UI | `StoryboardFeature/.../StoryboardTimelineView.swift` | C4-002.6.4 |
| T029 | Assembly progress + result reducer | `StoryboardFeature/.../StoryboardReducer.swift` | C4-002.6.5 |

### Phase 7 — US5: Scene Variations

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T030 | Scene variations endpoint | `backend/src/routes/storyboards.js` | C4-002.7.1 |
| T031 | Prompt perturbation logic | `backend/src/services/scene-splitter.js` | C4-002.7.2 |
| T032 | SceneVariationsView comparison grid | `StoryboardFeature/.../SceneVariationsView.swift` | C4-002.7.3 |
| T033 | Variation generation + winner selection reducer | `StoryboardFeature/.../StoryboardReducer.swift` | C4-002.7.4 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Setup | 3 | 1 | C4-002.1 |
| 2: Foundational | 5 | 1 | C4-002.2 |
| 3: US1 — AI Splitting (MVP) | 4 | 1 | C4-002.3 |
| 4: US2 — Timeline UI | 6 | 1 | C4-002.4 |
| 5: US3 — Batch Generation | 6 | 1 | C4-002.5 |
| 6: US4 — Assembly | 5 | 2 | C4-002.6 |
| 7: US5 — Variations | 4 | 2 | C4-002.7 |
| **Total** | **33** | | |

## Dependency Graph

```
Phase 1: Setup (C4-002.1)
    |
Phase 2: Foundational (C4-002.2)
    |
    +--→ Phase 3: US1 AI Splitting (C4-002.3)  ──┐
    |                                              |
    +--→ Phase 4: US2 Timeline UI (C4-002.4)   ──┤
                                                   |
                                    Phase 5: US3 Batch Gen (C4-002.5)
                                         |                |
                              Phase 6: US4 Assembly    Phase 7: US5 Variations
                              (C4-002.6)               (C4-002.7)
```

## Improvements

Improvements (Level 4: C4-002.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered.
