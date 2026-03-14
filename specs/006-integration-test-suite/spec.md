# Feature Specification: Integration Test Suite

**Feature Branch**: `006-integration-test-suite`
**Created**: 2026-03-12
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - Backend Test Infrastructure & Happy Path Coverage (Priority: P1)

A developer pushes code to C4's backend and wants confidence that all API endpoints return correct responses for valid input. The test suite runs in <30 seconds with zero external API calls, using mocked providers and an in-memory or test database.

**Why this priority**: Foundation — nothing else works without test infrastructure. Happy paths cover the most common user journeys.

**Independent Test**: `npm test` from `backend/` runs all route tests against mocked providers and reports coverage ≥70%.

**Acceptance Scenarios**:

1. **Given** a clean test environment, **When** `npm test` runs, **Then** all 52+ happy path tests pass in <30 seconds
2. **Given** mocked OpenAI/fal.ai/Deepgram/Creatomate providers, **When** any generation endpoint is called, **Then** canned responses are returned without network calls
3. **Given** test helpers exist, **When** a test needs a project/storyboard/scene, **Then** `createTestProject()` etc. seed the data in one call
4. **Given** test run completes, **When** coverage is reported, **Then** route coverage is ≥70%

---

### User Story 2 - Backend Error Path & Worker Tests (Priority: P1)

A developer wants to verify that C4's backend handles all error cases correctly — 404s, 400s, 402s, partial failures, credit refunds — and that the BullMQ worker processes jobs correctly with proper side effects.

**Why this priority**: Error paths are where production bugs live. The 9 bugs found during C4-002 QA were almost all error-path issues.

**Independent Test**: Error path tests and worker tests pass, covering 40+ error scenarios and 15+ worker scenarios.

**Acceptance Scenarios**:

1. **Given** a nonexistent resource ID, **When** any GET/PUT/DELETE endpoint is called, **Then** 404 is returned with descriptive error
2. **Given** insufficient credits, **When** a generation endpoint is called, **Then** 402 is returned and no job is queued
3. **Given** a generation job fails, **When** the worker processes it, **Then** the asset is marked failed, credits are refunded, and a WebSocket error is broadcast
4. **Given** a batch generation where 3 of 5 scenes fail, **When** processing completes, **Then** 2 assets exist, 3 are marked failed, and credits are refunded for failures only

---

### User Story 3 - iOS TCA Reducer Tests (Priority: P2)

An iOS developer modifies a TCA reducer and wants to verify that state transitions and effects are correct without running the full app.

**Why this priority**: Reducers contain all business logic for the iOS app. Testing them catches logic regressions before they reach UI.

**Independent Test**: `swift test` in each feature package runs reducer tests with TestStore.

**Acceptance Scenarios**:

1. **Given** a StoryboardReducer TestStore, **When** `.splitScript` action is sent, **Then** state transitions through loading → success with scenes populated
2. **Given** a ProjectReducer TestStore, **When** `.delete` action is sent, **Then** the project is removed from state and API effect fires
3. **Given** a CreditReducer TestStore, **When** `.loadBalance` action is sent, **Then** balance is populated from mock API response

---

### User Story 4 - iOS APIClient & WebSocket Tests (Priority: P2)

An iOS developer modifies the API or WebSocket client and wants to verify URL construction, request encoding, response decoding, and WebSocket message handling are correct.

**Why this priority**: Client-backend contract mismatches have caused bugs. These tests catch encoding/decoding issues at compile time.

**Independent Test**: `swift test` in CoreKit runs APIClient and WebSocketClient tests.

**Acceptance Scenarios**:

1. **Given** a mocked URLProtocol, **When** `APIClient.createProject(name:)` is called, **Then** the request URL is `/api/projects`, method is POST, and body contains the name
2. **Given** a WebSocket message `{"type":"progress","jobId":"123","percent":50}`, **When** parsed by WebSocketClient, **Then** a `.progress(jobId: "123", percent: 50)` event is emitted
3. **Given** a WebSocket disconnection, **When** reconnection logic fires, **Then** the client reconnects within 5 seconds

---

### Edge Cases

- What happens when the test database is not available? → Tests should fail fast with a clear error, not hang
- What happens when a mock provider is not configured for a route? → Test should fail with "missing mock" error, not silently pass
- What happens when iOS JSON fixtures don't match backend response shapes? → Type decoding tests catch the mismatch

## Requirements

### Functional Requirements

- **FR-001**: Backend test suite MUST run with zero external API calls (all providers mocked)
- **FR-002**: Backend test suite MUST report line coverage via Node.js built-in coverage
- **FR-003**: iOS tests MUST use TCA TestStore for reducer testing
- **FR-004**: iOS tests MUST use URLProtocol mock for APIClient testing
- **FR-005**: All test helpers MUST be reusable across test files
- **FR-006**: Tests MUST run in <30 seconds total (backend) and <60 seconds total (iOS)

### Key Entities

- **Test Helper**: Factory functions for creating test data (projects, storyboards, scenes, credits)
- **Mock Provider**: Fake implementation of external services (OpenAI, fal.ai, Deepgram, Creatomate)
- **JSON Fixture**: Canned response data shared between backend contract tests and iOS decode tests

## Success Criteria

- **SC-001**: Backend test coverage ≥70% (from <5%)
- **SC-002**: iOS test coverage ≥50% (from 0%)
- **SC-003**: ~163 total tests across backend and iOS
- **SC-004**: All tests pass in CI with no external dependencies
- **SC-005**: Test suite runs in <30s (backend) and <60s (iOS)
