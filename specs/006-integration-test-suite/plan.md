# Implementation Plan: Integration Test Suite

**Branch**: `006-integration-test-suite` | **Date**: 2026-03-12
**Epic**: `C4-005` | **Priority**: P1

## Summary

Add comprehensive integration tests to C4's backend (Node.js/Fastify) and iOS app (Swift/TCA), taking coverage from <5% to ~70% backend and 0% to ~50% iOS. All tests use mocked external providers (OpenAI, fal.ai, Deepgram, Creatomate) so they run fast with zero API costs. The existing test infrastructure in `backend/tests/setup.js` provides a foundation to extend.

## Bead Map

- `C4-005` - Root: Integration Test Suite
  - `C4-005.1` - Phase 1: Backend Test Infrastructure
    - `C4-005.1.1` - Extend test helpers with storyboard/scene/asset factories
    - `C4-005.1.2` - Add mock providers for all external services
    - `C4-005.1.3` - Register missing route plugins in test harness
    - `C4-005.1.4` - Add coverage reporting to package.json test script
  - `C4-005.2` - Phase 2: Backend Happy Path Tests
    - `C4-005.2.1` - Projects CRUD tests (5 tests)
    - `C4-005.2.2` - Storyboards CRUD + split + generate + assemble tests (15 tests)
    - `C4-005.2.3` - Scenes CRUD + reorder tests (8 tests)
    - `C4-005.2.4` - Assets list + get + delete tests (5 tests)
    - `C4-005.2.5` - Credits balance + history + allocate tests (5 tests)
    - `C4-005.2.6` - Notes CRUD tests (5 tests)
    - `C4-005.2.7` - Generation endpoint tests (6 tests)
    - `C4-005.2.8` - Assembly endpoint tests (3 tests)
  - `C4-005.3` - Phase 3: Backend Error Path Tests
    - `C4-005.3.1` - 404 tests for all resource types
    - `C4-005.3.2` - 400 tests for malformed/missing input
    - `C4-005.3.3` - 402 tests for insufficient credits
    - `C4-005.3.4` - Concurrent access and partial failure tests
    - `C4-005.3.5` - Credit refund verification tests
    - `C4-005.3.6` - Empty state edge case tests
  - `C4-005.4` - Phase 4: Worker Integration Tests
    - `C4-005.4.1` - Image generation worker success/failure tests
    - `C4-005.4.2` - Video generation worker tests
    - `C4-005.4.3` - Batch generation worker tests
    - `C4-005.4.4` - Assembly worker tests
  - `C4-005.5` - Phase 5: iOS TCA Reducer Tests
    - `C4-005.5.1` - StoryboardReducer tests (15 tests)
    - `C4-005.5.2` - ProjectReducer tests (5 tests)
    - `C4-005.5.3` - CreditReducer tests (3 tests)
    - `C4-005.5.4` - GenerateReducer tests (5 tests)
  - `C4-005.6` - Phase 6: iOS APIClient & WebSocket Tests
    - `C4-005.6.1` - APIClient URL/encoding/decoding tests (20 tests)
    - `C4-005.6.2` - WebSocketClient message parsing tests (8 tests)

## Technical Context

**Stack**: Node.js 22 (backend), Swift 6 / TCA (iOS), Fastify 5, Knex, BullMQ
**Storage**: PostgreSQL (production), in-memory mock (tests)
**Testing**: `node:test` + `node:assert` (backend), Swift Testing + TCA TestStore (iOS)
**Constraints**: Zero external API calls in tests, <30s backend / <60s iOS runtime

## Architecture Decision

Extend the existing mock-based approach in `backend/tests/setup.js` rather than spinning up a real PostgreSQL instance. The in-memory mock DB is already working for credits/projects routes — it needs to be extended with storyboard/scene/asset support and missing route registrations (storyboards, scenes, notes, styles, prompts). This keeps tests fast and dependency-free.

For iOS, use TCA's built-in `TestStore` for reducer testing and `URLProtocol` subclass for network mocking — both are standard patterns with zero additional dependencies.

## Files Changed

