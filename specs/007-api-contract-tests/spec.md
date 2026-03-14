# Feature Specification: API Contract Tests

**Feature Branch**: `007-api-contract-tests`
**Created**: 2026-03-12
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - Storyboard & Scene Contract Verification (Priority: P1)

Backend developers change storyboard/scene API response shapes without breaking iOS decoding. Contract tests catch shape mismatches at CI time instead of runtime.

**Why this priority**: Storyboard and scene APIs have the highest historical bug rate — splitScript, reorderScenes, batch generation responses have all caused iOS crashes from shape mismatches.

**Independent Test**: Run `npm test` in backend — all storyboard/scene contract tests pass. Import JSON fixtures into iOS XCTest — all Codable round-trip tests pass.

**Acceptance Scenarios**:

1. **Given** a running backend, **When** contract tests execute against storyboard CRUD endpoints, **Then** all responses parse through Zod schemas without error
2. **Given** the splitScript endpoint returns `{storyboard, scenes}`, **When** the contract test runs, **Then** the Zod schema validates this exact shape (not `[Scene]`)
3. **Given** validated response JSON is exported as fixtures, **When** iOS XCTest decodes them with `Storyboard.self` and `Scene.self`, **Then** all fields decode correctly including snake_case → camelCase mapping

---

### User Story 2 - Style Preset & Prompt History Contract Verification (Priority: P2)

Style preset and prompt history APIs have verified contracts ensuring iOS models match backend responses.

**Why this priority**: Lower bug rate than storyboards, but still a type-mismatch risk as these are newer APIs.

**Independent Test**: Run style/prompt contract tests — all pass. iOS fixtures decode correctly.

**Acceptance Scenarios**:

1. **Given** style preset CRUD endpoints, **When** contract tests run, **Then** responses match Zod schemas for create/read/update/delete/search
2. **Given** prompt history endpoints, **When** contract tests run, **Then** response shapes match including remix and enhancement fields

---

### User Story 3 - Project & Generation Contract Verification (Priority: P2)

Project CRUD and generation endpoints have verified contracts.

**Why this priority**: Project APIs are simpler and more stable, generation has fewer shape issues.

**Independent Test**: Run project/generation contract tests — all pass.

**Acceptance Scenarios**:

1. **Given** project CRUD endpoints, **When** contract tests run, **Then** responses match Zod schemas
2. **Given** generation and assembly endpoints, **When** contract tests run, **Then** response shapes match including job status, cost estimation, and credit fields

---

### Edge Cases

- What happens when a backend response includes extra fields not in the schema? → Zod `.passthrough()` or `.strict()` — decision: use `.strict()` to catch drift in both directions
- What happens when iOS model has optional fields the backend doesn't send? → Fixture tests catch missing fields at decode time
- How do we handle enum value mismatches (e.g., backend sends "in_progress" but iOS expects "inProgress")? → Zod schemas define exact string enum values; iOS CodingKeys handle the mapping

## Requirements

### Functional Requirements

- **FR-001**: System MUST have Zod schemas for every API endpoint response shape in `backend/types/contracts/`
- **FR-002**: System MUST have supertest-based contract tests that hit real HTTP endpoints and validate through Zod
- **FR-003**: System MUST export validated JSON fixtures for iOS XCTest consumption
- **FR-004**: Contract tests MUST run as part of `npm test` in CI
- **FR-005**: iOS fixture tests MUST verify Codable round-trip decoding of all exported JSON

### Key Entities

- **Contract Schema**: Zod schema defining the exact response shape for one API endpoint
- **Contract Test**: supertest test that calls an endpoint and validates the response through its schema
- **JSON Fixture**: Validated response JSON file exported for cross-platform testing

## Success Criteria

- **SC-001**: All 3 phases of contract tests pass in CI with zero manual intervention
- **SC-002**: At least one historical iOS-backend mismatch (splitScript, reorderScenes, or camelCase) would have been caught by these tests
- **SC-003**: iOS XCTest fixture tests decode all exported JSON without errors
