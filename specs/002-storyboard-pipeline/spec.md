# Feature Specification: Script-to-Scene Storyboard Pipeline

**Feature Branch**: `002-storyboard-pipeline`
**Created**: 2026-03-11
**Status**: Draft
**Proposal**: ccbcebc4-8ab8-4c08-b97f-1f1972201f2e

## User Scenarios & Testing

### User Story 1 - Script Input & AI Scene Splitting (Priority: P1)

User pastes a script or outline into a storyboard editor. AI analyzes the text and breaks it into numbered scenes, each with a suggested visual prompt, camera direction, and estimated duration. User can review and edit the generated scenes before proceeding.

**Why this priority**: This is the entry point for the entire storyboard workflow. Without script-to-scene splitting, users must manually create each scene — defeating the purpose.

**Independent Test**: Create a storyboard, paste a 60-second script, verify AI returns 4-8 scenes with visual prompts and durations that sum to approximately 60 seconds.

**Acceptance Scenarios**:

1. **Given** a project exists, **When** user creates a new storyboard and pastes a script, **Then** AI returns numbered scenes with visual descriptions, narration text, and duration estimates
2. **Given** AI has split a script into scenes, **When** user edits a scene's visual prompt, **Then** the change persists and only affects that scene
3. **Given** a script with no clear scene breaks, **When** AI processes it, **Then** it still produces reasonable scene splits based on topic/mood changes

---

### User Story 2 - Storyboard Timeline & Scene Card UI (Priority: P1)

User views their storyboard as a horizontal scrollable timeline of scene cards. Each card shows: scene number, narration/dialogue excerpt, visual prompt, duration target, and generation status (empty/generating/complete). User can reorder scenes via drag-and-drop and add/delete individual scenes.

**Why this priority**: The timeline is the primary interface for the entire feature. Every other capability (generation, assembly) depends on having a usable scene management UI.

**Independent Test**: Create a storyboard with 6 scenes, verify timeline renders all cards, drag scene 4 to position 2, verify reorder persists. Delete a scene, verify remaining scenes renumber correctly.

**Acceptance Scenarios**:

1. **Given** a storyboard with scenes, **When** user opens the storyboard, **Then** a horizontal timeline shows all scene cards in order with scene number, narration excerpt, visual prompt, duration, and generation status
2. **Given** a storyboard timeline, **When** user drags a scene card to a new position, **Then** scenes reorder and renumber correctly
3. **Given** a storyboard timeline, **When** user taps "Add Scene" between two existing scenes, **Then** a blank scene is inserted and all scenes renumber
4. **Given** a storyboard timeline, **When** user deletes a scene, **Then** the scene is removed and remaining scenes renumber

---

### User Story 3 - Batch Generation (Priority: P1)

User taps "Generate All" on a storyboard to queue image or video generation for every scene that doesn't yet have a generated asset. Each scene's visual prompt is sent to the selected provider. Progress updates appear on each scene card in real-time. User can regenerate individual scenes without affecting others.

**Why this priority**: Batch generation is the core productivity unlock — it's the difference between generating 8 scenes one-by-one versus one click.

**Independent Test**: Create a storyboard with 5 scenes, tap "Generate All" with budget image provider, verify 5 jobs are queued, progress appears on each card, and all 5 assets attach to their respective scenes upon completion.

**Acceptance Scenarios**:

1. **Given** a storyboard with 5 scenes and no generated assets, **When** user taps "Generate All" and selects image generation with a provider, **Then** 5 generation jobs are queued and each scene card shows progress
2. **Given** a storyboard with 3/5 scenes already generated, **When** user taps "Generate All", **Then** only the 2 empty scenes are queued for generation
3. **Given** batch generation is in progress, **When** one scene fails, **Then** the failed scene shows an error and other scenes continue generating
4. **Given** a scene has a completed asset, **When** user taps "Regenerate" on that scene, **Then** a new generation replaces the old asset for that scene only

---

### User Story 4 - One-Click Assembly (Priority: P2)

