# Feature Specification: AI Creative Director — Trend-Aware Prompt Intelligence

**Feature Branch**: `003-ai-creative-director`
**Created**: 2026-03-11
**Status**: Draft
**Proposal**: 52acda98-92a6-4e6f-ab06-ae8a21e92b16

## User Scenarios & Testing

### User Story 1 - Smart Prompt Enhancement (Priority: P1)

User types a rough prompt idea ("dog on a skateboard") and taps an "Enhance" button. AI rewrites it into a production-quality prompt with lighting, composition, style, and mood details. The original and enhanced prompts are shown side-by-side so the user learns effective prompting over time. The enhanced prompt is auto-adapted to the selected provider's strengths (e.g., FLUX responds well to photography terms, OpenAI handles abstract concepts better).

**Why this priority**: This is the core value proposition — eliminating the blank page problem. Every other feature builds on having better prompts.

**Independent Test**: Type "cat sleeping on books" in the prompt field, tap Enhance, verify AI returns a detailed prompt with lighting/composition/style. Switch provider from FLUX to OpenAI, verify the enhanced prompt adapts its terminology.

**Acceptance Scenarios**:

1. **Given** the user is on the image generation screen, **When** they type a rough prompt and tap "Enhance", **Then** an AI-enhanced version appears alongside the original with added lighting, composition, and style details
2. **Given** the user has selected FLUX as provider, **When** they enhance a prompt, **Then** the enhanced version uses photography-specific terms (focal length, exposure, film stock)
3. **Given** the user has selected OpenAI as provider, **When** they enhance a prompt, **Then** the enhanced version uses descriptive/conceptual language that OpenAI responds best to
4. **Given** the user views an enhanced prompt, **When** they want to modify it, **Then** they can edit the enhanced version before generating

---

### User Story 2 - Visual Style Library (Priority: P1)

User browses a gallery of 30-50 curated visual style presets (cinematic, anime, watercolor, neon cyberpunk, vintage film, etc.) with example thumbnails. Selecting a style automatically modifies the current prompt to incorporate that style's characteristics. Users can save their own custom styles from generations they love. Projects can have a default "locked" style that applies to all generations within that project.

**Why this priority**: Style presets are the second biggest friction reducer after prompt enhancement. They give users a starting vocabulary and ensure visual consistency across content series.

**Independent Test**: Open the style picker, browse presets, select "Cinematic". Verify the current prompt is modified with cinematic style terms. Save a custom style from a completed generation. Set a project style lock, verify it applies to new generations.

**Acceptance Scenarios**:

1. **Given** the user is on the generation screen, **When** they tap the style picker, **Then** a gallery of curated presets appears with name, thumbnail preview, and style description
2. **Given** a style is selected, **When** the user's prompt is "mountain at sunset", **Then** the prompt is modified to include the style's characteristics (e.g., "mountain at sunset, cinematic lighting, anamorphic lens flare, 35mm film grain, dramatic color grading")
3. **Given** the user has generated an image they love, **When** they tap "Save as Style", **Then** the prompt's style elements are extracted and saved as a reusable custom style
4. **Given** a project has a style lock set, **When** the user generates any content in that project, **Then** the locked style is automatically applied (with option to override)

---

### User Story 3 - Prompt History & Remix (Priority: P1)

User can browse a history of all prompts they've used, sorted by recency. Each history entry shows the prompt text, provider used, and a thumbnail of the generated result. A "Remix" button takes a past prompt and creates an AI-generated variation for new content — preserving the effective elements while adding novelty.

**Why this priority**: Prompt history prevents re-inventing the wheel and remix accelerates content series production. Low implementation cost with high user value.

**Independent Test**: Generate 3 images with different prompts. Open prompt history, verify all 3 appear with thumbnails. Tap Remix on the first, verify a variation is generated that preserves the core concept but adds novelty.

**Acceptance Scenarios**:

1. **Given** the user has generated content, **When** they open prompt history, **Then** all past prompts appear sorted by recency with prompt text, provider, and result thumbnail
2. **Given** the user is viewing prompt history, **When** they tap a past prompt, **Then** it is loaded into the generation prompt field
3. **Given** the user is viewing a past prompt, **When** they tap "Remix", **Then** AI generates a variation that preserves the core concept but introduces new elements (different angle, mood, or setting)
4. **Given** the user searches prompt history, **When** they type a search term, **Then** matching prompts are filtered by prompt text content

---

### User Story 4 - Content Intelligence (Priority: P2)

