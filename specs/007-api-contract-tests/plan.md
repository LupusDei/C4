# Implementation Plan: API Contract Tests

**Branch**: `007-api-contract-tests` | **Date**: 2026-03-12
**Epic**: `C4-006` | **Priority**: P1

## Summary

Create shared Zod schemas defining every C4 API response shape, contract tests using supertest to validate backend responses against those schemas, and JSON fixture export for iOS XCTest Codable verification. Three phases: storyboard/scene (highest bug rate), style/prompt, then project/generation.

## Bead Map

_To be filled after bead creation._

## Technical Context

**Stack**: Node.js (Fastify), Zod, supertest, Node test runner; Swift (CoreKit models, XCTest)
**Storage**: PostgreSQL (test database via knex migrations)
**Testing**: Node built-in test runner (`node --test`), XCTest for iOS
**Constraints**: Tests must run without external AI providers (mocked or skipped); test DB setup/teardown must be idempotent

## Architecture Decision

Zod was chosen over JSON Schema or TypeScript interfaces because:
1. Runtime validation — can parse actual HTTP responses, not just type-check at compile time
2. Schema-to-JSON export — can generate fixture JSON from schema defaults
3. Single source of truth — one schema validates backend AND generates iOS fixtures
4. Already ecosystem-standard for this pattern in Node.js

supertest chosen because it integrates directly with Fastify's `.inject()` for in-process HTTP testing without starting a real server.

## Files Changed

| File | Change |
|------|--------|
| `backend/package.json` | Add zod, supertest devDependencies |
| `backend/types/contracts/` | New directory with Zod schemas per endpoint group |
| `backend/tests/contracts/` | New directory with contract test files |
| `backend/tests/helpers/` | Test DB setup, seed helpers, app factory |
| `backend/tests/fixtures/` | Exported JSON fixtures |
| `ios/C4/Packages/CoreKit/Tests/CoreKitTests/` | iOS fixture decode tests |

## Phase 1: Setup — Test Infrastructure

Install dependencies (zod, supertest). Create test helpers: test app factory (Fastify instance with test DB), database setup/teardown, seed helpers for creating test data. Create fixture export script.

## Phase 2: Storyboard & Scene Contracts (MVP)

Zod schemas for all storyboard and scene endpoints. Contract tests for: list/create/update/delete storyboards, splitScript, scene CRUD, reorderScenes, batch generation, assembly, variations. Export JSON fixtures. iOS decode tests.

## Phase 3: Style Preset & Prompt History Contracts

Zod schemas for style and prompt endpoints. Contract tests for: style CRUD + search + extract, prompt history + enhance + remix. Export fixtures. iOS decode tests.

## Phase 4: Project & Generation Contracts

Zod schemas for project, generation, credit, asset, and note endpoints. Contract tests for all CRUD and generation operations. Export fixtures. iOS decode tests.

## Phase 5: CI Integration & Polish

Wire contract tests into CI pipeline. Add fixture export as npm script. Ensure iOS tests run in Xcode scheme. Add documentation.

## Parallel Execution

- After Phase 1 (Setup), Phases 2, 3, and 4 can run in parallel — they touch different schema files and test files with no dependencies between endpoint groups.
- iOS fixture tests within each phase can be written in parallel with backend contract tests.

## Verification Steps

- [ ] `npm test` passes all contract tests
- [ ] JSON fixtures directory is populated with validated response files
- [ ] iOS XCTest fixture tests pass in Xcode
- [ ] A deliberate schema-breaking change (e.g., rename a field) causes a test failure
