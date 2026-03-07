# Tasks: C4 Content Creation Coordinator

**Input**: Design documents from `/specs/001-c4-content-creation-coordinator/`
**Epic**: `C4-001`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (C4-001.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1-US5)

## Phase 1: Setup

**Purpose**: Scaffold both projects, install dependencies, establish project structure.

- [ ] T001 Initialize Node.js backend with Fastify, create `backend/package.json` with all dependencies (fastify, @fastify/swagger, @fastify/websocket, pg, knex, bullmq, ioredis, sharp, pino, openai, @fal-ai/client, @runwayml/sdk, dotenv) in `backend/`
- [ ] T002 [P] Create iOS Xcode project with SPM module structure: CoreKit, ProjectFeature, GenerateFeature, AssemblyFeature, CreditFeature in `ios/C4/`
- [ ] T003 [P] Create `.env.example` and config loader for API keys (OpenAI, fal.ai, Runway, Creatomate, Deepgram) in `backend/src/config.js`

---

## Phase 2: Foundational

**Purpose**: Core infrastructure blocking all user stories: database, storage, job queue, WebSocket, credit system.

- [ ] T004 Create PostgreSQL schema migration for projects, assets, notes, credits tables in `backend/src/db/migrations/001_initial.js`
- [ ] T005 Create Fastify database plugin (pg connection pool) in `backend/src/plugins/database.js`
- [ ] T006 [P] Create Redis plugin and BullMQ queue setup in `backend/src/plugins/redis.js`
- [ ] T007 [P] Create local filesystem storage plugin with asset path conventions in `backend/src/plugins/storage.js`
- [ ] T008 Create WebSocket plugin for real-time progress broadcast in `backend/src/plugins/websocket.js`
- [ ] T009 Create credit accounting service (balance check, deduct, refund, history) in `backend/src/services/credits.js`
- [ ] T010 Create Fastify server entry point registering all plugins and routes in `backend/src/server.js`
- [ ] T011 [P] Create iOS CoreKit module: API client (URLSession), WebSocket manager, shared models (Project, Asset, Credit) in `ios/C4/Packages/CoreKit/`
- [ ] T012 Create Knex configuration for localhost PostgreSQL in `backend/knexfile.js`

**Checkpoint**: Backend starts, database migrates, Redis connects, WebSocket accepts connections.

---

## Phase 3: US1 - AI Image Generation (Priority: P1, MVP)

**Goal**: Generate images from text prompts using multiple AI providers with real-time progress.
**Independent Test**: Submit a prompt, see an image appear, verify credits deducted.

- [ ] T013 [US1] Create multi-provider image generation service with provider selection (OpenAI, FLUX/fal.ai, Imagen/Nano Banana, Grok Imagine) in `backend/src/services/ai-image.js`
- [ ] T014 [US1] Create image generation BullMQ worker that processes jobs and emits WebSocket progress in `backend/src/workers/generation.js`
- [ ] T015 [US1] Create `/api/generate/image` POST route with schema validation, credit check, job dispatch in `backend/src/routes/generate.js`
- [ ] T016 [US1] Create iOS GenerateFeature: prompt input screen, provider/quality tier selector, generate button in `ios/C4/Packages/GenerateFeature/Sources/ImageGenerateView.swift`
- [ ] T017 [US1] Create iOS TCA reducer for image generation state (idle/generating/progress/complete/error) in `ios/C4/Packages/GenerateFeature/Sources/ImageGenerateReducer.swift`
- [ ] T018 [US1] Wire WebSocket progress updates from backend to iOS generation progress UI in `ios/C4/Packages/CoreKit/Sources/WebSocketClient.swift`

- [ ] T049 [US1] Add Grok Imagine provider (grok-imagine-image, grok-imagine-image-pro) to image service using OpenAI SDK with baseURL https://api.x.ai/v1 in `backend/src/services/ai-image.js`

**Checkpoint**: US1 independently functional -- prompt → image → credits deducted.

---

## Phase 4: US2 - AI Video Generation (Priority: P1)

**Goal**: Generate video clips from text or images using multiple AI providers.
**Independent Test**: Generate a 5-second video from text or image, see it playable in app.

- [ ] T019 [US2] Create multi-provider video generation service (Kling/fal.ai, Runway Gen-4, Hailuo, Veo, Grok Imagine) in `backend/src/services/ai-video.js`
- [ ] T020 [US2] Add video generation job type to BullMQ worker with async polling for provider status in `backend/src/workers/generation.js`
- [ ] T021 [US2] Create `/api/generate/video` POST route supporting text-to-video and image-to-video modes in `backend/src/routes/generate.js`
- [ ] T022 [US2] Create iOS video generation UI: mode selector (text/image), duration picker, aspect ratio in `ios/C4/Packages/GenerateFeature/Sources/VideoGenerateView.swift`
- [ ] T023 [US2] Create iOS TCA reducer for video generation with progress tracking and video playback in `ios/C4/Packages/GenerateFeature/Sources/VideoGenerateReducer.swift`
- [ ] T024 [P] [US2] Create video thumbnail generation utility using ffmpeg/sharp in `backend/src/services/thumbnails.js`

- [ ] T050 [US2] Add Grok Imagine Video provider (grok-imagine-video) to video service with text-to-video, image-to-video, and video editing modes in `backend/src/services/ai-video.js`
- [ ] T051 [US2] Create video extension service using Grok Imagine: chain continuations via video_url, poll for results, concatenate with ffmpeg in `backend/src/services/video-extend.js`
- [ ] T052 [US2] Create `/api/generate/video/extend` POST route with asset selection, continuation prompt, target duration in `backend/src/routes/generate.js`
- [ ] T053 [US2] Add video extension UI to iOS GenerateFeature: extend button on video assets, continuation prompt sheet, progress tracking in `ios/C4/Packages/GenerateFeature/Sources/VideoExtendView.swift`