User taps "Assemble" on a completed storyboard to combine all scene assets into a single video via the existing Creatomate pipeline. Scenes are assembled in storyboard order with configurable transitions. Captions are generated from the script text (narration field of each scene) rather than audio transcription.

**Why this priority**: Assembly is the payoff — it turns individual scene assets into a finished video. Depends on batch generation being functional.

**Independent Test**: Create a storyboard with 4 scenes, all with generated video assets. Tap "Assemble" with crossfade transitions and captions enabled. Verify output video plays scenes in order with transitions and script-based captions.

**Acceptance Scenarios**:

1. **Given** a storyboard where all scenes have generated video assets, **When** user taps "Assemble", **Then** a single video is produced with scenes in storyboard order
2. **Given** assembly is initiated, **When** user selects "crossfade" transition, **Then** the assembled video has 0.5s crossfade between each scene
3. **Given** captions are enabled for assembly, **When** assembly completes, **Then** captions are derived from each scene's narration text (not audio transcription) and timed to match scene durations
4. **Given** a storyboard where some scenes are missing assets, **When** user taps "Assemble", **Then** the button is disabled with a message indicating which scenes need generation

---

### User Story 5 - Scene Variations (Priority: P2)

For any individual scene, user can generate 2-3 visual alternatives using the same prompt or slight AI-perturbed variations. Alternatives display in a comparison view. User picks a winner which becomes the scene's primary asset.

**Why this priority**: Variations improve quality but aren't required for the core workflow. Can be added after the main pipeline works.

**Independent Test**: On a scene with one generated image, tap "Generate Variations (3)". Verify 3 alternatives appear in a comparison grid. Tap to select one as winner, verify it replaces the scene's primary asset.

**Acceptance Scenarios**:

1. **Given** a scene card, **When** user taps "Variations" and selects count (2 or 3), **Then** N generation jobs are queued with prompt variations
2. **Given** variations have completed, **When** user views the scene, **Then** all variations display in a side-by-side grid
3. **Given** a variation grid, **When** user taps "Use This" on a variation, **Then** it becomes the scene's primary asset and the grid collapses

---

### Edge Cases

- What happens when the script is empty or too short (< 10 words)? Show validation error, require minimum content.
- What happens when AI scene splitting produces too many scenes (> 20)? Cap at 20, suggest user break into multiple storyboards.
- What happens when a storyboard has mixed asset types (some images, some videos)? Assembly requires all-video; show prompt to generate video versions of image-only scenes.
- What happens when batch generation is interrupted (app backgrounded)? Jobs continue server-side; progress resumes on reconnect via WebSocket.
- What happens when user edits a scene prompt after generation? Mark the asset as "stale" with option to regenerate.

## Requirements

### Functional Requirements

- **FR-001**: System MUST support creating multiple storyboards per project
- **FR-002**: System MUST accept script text and return AI-generated scene breakdowns via API
- **FR-003**: System MUST store scenes with: order, narration text, visual prompt, duration target, and asset references
- **FR-004**: System MUST support batch queuing of generation jobs for all scenes in a storyboard
- **FR-005**: System MUST support one-click assembly of all scene assets in storyboard order
- **FR-006**: System MUST generate captions from scene narration text (not audio transcription) for assembly
- **FR-007**: System MUST support generating and comparing 2-3 variations per scene
- **FR-008**: System MUST broadcast per-scene generation progress via WebSocket

### Key Entities

- **Storyboard**: Belongs to a project. Has a title, original script text, and ordered scenes. Status: draft/generating/complete/assembled.
- **Scene**: Belongs to a storyboard. Has: order_index, narration_text, visual_prompt, duration_seconds, asset_id (nullable), variations (array of asset_ids).

## Success Criteria

- **SC-001**: User can go from pasting a script to having a fully assembled video in under 10 manual interactions (paste, review scenes, generate all, assemble)
- **SC-002**: Batch generation of 5 scenes completes without requiring per-scene manual intervention
- **SC-003**: Assembly output correctly orders scenes and applies script-based captions
