# Implementation Plan: C4 Content Creation Coordinator

**Branch**: `001-c4-content-creation-coordinator` | **Date**: 2026-03-07
**Epic**: `C4-001` | **Priority**: P1

## Summary

Build the foundational C4 platform: an iOS app backed by a Node.js (plain JavaScript) API running on localhost. The MVP delivers AI image generation, AI video generation, content project management, and basic video assembly -- all gated by a credit system. No auth, single user, localhost deployment. Detailed video editing, publishing, and multi-user features are deferred to future epics.

## Bead Map

- `C4-001` - Root: C4 Content Creation Coordinator
  - `C4-001.1` - Setup: Project scaffolding
  - `C4-001.2` - Foundational: Database, API framework, job queue, credit system
  - `C4-001.3` - US1: AI Image Generation
  - `C4-001.4` - US2: AI Video Generation
  - `C4-001.5` - US3: Content Project Management
  - `C4-001.6` - US4: Basic Video Assembly
  - `C4-001.7` - US5: Credit System & Usage Tracking
  - `C4-001.8` - Polish: Error handling, testing, documentation

## Technical Context

**iOS Stack**: SwiftUI + UIKit hybrid, TCA architecture, Swift Package Manager modules, Swift 6 concurrency
**Backend Stack**: Fastify (plain JS), PostgreSQL, Redis, BullMQ, Pino logging
**Storage**: Local filesystem (localhost), structured as `./storage/assets/{projectId}/{assetId}.{ext}`
**AI Providers**: OpenAI (GPT Image 1.5), fal.ai (FLUX, Kling, Hailuo), x.ai Grok Imagine (image + video + extension), Creatomate (assembly), Deepgram (captions)
**Testing**: XCTest + TCA testing (iOS), tap/node:test (backend)
**Constraints**: Localhost only, no auth, single user, plain JavaScript (no TypeScript)

## Architecture Decision

**Why Fastify over Express**: 4x throughput (72k vs 18k req/s), built-in JSON Schema validation eliminates need for separate validation library, automatic OpenAPI doc generation from route schemas, plugin system encourages modularity.

**Why fal.ai as gateway**: Unified SDK (`@fal-ai/client`) provides access to FLUX, Kling, Hailuo, and Seedance models through one API. Enables model switching without code changes. Cheaper than direct API access for most models.

**Why Grok Imagine**: x.ai's Grok Imagine provides competitive image generation ($0.02/img standard, $0.07/img pro) AND video generation ($0.05/sec) through an OpenAI-compatible API (same `openai` npm package, just different baseURL). Uniquely supports video extension — chaining continuations from the final frame of a clip to build longer sequences up to 30 seconds. No new dependencies needed.

**Why TCA for iOS**: Unidirectional data flow makes async AI generation state predictable. Composable reducers let us build features in isolation. Built-in dependency injection makes testing and previews easy. Best pattern for apps with complex async state.

**Why localhost first**: Eliminates AWS setup complexity from the critical path. Storage abstraction layer means we can swap to S3 later without changing business logic. Focus on product, not infrastructure.

## Files Changed

### Backend (`/backend/`)

| File | Change |
|------|--------|
| `backend/package.json` | Project config, dependencies |
| `backend/src/server.js` | Fastify server setup, plugin registration |
| `backend/src/plugins/database.js` | PostgreSQL connection via pg |
| `backend/src/plugins/redis.js` | Redis connection for cache + BullMQ |
| `backend/src/plugins/websocket.js` | WebSocket server for progress updates |
| `backend/src/plugins/storage.js` | Local filesystem storage abstraction |
| `backend/src/routes/projects.js` | CRUD routes for projects |
| `backend/src/routes/assets.js` | Asset management routes |
| `backend/src/routes/generate.js` | Image and video generation endpoints |
| `backend/src/routes/assemble.js` | Video assembly endpoints |
| `backend/src/routes/credits.js` | Credit balance and history |
| `backend/src/services/ai-image.js` | Multi-provider image generation service |
| `backend/src/services/ai-video.js` | Multi-provider video generation service |
| `backend/src/services/assembly.js` | Creatomate video assembly service |
| `backend/src/services/captions.js` | Deepgram captioning service |
| `backend/src/services/video-extend.js` | Grok Imagine video extension + ffmpeg concatenation |
| `backend/src/services/credits.js` | Credit accounting service |
| `backend/src/workers/generation.js` | BullMQ worker for async AI jobs |
| `backend/src/db/migrations/001_initial.js` | Database schema migration |
| `backend/src/db/migrations/002_credits.js` | Credit system tables |
| `backend/knexfile.js` | Knex database configuration |

