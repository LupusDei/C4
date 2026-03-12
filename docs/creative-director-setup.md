# AI Creative Director — Setup & Usage Guide

## Overview

The AI Creative Director adds intelligent prompt enhancement, a curated visual style library, prompt history with remix, and style extraction to C4. It turns the blank prompt field into a creative partner powered by Claude.

## Prerequisites

- **Node.js** 20+
- **PostgreSQL** running locally (default: `localhost:5432`)
- **Redis** running locally (default: `localhost:6379`)
- **Anthropic API key** — required for prompt enhancement, remix, and style extraction

## Backend Setup

### 1. Environment Variables

Add to `backend/.env`:

```env
# Required for Creative Director features
ANTHROPIC_API_KEY=sk-ant-...

# Core (already required)
DATABASE_URL=postgresql://localhost:5432/c4
REDIS_URL=redis://localhost:6379
```

Without `ANTHROPIC_API_KEY`, the prompt enhance, remix, and style extract endpoints will return errors. All other features (style presets, prompt history, style picker) work without it.

### 2. Install Dependencies

```bash
cd backend
npm install
```

The Anthropic SDK (`@anthropic-ai/sdk`) is already in `package.json`.

### 3. Run Migrations

```bash
npm run migrate
```

This runs migration `003_creative_director.js` which creates:

| Table | Purpose |
|---|---|
| `style_presets` | System and custom visual style presets |
| `prompt_history` | Log of all prompts used in generations |

It also adds `default_style_preset_id` to the `projects` table for per-project style locking.

### 4. Seed Style Presets

```bash
npx knex seed:run --knexfile knexfile.js
```

This loads 32 curated style presets across 6 categories:

| Category | Examples |
|---|---|
| Cinematic | Film Noir, Wes Anderson, Sci-Fi Epic |
| Photography | Street Photography, Golden Hour, Macro |
| Illustration | Watercolor, Comic Book, Studio Ghibli |
| Digital Art | Neon Cyberpunk, Vaporwave, Low Poly |
| Retro | VHS Aesthetic, 35mm Film, Polaroid |
| Abstract | Geometric Minimalism, Fluid Art, Glitch |

The seed is idempotent — running it again won't create duplicates.

### 5. Start the Server

```bash
npm run dev
```

API docs with all new endpoints are available at `http://localhost:3000/docs`.

## iOS Setup

The iOS app already includes the `PromptFeature` package. Open the Xcode project and build normally. The app connects to `http://localhost:3000` by default.

Key packages:
- **PromptFeature** — Prompt enhancer view, style picker gallery, prompt history list
- **CoreKit** — Models (`StylePreset`, `PromptHistory`, `RemixResult`) and API client methods
- **GenerateFeature** — Image/video generation views with integrated prompt enhancement and style picker
- **ProjectFeature** — Project detail with default style lock and "Save as Style" from assets

## API Endpoints

### Prompt Enhancement

**POST /api/prompts/enhance**

Enhances a rough prompt into production-quality text optimized for the target provider.

```json
// Request
{ "prompt": "dog on a skateboard", "provider": "auto" }

// Response
{
  "original": "dog on a skateboard",
  "enhanced": "A golden retriever balancing on a weathered maple skateboard, captured at street level with a 35mm lens at f/2.8. Warm afternoon sunlight casting long shadows on cracked asphalt, bokeh of passing pedestrians in the background. Dynamic motion blur on the wheels, sharp focus on the dog's joyful expression.",
  "providerHints": ["Balance technical and descriptive language", ...]
}
```

Provider options: `auto`, `flux`, `openai`, `grok-imagine`, `nano-banana`. Each optimizes the prompt for that provider's strengths (e.g., FLUX gets photography terms, OpenAI gets conceptual language).

### Prompt Remix

**POST /api/prompts/remix**

Creates a meaningful variation of a prompt, keeping the core concept but changing elements like angle, setting, or color palette.

```json
// Request
{ "prompt": "A golden retriever on a skateboard at sunset" }

// Response
{
  "original": "A golden retriever on a skateboard at sunset",
  "remixed": "A border collie gliding on a longboard through a rain-slicked city street at dusk, neon signs reflected in puddles..."
}
```

### Prompt History

**GET /api/prompts/history**

Paginated, searchable log of all prompts used in generations.

```
GET /api/prompts/history?limit=20&offset=0&search=dog&projectId=<uuid>&generationType=image
```

Returns `{ items, total, limit, offset }`.

**GET /api/prompts/history/:id** — Single entry.

**DELETE /api/prompts/history/:id** — Remove an entry.

Prompt history is recorded automatically when you generate an image or video — no manual insertion needed.

### Style Presets

**GET /api/styles** — List all presets (system + custom). Filter with `?category=cinematic`.

**GET /api/styles/:id** — Single preset.

**POST /api/styles** — Create a custom style.

```json
{
  "name": "My Moody Style",
  "description": "Dark, atmospheric, high contrast",
  "promptModifier": "dark atmospheric lighting, deep shadows, high contrast, moody color grading, desaturated tones",
  "category": "cinematic"
}
```

**PUT /api/styles/:id** — Update a custom style (system presets are protected).

**DELETE /api/styles/:id** — Delete a custom style (system presets are protected). Automatically clears any project references.

### Style Extraction

**POST /api/styles/extract**

Uses Claude to analyze a prompt and extract its visual style elements, separating style from subject matter.

```json
// Request
{ "prompt": "A samurai standing in a field of cherry blossoms, soft pink watercolor washes, delicate ink outlines, traditional Japanese aesthetic" }

// Response
{
  "name": "Japanese Watercolor",
  "description": "Soft watercolor washes with delicate ink outlines in a traditional Japanese aesthetic",
  "promptModifier": "soft watercolor washes, delicate ink outlines, traditional Japanese aesthetic, muted pink and earth tones",
  "category": "illustration"
}
```

The extracted style can then be saved as a custom preset via `POST /api/styles`.

### Project Style Lock

**PUT /api/projects/:id**

Set a default style for a project so all generations maintain visual consistency:

```json
{ "defaultStylePresetId": "<style-preset-uuid>" }
```

Set to `null` to clear.

## Usage Workflows

### Enhance and Generate

1. Type a rough idea in the prompt field
2. Tap **Enhance** — Claude rewrites it with lighting, composition, mood, and provider-specific optimizations
3. Review the before/after comparison
4. Pick a style preset from the gallery (optional — it modifies the prompt further)
5. Generate

### Build a Style Library

1. Generate content you love
2. On the asset preview, tap **Save as Style** — Claude extracts the visual elements
3. Edit the extracted style name and modifier
4. Save as a custom preset
5. Apply it to future generations with one tap

### Remix Past Winners

1. Open **Prompt History** to browse your successful prompts
2. Tap **Remix** on any entry — Claude creates a fresh variation
3. Generate the remixed version
4. Build a content series from variations of a proven concept

### Maintain Visual Consistency

1. In project settings, set a **Default Style**
2. All generations in that project automatically apply the style's prompt modifier
3. Switch styles per-project to maintain distinct brand identities

## Architecture Notes

- **LLM**: All AI features use Claude (`claude-haiku-4-5-20251001` via `@anthropic-ai/sdk`) — fast and cost-effective for prompt rewriting
- **Prompt history** is recorded automatically during image/video generation (in `generate.js`), not from the enhance endpoint
- **Style presets** are seeded as system presets (`is_custom: false`) which cannot be modified or deleted via the API
- **iOS** uses The Composable Architecture (TCA) with dedicated reducers for each feature (PromptEnhancerReducer, StylePickerReducer, PromptHistoryReducer)
