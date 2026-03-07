import OpenAI from 'openai';
import * as fal from '@fal-ai/client';
import RunwayML from '@runwayml/sdk';
import { withRetry } from '../lib/retry.js';
import config from '../config.js';

// --- Provider clients (lazy-initialized) ---

let grokClient;
function getGrok() {
  if (!grokClient) {
    grokClient = new OpenAI({
      apiKey: config.ai.xaiApiKey,
      baseURL: 'https://api.x.ai/v1',
    });
  }
  return grokClient;
}

let runwayClient;
function getRunway() {
  if (!runwayClient) {
    runwayClient = new RunwayML({ apiKey: config.ai.runwayApiKey });
  }
  return runwayClient;
}

function initFal() {
  fal.config({ credentials: config.ai.falKey });
}

// --- Quality-tier → default provider mapping ---

const TIER_PROVIDERS = {
  budget: 'hailuo',
  standard: 'kling',
  premium: 'runway',
};

// --- Provider implementations ---
// All video providers are async. Each returns { poll, metadata } where
// poll() resolves to { buffer, contentType } when the video is ready.

async function generateKling(prompt, opts) {
  initFal();
  const requestId = await fal.queue.submit('fal-ai/kling-video/v2', {
    input: {
      prompt,
      duration: String(opts.duration || 5),
      aspect_ratio: opts.aspectRatio || '16:9',
      ...(opts.imageUrl ? { image_url: opts.imageUrl } : {}),
    },
  });

  return {
    metadata: { provider: 'kling', model: 'kling-video-v2' },
    poll: createFalPoller(requestId),
  };
}

async function generateRunway(prompt, opts) {
  const client = getRunway();
  const params = {
    model: 'gen4_turbo',
    duration: Math.min(opts.duration || 5, 10),
    ratio: mapRunwayRatio(opts.aspectRatio),
  };

  if (opts.imageUrl) {
    params.promptImage = opts.imageUrl;
    params.promptText = prompt;
  } else {
    params.promptText = prompt;
  }

  const task = await client.imageToVideo.create(params);

  return {
    metadata: { provider: 'runway', model: 'gen4_turbo', taskId: task.id },
    poll: createRunwayPoller(client, task.id),
  };
}

async function generateHailuo(prompt, opts) {
  initFal();
  const requestId = await fal.queue.submit('fal-ai/hailuo-video', {
    input: {
      prompt,
      duration: String(opts.duration || 5),
      ...(opts.imageUrl ? { image_url: opts.imageUrl } : {}),
    },
  });

  return {
    metadata: { provider: 'hailuo', model: 'hailuo-video' },
    poll: createFalPoller(requestId),
  };
}

async function generateGrokVideo(prompt, opts) {
  const client = getGrok();

  // Grok Imagine Video uses a custom endpoint — POST /v1/videos/generations
  const body = {
    model: 'grok-imagine-video',
    prompt,
    ...(opts.imageUrl ? { image_url: opts.imageUrl } : {}),
    ...(opts.videoUrl ? { video_url: opts.videoUrl } : {}),
  };

  const response = await client.post('/videos/generations', {
    body,
  });

  const requestId = response.request_id;

  return {
    metadata: { provider: 'grok-imagine', model: 'grok-imagine-video', requestId },
    poll: createGrokVideoPoller(client, requestId),
  };
}

const PROVIDERS = {
  kling: generateKling,
  runway: generateRunway,
  hailuo: generateHailuo,
  'grok-imagine': generateGrokVideo,
};

// --- Polling helpers ---

function createFalPoller(requestId) {
  return async function poll(onProgress) {
    const POLL_INTERVAL = 3000;
    const MAX_POLLS = 200; // ~10 minutes

    for (let i = 0; i < MAX_POLLS; i++) {
      const status = await fal.queue.status(requestId.request_id, {
        logs: false,
      });

      if (status.status === 'COMPLETED') {
        const result = await fal.queue.result(requestId.request_id);
        const videoUrl = result.data.video?.url || result.data.video_url;
        const res = await fetch(videoUrl);
        return {
          buffer: Buffer.from(await res.arrayBuffer()),
          contentType: 'video/mp4',
        };
      }

      if (status.status === 'FAILED') {
        throw new Error(`fal.ai generation failed: ${status.error || 'unknown error'}`);
      }

      const progress = Math.min(Math.round((i / MAX_POLLS) * 90), 90);
      if (onProgress) onProgress(progress);

      await sleep(POLL_INTERVAL);
    }
    throw new Error('fal.ai generation timed out');
  };
}