### iOS App (`/ios/C4/`)

| File | Change |
|------|--------|
| `ios/C4/C4App.swift` | App entry point |
| `ios/C4/Package.swift` | SPM module definitions |
| `ios/C4/Packages/CoreKit/` | Shared models, API client, WebSocket manager |
| `ios/C4/Packages/ProjectFeature/` | Project list, project detail, notes |
| `ios/C4/Packages/GenerateFeature/` | Image/video generation UI and TCA reducers |
| `ios/C4/Packages/AssemblyFeature/` | Video assembly UI |
| `ios/C4/Packages/CreditFeature/` | Credit display, history |

## Phase 1: Setup

Scaffold both the iOS Xcode project and Node.js backend. Initialize git, install dependencies, configure linting. Create the SPM module structure for the iOS app. Establish the Fastify project skeleton with plugin architecture.

## Phase 2: Foundational

Build the core infrastructure that all user stories depend on: PostgreSQL schema and migrations, Redis connection, BullMQ job queue, local file storage service, WebSocket server for progress, API route structure, and the credit accounting system. This phase produces no user-visible features but unblocks everything else.

## Phase 3: US1 - AI Image Generation (MVP)

Implement the image generation pipeline end-to-end: iOS prompt input UI -> backend `/generate/image` endpoint -> AI provider service (OpenAI GPT Image 1.5, FLUX via fal.ai, Imagen 4 Fast) -> BullMQ job -> WebSocket progress -> store result -> return to iOS. Provider selection based on quality tier. Credit deduction on completion.

## Phase 4: US2 - AI Video Generation

Implement video generation pipeline: iOS video generation UI -> backend `/generate/video` endpoint -> AI provider service (Kling 3.0, Runway Gen-4, Hailuo via fal.ai, Grok Imagine Video) -> BullMQ job -> WebSocket progress -> store result -> return to iOS. Support text-to-video, image-to-video, and video extension modes. Grok Imagine enables extending clips by chaining continuations from the final frame, with server-side concatenation via ffmpeg.

## Phase 5: US3 - Content Project Management

Build the project CRUD layer: create/list/update/delete projects, associate assets with projects, add/edit notes, browse project assets in a grid with thumbnails, preview images and play videos inline.

## Phase 6: US4 - Basic Video Assembly

Integrate Creatomate API for combining multiple clips into one video. Add Deepgram for auto-captioning. Build iOS UI for selecting clips, choosing assembly options, and previewing/exporting the result.

## Phase 7: US5 - Credit System & Usage Tracking

Build the credits UI: display balance, show transaction history, configure free tier allocation. Wire credit checks into all generation endpoints. Build the cost calculation logic for different providers and quality tiers.

## Phase 8: Polish

Error handling across all flows, retry logic for failed generations, loading states, empty states, credit refund on failure, basic test coverage for backend routes and iOS reducers.

## Parallel Execution

- **After Phase 2 (Foundational)**: US1 (Image Gen), US3 (Projects), and US5 (Credits) can start in parallel -- they touch different files.
- **US2 (Video Gen)** can run in parallel with US1 since they share the same pattern but different provider services.
- **US4 (Assembly)** depends on US2 being complete (needs video clips to assemble).
- **Phase 8 (Polish)** depends on all user stories being complete.

## Verification Steps

- [ ] Backend starts on localhost:3000 with all routes registered
- [ ] `GET /docs` shows OpenAPI documentation
- [ ] Image generation produces a visible image file from a text prompt
- [ ] Video generation produces a playable video file
- [ ] WebSocket delivers progress updates during generation
- [ ] Credits are deducted after each generation
- [ ] Projects contain their associated assets
- [ ] Assembly combines multiple clips with captions
- [ ] iOS app displays projects, assets, and generation progress