**Checkpoint**: US2 independently functional -- prompt/image → video → playable → extendable → credits deducted.

---

## Phase 5: US3 - Content Project Management (Priority: P1)

**Goal**: Organize generated content into named projects with notes.
**Independent Test**: Create project, generate content into it, browse assets, add notes.

- [ ] T025 [US3] Create project CRUD routes (create, list, get, update, delete) in `backend/src/routes/projects.js`
- [ ] T026 [US3] Create asset management routes (list by project, get, delete) in `backend/src/routes/assets.js`
- [ ] T027 [US3] Create notes CRUD routes (add, list, update, delete per project) in `backend/src/routes/notes.js`
- [ ] T028 [US3] Create iOS ProjectFeature: project list view with grid/list toggle in `ios/C4/Packages/ProjectFeature/Sources/ProjectListView.swift`
- [ ] T029 [US3] Create iOS project detail view: asset grid, notes section, generation shortcuts in `ios/C4/Packages/ProjectFeature/Sources/ProjectDetailView.swift`
- [ ] T030 [US3] Create iOS TCA reducers for project list and project detail state in `ios/C4/Packages/ProjectFeature/Sources/ProjectReducer.swift`
- [ ] T031 [P] [US3] Create iOS asset preview: full-screen image viewer and video player in `ios/C4/Packages/ProjectFeature/Sources/AssetPreviewView.swift`

**Checkpoint**: US3 independently functional -- projects contain organized assets and notes.

---

## Phase 6: US4 - Basic Video Assembly (Priority: P2)

**Goal**: Combine multiple clips into a single video with optional captions.
**Independent Test**: Select 3 clips, assemble with captions, export to photo library.

- [ ] T032 [US4] Create Creatomate video assembly service (combine clips, transitions, aspect ratio) in `backend/src/services/assembly.js`
- [ ] T033 [US4] Create Deepgram captioning service (transcribe, generate SRT, burn-in) in `backend/src/services/captions.js`
- [ ] T034 [US4] Create `/api/assemble` POST route with clip selection, caption toggle, export options in `backend/src/routes/assemble.js`
- [ ] T035 [US4] Add assembly job type to BullMQ worker with Creatomate polling in `backend/src/workers/generation.js`
- [ ] T036 [US4] Create iOS AssemblyFeature: clip selector, order manager, caption toggle, preview in `ios/C4/Packages/AssemblyFeature/Sources/AssemblyView.swift`
- [ ] T037 [US4] Create iOS TCA reducer for assembly state and export-to-photos functionality in `ios/C4/Packages/AssemblyFeature/Sources/AssemblyReducer.swift`

**Checkpoint**: US4 independently functional -- multi-clip assembly with captions works.

---

## Phase 7: US5 - Credit System UI (Priority: P1)

**Goal**: Display credit balance, transaction history, and cost information.
**Independent Test**: View credits, generate something, see balance decrease with history entry.

- [ ] T038 [US5] Create credit routes: GET balance, GET history, POST allocate-free-tier in `backend/src/routes/credits.js`
- [ ] T039 [US5] Define credit cost matrix for all providers and quality tiers in `backend/src/config/credit-costs.js`
- [ ] T040 [US5] Create iOS CreditFeature: balance display, transaction history list in `ios/C4/Packages/CreditFeature/Sources/CreditView.swift`
- [ ] T041 [US5] Create iOS TCA reducer for credit state with real-time balance updates in `ios/C4/Packages/CreditFeature/Sources/CreditReducer.swift`
- [ ] T042 [US5] Integrate credit balance display into generation screens (show cost before generate) in `ios/C4/Packages/GenerateFeature/Sources/`

- [ ] T054 [US5] Add Grok Imagine pricing to credit cost matrix (image: 2/7 credits, video: per-second rate, extension: per-second rate) in `backend/src/config/credit-costs.js`

**Checkpoint**: Credits visible, costs shown before generation, history tracks all charges.

---

## Phase 8: Polish & Cross-Cutting

- [ ] T043 [P] Add error handling middleware and standardized error responses in `backend/src/plugins/errors.js`
- [ ] T044 [P] Add retry logic with exponential backoff for AI provider failures in `backend/src/services/ai-image.js` and `backend/src/services/ai-video.js`
- [ ] T045 [P] Add credit refund on generation failure in `backend/src/workers/generation.js`
- [ ] T046 [P] Create iOS empty states and loading indicators for all screens in `ios/C4/Packages/CoreKit/Sources/SharedViews/`
- [ ] T047 Add backend integration tests for generation and credit flows in `backend/tests/`
- [ ] T048 Create iOS app navigation shell (tab bar: Projects, Generate, Credits) in `ios/C4/C4App.swift`

---

## Dependencies

- Setup (Phase 1) -> Foundational (Phase 2) -> blocks all user stories
- US1 (Image Gen) and US2 (Video Gen) can run in parallel after Foundational
- US3 (Projects) can run in parallel with US1/US2 after Foundational
- US4 (Assembly) depends on US2 (needs video clips to assemble)
- US5 (Credits UI) can run in parallel after Foundational (credit service is in Foundational)
- Polish (Phase 8) depends on US1, US2, US3, US4, US5 complete

## Parallel Opportunities

- T001, T002, T003 (Setup) can all run in parallel
- T005+T006+T007 (database, redis, storage plugins) can run in parallel
- After Foundational: US1, US2, US3, US5 can all run in parallel across different files
- Tasks marked [P] within a phase can run simultaneously
- iOS and backend tasks within the same user story can be parallelized across 2 agents