function createRunwayPoller(client, taskId) {
  return async function poll(onProgress) {
    const POLL_INTERVAL = 5000;
    const MAX_POLLS = 120; // ~10 minutes

    for (let i = 0; i < MAX_POLLS; i++) {
      const task = await client.tasks.retrieve(taskId);

      if (task.status === 'SUCCEEDED') {
        const videoUrl = task.output?.[0];
        if (!videoUrl) throw new Error('Runway returned no output URL');
        const res = await fetch(videoUrl);
        return {
          buffer: Buffer.from(await res.arrayBuffer()),
          contentType: 'video/mp4',
        };
      }

      if (task.status === 'FAILED') {
        throw new Error(`Runway generation failed: ${task.failure || 'unknown error'}`);
      }

      const progress = task.progress ? Math.round(task.progress * 100) : Math.min(Math.round((i / MAX_POLLS) * 90), 90);
      if (onProgress) onProgress(progress);

      await sleep(POLL_INTERVAL);
    }
    throw new Error('Runway generation timed out');
  };
}

function createGrokVideoPoller(client, requestId) {
  return async function poll(onProgress) {
    const POLL_INTERVAL = 4000;
    const MAX_POLLS = 150; // ~10 minutes

    for (let i = 0; i < MAX_POLLS; i++) {
      const status = await client.get(`/videos/${requestId}`);

      if (status.status === 'completed' || status.status === 'complete') {
        const videoUrl = status.video_url || status.output?.video_url;
        if (!videoUrl) throw new Error('Grok returned no video URL');
        const res = await fetch(videoUrl);
        return {
          buffer: Buffer.from(await res.arrayBuffer()),
          contentType: 'video/mp4',
        };
      }

      if (status.status === 'failed') {
        throw new Error(`Grok video generation failed: ${status.error || 'unknown error'}`);
      }

      const progress = status.progress
        ? Math.round(status.progress * 100)
        : Math.min(Math.round((i / MAX_POLLS) * 90), 90);
      if (onProgress) onProgress(progress);

      await sleep(POLL_INTERVAL);
    }
    throw new Error('Grok video generation timed out');
  };
}

// --- Helpers ---

function mapRunwayRatio(aspectRatio) {
  const map = {
    '16:9': '16:9',
    '9:16': '9:16',
    '1:1': '1:1',
    '4:3': '4:3',
    '3:4': '3:4',
  };
  return map[aspectRatio] || '16:9';
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// --- Public API ---

/**
 * Start a video generation job with the specified provider.
 *
 * @param {object} params
 * @param {string} params.prompt - Text prompt
 * @param {string} [params.provider] - Explicit provider name
 * @param {string} [params.qualityTier='standard'] - budget | standard | premium
 * @param {number} [params.duration=5] - Duration in seconds (1-15)
 * @param {string} [params.aspectRatio='16:9'] - Aspect ratio
 * @param {string} [params.resolution] - Target resolution
 * @param {string} [params.imageUrl] - Source image URL for image-to-video
 * @returns {Promise<{ poll: (onProgress?) => Promise<{ buffer, contentType }>, metadata: object }>}
 */
export async function generateVideo({
  prompt,
  provider,
  qualityTier = 'standard',
  duration = 5,
  aspectRatio = '16:9',
  resolution,
  imageUrl,
}) {
  const resolvedProvider = provider || TIER_PROVIDERS[qualityTier] || TIER_PROVIDERS.standard;
  const generateFn = PROVIDERS[resolvedProvider];

  if (!generateFn) {
    throw new Error(`Unknown video provider: ${resolvedProvider}`);
  }

  return withRetry(() => generateFn(prompt, { duration, aspectRatio, resolution, imageUrl }));
}

export const providers = Object.keys(PROVIDERS);
export const qualityTiers = Object.keys(TIER_PROVIDERS);
