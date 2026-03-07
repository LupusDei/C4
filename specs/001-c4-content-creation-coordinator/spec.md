# Feature Specification: C4 Content Creation Coordinator

**Feature Branch**: `001-c4-content-creation-coordinator`
**Created**: 2026-03-07
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - AI Image Generation (Priority: P1)

User opens the C4 app, starts a new content project, types a prompt describing an image they want, selects a quality tier (budget/standard/premium), and taps Generate. The backend dispatches the request to the appropriate AI provider based on the tier, deducts credits, and streams real-time progress back via WebSocket. When the image is ready, it appears in the project gallery.

**Why this priority**: Image generation is the fastest path to demonstrating value and testing the full client-server-AI pipeline.

**Independent Test**: Generate an image from a text prompt, see it appear in the project, verify credits were deducted.

**Acceptance Scenarios**:

1. **Given** a user with available credits, **When** they submit an image prompt with "standard" quality, **Then** an image is generated via the configured provider, stored locally, displayed in the project, and credits are deducted.
2. **Given** a user with zero credits, **When** they attempt to generate an image, **Then** they see a "no credits remaining" message and no generation occurs.
3. **Given** an image generation is in progress, **When** the user views the project, **Then** they see a real-time progress indicator updated via WebSocket.

---

### User Story 2 - AI Video Generation (Priority: P1)

User selects an existing image (or provides a text prompt), chooses video generation settings (duration, aspect ratio, quality tier), and taps Generate Video. The backend dispatches to the video AI provider via the job queue, streams progress, and the resulting video clip appears in the project when complete. Users can also **extend** existing video clips using Grok Imagine — the system chains continuations from the final frame to build longer sequences up to 30 seconds.

**Why this priority**: Video generation is the core differentiator of C4 and validates the async job pipeline.

**Independent Test**: Generate a 5-second video from an image, see it appear in the project with playback.

**Acceptance Scenarios**:

1. **Given** a user with credits and a generated image, **When** they request image-to-video generation, **Then** a video clip is generated, stored, and playable in the project.
2. **Given** a text prompt, **When** the user requests text-to-video, **Then** a video is generated directly from the prompt.
3. **Given** a video generation job is queued, **When** the user checks progress, **Then** they see percentage-based updates streamed in real-time.
4. **Given** a generated video clip under 8.7 seconds, **When** the user taps Extend and provides a continuation prompt, **Then** the system generates a continuation from the final frame and concatenates the clips into a longer video.

---

### User Story 3 - Content Project Management (Priority: P1)

User creates named content projects to organize their generated images and videos. They can browse projects, view all assets in a project grid, preview images/videos, add notes/ideas to a project, and delete unwanted assets.

**Why this priority**: Projects provide the organizational container for all generated content.

**Independent Test**: Create a project, generate assets into it, browse them, add notes, delete an asset.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** the user creates a new project with a name, **Then** an empty project appears in the project list.
2. **Given** a project exists, **When** the user generates an image or video, **Then** it is automatically associated with the current project.
3. **Given** a project with assets, **When** the user views the project, **Then** they see a grid of thumbnails they can tap to preview.
4. **Given** a project, **When** the user adds a note, **Then** the note is saved and visible when they return to the project.

---

### User Story 4 - Basic Video Assembly (Priority: P2)

User selects multiple video clips and/or images from a project and assembles them into a single video using Creatomate's API. They can choose an aspect ratio, add auto-generated captions (via Deepgram), and export the assembled video.

**Why this priority**: Assembly turns individual clips into finished content -- the core value proposition. But basic generation (US1 + US2) must work first.

**Independent Test**: Select 3 clips, assemble them with captions into a single video, export it.

**Acceptance Scenarios**:

1. **Given** a project with multiple video clips, **When** the user selects clips and taps Assemble, **Then** clips are combined into a single video in order.
2. **Given** an assembly job, **When** captions are enabled, **Then** Deepgram transcribes audio and captions are burned into the final video.
3. **Given** an assembled video, **When** the user taps Export, **Then** the video is saved to the device photo library.

---

### User Story 5 - Credit System & Usage Tracking (Priority: P1)

The system tracks credit usage for all AI operations. Each user starts with a free credit allocation. Different AI operations cost different amounts of credits. The user can see their remaining credits and generation history.

**Why this priority**: Credits gate all AI usage and must be in place before any generation works.

**Independent Test**: Start with 100 credits, generate an image (costs 5), verify balance shows 95.

**Acceptance Scenarios**:

1. **Given** a new installation, **When** the app starts, **Then** the user has a default free credit allocation.
2. **Given** available credits, **When** any AI generation completes, **Then** the appropriate credit cost is deducted and recorded.
3. **Given** the credits screen, **When** the user views it, **Then** they see remaining balance and a history of charges.

---

### Edge Cases

- What happens when an AI provider API is down? Show error, refund credits, suggest retry.
- What happens when a generation takes longer than expected? Show timeout warning, allow cancel.
- What happens when the device goes offline mid-generation? Queue resumes when connection returns.
- What happens when local storage is full? Warn user, suggest deleting old assets.

## Requirements

### Functional Requirements

- **FR-001**: System MUST generate images from text prompts via configurable AI providers
- **FR-002**: System MUST generate video clips from text or image inputs via configurable AI providers
- **FR-003**: System MUST organize generated content into named projects with notes
- **FR-004**: System MUST track and enforce credit-based usage limits
- **FR-005**: System MUST provide real-time progress updates during generation via WebSocket
- **FR-006**: System MUST assemble multiple clips into a single video with optional captions
- **FR-007**: System MUST support multiple AI provider tiers (budget/standard/premium) including Grok Imagine
- **FR-010**: System MUST support video extension via Grok Imagine, chaining clip continuations up to 30 seconds
- **FR-008**: System MUST store generated media locally (localhost deployment)
- **FR-009**: System MUST process generation jobs asynchronously via job queue

### Key Entities

- **Project**: A named container for content. Has title, description, notes, created/updated timestamps.
- **Asset**: A generated image or video. Belongs to a project. Has prompt, provider, quality tier, file path, thumbnail, credit cost, status.
- **CreditAccount**: Tracks balance and transaction history. Has balance, transactions[].
- **GenerationJob**: An async AI generation request. Has status, progress percentage, provider, input params, result asset ID.
- **Note**: Free-form text attached to a project for capturing ideas.

## Success Criteria

- **SC-001**: Generate an image from prompt in under 15 seconds end-to-end
- **SC-002**: Generate a 5-second video clip in under 90 seconds end-to-end
- **SC-003**: Real-time progress updates arrive within 1 second of status change
- **SC-004**: Credit deduction is atomic -- no double-charges or missed charges
- **SC-005**: Assembled video plays smoothly with synced captions
- **SC-006**: App remains responsive during background generation (no UI blocking)