| File | Change |
|------|--------|
| `backend/tests/setup.js` | Extend mock DB with storyboards/scenes/assets tables, add missing route registrations |
| `backend/tests/helpers.js` | NEW — test factory functions (createTestProject, createTestStoryboard, etc.) |
| `backend/tests/mocks/` | NEW — mock provider modules (openai, fal, deepgram, creatomate) |
| `backend/tests/routes/projects.test.js` | NEW — projects CRUD happy + error tests |
| `backend/tests/routes/storyboards.test.js` | NEW — storyboards CRUD + split + generate tests |
| `backend/tests/routes/scenes.test.js` | NEW — scenes CRUD + reorder tests |
| `backend/tests/routes/assets.test.js` | NEW — assets list/get/delete tests |
| `backend/tests/routes/credits.test.js` | NEW — credits balance/history/allocate tests |
| `backend/tests/routes/notes.test.js` | NEW — notes CRUD tests |
| `backend/tests/routes/generate.test.js` | NEW — generation endpoint tests |
| `backend/tests/routes/assemble.test.js` | NEW — assembly endpoint tests |
| `backend/tests/workers/generation.test.js` | NEW — worker integration tests |
| `backend/package.json` | Update test script with coverage flag |
| `ios/.../CoreKit/Tests/CoreKitTests/APIClientTests.swift` | NEW — APIClient tests |
| `ios/.../CoreKit/Tests/CoreKitTests/WebSocketClientTests.swift` | NEW — WebSocket tests |
| `ios/.../CoreKit/Tests/CoreKitTests/MockURLProtocol.swift` | NEW — URL protocol mock |
| `ios/.../StoryboardFeature/Tests/.../StoryboardReducerTests.swift` | NEW — reducer tests |
| `ios/.../ProjectFeature/Tests/.../ProjectReducerTests.swift` | NEW — reducer tests |
| `ios/.../CreditFeature/Tests/.../CreditReducerTests.swift` | NEW — reducer tests |
| `ios/.../GenerateFeature/Tests/.../GenerateReducerTests.swift` | NEW — reducer tests |

## Phase 1: Backend Test Infrastructure

Extend `backend/tests/setup.js` to support all route groups. Add factory helpers and mock providers. The existing `buildTestApp()` and `createMockDb()` provide the pattern — extend with storyboard/scene/asset table support. Register all route plugins (currently only generate, projects, credits, assemble are registered).

## Phase 2: Backend Happy Path Tests

One test file per route group, following the pattern in `backend/tests/integration.test.js`. Each file imports `buildTestApp()`, uses factory helpers to seed data, and tests each endpoint with valid input. Tests are independent — each `describe` block sets up its own data.

## Phase 3: Backend Error Path Tests

Same test files as Phase 2 (or separate `*.error.test.js` files). Test 404s, 400s, 402s, concurrent access, partial failures, and credit refunds. Focus on the specific error scenarios documented in the proposal.

## Phase 4: Worker Integration Tests

Test the BullMQ worker's `processJob` function directly with mocked AI providers. Verify side effects: asset creation, scene updates, credit deduction/refund, WebSocket broadcasts. Import the worker's processing function and call it with mock job data.

## Phase 5: iOS TCA Reducer Tests

Use TCA `TestStore` with mocked dependencies. Each reducer test file creates a `TestStore`, sends actions, and asserts state changes and effects. JSON fixtures from backend contract tests can be reused as mock API responses.

## Phase 6: iOS APIClient & WebSocket Tests

Use `URLProtocol` subclass to intercept network requests. Verify URL construction, HTTP methods, request body encoding, and response decoding for every endpoint. Test WebSocket message parsing and reconnection logic.

## Parallel Execution

- **Backend track** (Phases 1-4) and **iOS track** (Phases 5-6) are fully independent — can run in parallel
- Within Phase 2, all route test files can be written in parallel (different files, no deps)
- Within Phase 3, all error test files can be written in parallel
- Phase 5 reducer tests can all be written in parallel (different packages)
- Phase 6 is independent of Phase 5

## Verification Steps

- [ ] `npm test` passes with 90+ backend tests and ≥70% coverage
- [ ] `swift test` passes in each iOS feature package
- [ ] No test makes external API calls (verify with network monitor)
- [ ] Backend tests complete in <30 seconds
- [ ] iOS tests complete in <60 seconds