User sets their content niche (tech, fitness, cooking, comedy, education) in project settings. The system suggests trending content ideas and prompt templates tailored to what's working in that niche. A series idea generator takes a project theme and suggests a 5-10 episode content series with titles, visual concepts, and hook ideas.

**Why this priority**: Content intelligence is valuable but requires curated trend data and is not essential for the core prompt enhancement workflow. Ship after MVP proves the prompt enhancement model.

**Independent Test**: Set project niche to "tech". Open suggestions panel, verify tech-relevant content ideas appear. Use series generator with theme "AI tools", verify 5-10 episode suggestions with titles and visual concepts.

**Acceptance Scenarios**:

1. **Given** a project has a niche set, **When** the user opens the suggestions panel, **Then** content ideas appear tailored to that niche
2. **Given** the user taps "Generate Series", **When** they provide a theme, **Then** AI returns 5-10 episode suggestions with titles, visual concepts, and hook ideas
3. **Given** trend suggestions are displayed, **When** the user taps one, **Then** it populates the prompt field with the suggested content idea

---

### User Story 5 - Learning Loop (Priority: P2)

System tracks which prompts, styles, and providers produce assets the user keeps versus regenerates. Over time, suggestions become personalized toward what works for this specific user. On any generated asset, a "More Like This" button generates similar content by capturing the effective elements and producing variations.

**Why this priority**: The learning loop compounds over time but requires sufficient usage data to be useful. Ship after the generation features have user traction.

**Independent Test**: Generate 5 images, keep 3 and regenerate 2. Verify analytics show keep/regenerate ratios. On a kept image, tap "More Like This", verify a similar-but-different image is generated.

**Acceptance Scenarios**:

1. **Given** the user has generated multiple assets, **When** they view generation analytics, **Then** they see keep vs. regenerate ratios per provider and style
2. **Given** the user taps "More Like This" on a generated asset, **When** the generation completes, **Then** the result captures the effective elements (style, composition, mood) while varying specifics
3. **Given** the user has sufficient usage history, **When** they start a new generation, **Then** provider and style suggestions are ranked by personal success rate

---

### Edge Cases

- What happens when the prompt is empty and user taps Enhance? Show validation error requiring minimum input (at least 3 words).
- What happens when the LLM API is unavailable for prompt enhancement? Fall back gracefully — let the user proceed with their original prompt, show a non-blocking error.
- What happens when provider-specific optimization targets an unavailable provider? Enhancement should still work — provider hints are additive, not required.
- What happens when the style library has no custom styles yet? Show only curated presets. Custom styles section appears after the user saves their first.
- What happens when prompt history grows very large (1000+ entries)? Paginate with infinite scroll. Search is essential at this scale.
- What happens when "Remix" produces a prompt nearly identical to the original? Include a novelty constraint in the AI prompt to ensure meaningful variation.

## Requirements

### Functional Requirements

- **FR-001**: System MUST provide AI prompt enhancement that rewrites rough prompts into production-quality prompts with lighting, composition, style, and mood
- **FR-002**: System MUST adapt enhanced prompts to the selected provider's strengths (provider-aware optimization)
- **FR-003**: System MUST provide a library of 30+ curated visual style presets with name, description, and prompt modifier
- **FR-004**: System MUST allow users to save custom styles from successful generations
- **FR-005**: System MUST support per-project style lock (default style applied to all generations)
- **FR-006**: System MUST maintain a searchable history of all prompts with associated generation results
- **FR-007**: System MUST provide a "Remix" function that creates AI-generated prompt variations from past prompts
- **FR-008**: System SHOULD provide niche-aware content suggestions and series idea generation (P2)
- **FR-009**: System SHOULD track generation analytics (keep vs. regenerate) for personalization (P2)
- **FR-010**: System SHOULD provide "More Like This" on generated assets (P2)

### Key Entities

- **StylePreset**: Curated or user-created style with name, description, prompt_modifier, thumbnail_url, category, is_custom flag. Belongs to user (if custom) or system (if curated).
- **PromptHistory**: Record of every prompt used with original_prompt, enhanced_prompt, provider, style_preset_id, asset_id (result), kept (boolean).
- **ProjectStyle**: Junction linking a project to its locked style preset.

## Success Criteria

- **SC-001**: Prompt enhancement produces noticeably better generation results compared to raw user prompts (subjective, verified by user testing)
- **SC-002**: Enhancement latency under 3 seconds (single Claude API call)
- **SC-003**: Style presets modify prompts consistently — same style applied to different prompts produces visually cohesive results
- **SC-004**: Prompt history loads within 500ms for up to 1000 entries
- **SC-005**: Remix produces meaningfully different prompts (not near-duplicates) in 95% of cases
