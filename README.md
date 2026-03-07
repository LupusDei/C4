# C4 — Content Creation Coordinator

AI-powered content creation platform with multi-provider image generation, video generation, video extension, and video assembly. Node.js backend + iOS app.

## Architecture

```
ios/C4/             SwiftUI + TCA app (5 SPM packages)
backend/            Fastify API server (plain JS, ESM)
  src/
    routes/         REST endpoints
    services/       AI provider integrations
    workers/        BullMQ background jobs
    plugins/        Fastify plugins (db, redis, ws, storage)
    config/         Credit cost matrix
    lib/            Retry utility
    db/migrations/  PostgreSQL schema
  tests/            Integration tests
```

## Prerequisites

- **Node.js** 20+
- **PostgreSQL** 14+
- **Redis** 7+
- **ffmpeg** (for video thumbnails and extension concatenation)
- **Xcode** 16+ with iOS 18 SDK (for the iOS app)

At least one AI provider API key (see below).

## Backend Setup

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
# Required
DATABASE_URL=postgresql://localhost:5432/c4
REDIS_URL=redis://localhost:6379

# AI providers (add whichever you have)
OPENAI_API_KEY=sk-...          # GPT Image 1.5
XAI_API_KEY=xai-...            # Grok Imagine (image + video + extend)
FAL_KEY=...                     # FLUX, Kling, Hailuo, Nano Banana
RUNWAY_API_KEY=...              # Runway Gen-4
CREATOMATE_API_KEY=...          # Video assembly
DEEPGRAM_API_KEY=...            # Captions/transcription

# Optional
PORT=3000
STORAGE_PATH=./storage
```

You don't need all providers. The system selects providers based on quality tier:

| Tier | Image Provider | Video Provider |
|------|---------------|----------------|
| Budget | Nano Banana (Imagen 4) | Hailuo |
| Standard | FLUX Pro v2 | Kling 3.0 |
| Premium | OpenAI GPT Image | Runway Gen-4 |

Grok Imagine is available at all tiers when selected explicitly.

### 3. Create the database

```bash
createdb c4
npm run migrate
```

### 4. Start Redis

```bash
redis-server
```

### 5. Start the server

```bash
# Development (auto-restart on changes)
npm run dev

# Production
npm start
```

Server runs at `http://localhost:3000`. API docs at `http://localhost:3000/docs`.

### 6. Run tests

```bash
npm test
```

## iOS App Setup

The iOS app is a pure SPM project at `ios/C4/`. It needs an Xcode project wrapper to build.

### 1. Open in Xcode

```bash
cd ios/C4
open Package.swift
```

Or create a new Xcode iOS app project and add the local packages as dependencies.

### 2. Build targets

The app is organized as 5 SPM packages:

| Package | Purpose |
|---------|---------|
| **CoreKit** | API client, WebSocket client, data models |
| **GenerateFeature** | Image/video generation + video extend UI |
| **ProjectFeature** | Project list, detail, asset preview |
| **CreditFeature** | Credit balance, history, allocation |
| **AssemblyFeature** | Multi-clip video assembly |

`C4App.swift` is the entry point — it wires all features into a `TabView` with three tabs: Projects, Generate, Credits.

### 3. Requirements

- iOS 18+ / macOS 14+
- Swift 6
- The backend must be running at `localhost:3000` (hardcoded in `APIClient`)

## Usage

### Starting a project

1. Open the **Projects** tab
2. Tap **+** to create a new project (title + description)
3. The project holds all your generated assets and notes

### Generating images

1. Go to **Generate > Generate Image**
2. Write a prompt
3. Pick quality tier (budget/standard/premium), provider, and aspect ratio
4. Select a project to save to
5. Tap **Generate Image** — progress streams via WebSocket

### Generating video

1. Go to **Generate > Generate Video**
2. Choose mode: **Text-to-Video** or **Image-to-Video** (needs a source image asset)
3. Set prompt, duration (1-15s), resolution, provider, quality tier
4. Tap **Generate Video**

### Extending video

From a project's asset detail view, tap **Extend** on any completed video. Grok Imagine chains continuations from the final frame, up to 30 seconds total.

### Assembling video

From a project detail, open the assembly view:

1. Select 2+ completed video clips
2. Reorder with up/down buttons
3. Choose aspect ratio, transition (none/crossfade/fade), and whether to enable captions
4. Tap **Assemble Video** — clips are combined via Creatomate with optional Deepgram captions

### Credits

New accounts start with **100 credits**. Each generation costs credits based on type and provider:

| Type | Cost |
|------|------|
| Budget image | 2 credits |
| Standard image | 5 credits |
| Premium image | 10 credits |
| Budget video (5s) | 5 credits |
| Standard video (5s) | 10 credits |
| Premium video (5s) | 25 credits |
| Video extension | 2 credits/second |
| Video assembly | 3 credits |
| Captioning | 1 credit |

Add more credits from the **Credits** tab. Failed generations are automatically refunded.

## API Endpoints

### Generation

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/generate/image` | Generate an AI image |
| `POST` | `/api/generate/video` | Generate an AI video |
| `POST` | `/api/generate/video/extend` | Extend a video via Grok Imagine |
| `POST` | `/api/assemble` | Assemble clips into a video |

### Projects

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/projects` | List all projects |
| `POST` | `/api/projects` | Create a project |
| `GET` | `/api/projects/:id` | Get a project |
| `PUT` | `/api/projects/:id` | Update a project |
| `DELETE` | `/api/projects/:id` | Delete a project |

### Assets

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/projects/:id/assets` | List assets (paginated) |
| `GET` | `/api/assets/:id` | Get an asset |
| `DELETE` | `/api/assets/:id` | Delete an asset |
| `GET` | `/api/assets/:id/file` | Serve the asset file |
| `GET` | `/api/assets/:id/thumbnail` | Serve the thumbnail |

### Notes

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/projects/:id/notes` | List notes |
| `POST` | `/api/projects/:id/notes` | Create a note |
| `PUT` | `/api/projects/:id/notes/:noteId` | Update a note |
| `DELETE` | `/api/projects/:id/notes/:noteId` | Delete a note |

### Credits

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/credits/balance` | Get current balance |
| `GET` | `/api/credits/history` | Get transaction history |
| `POST` | `/api/credits/allocate` | Add credits |

### WebSocket

Connect to `ws://localhost:3000/ws` to receive real-time generation progress:

```json
{ "event": "generation:progress", "data": { "jobId": "...", "progress": 50, "status": "generating" } }
{ "event": "generation:complete", "data": { "jobId": "...", "assetId": "..." } }
{ "event": "generation:error",    "data": { "jobId": "...", "error": "..." } }
```

## Quick Start (all-in-one)

```bash
# Terminal 1: Start services
redis-server &
createdb c4 2>/dev/null

# Terminal 2: Start backend
cd backend
cp .env.example .env
# Edit .env with your API keys
npm install
npm run migrate
npm run dev

# Terminal 3: Open iOS app in Xcode
cd ios/C4
open Package.swift
```
