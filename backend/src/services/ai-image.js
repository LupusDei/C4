import OpenAI from 'openai';
import * as fal from '@fal-ai/client';
import { withRetry } from '../lib/retry.js';
import config from '../config.js';

// --- Provider clients (lazy-initialized) ---

let openaiClient;
function getOpenAI() {
  if (!openaiClient) {
    openaiClient = new OpenAI({ apiKey: config.ai.openaiApiKey });
  }
  return openaiClient;
}

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

function initFal() {
  fal.config({ credentials: config.ai.falKey });
}

// --- Quality-tier → default provider mapping ---

const TIER_PROVIDERS = {
  budget: 'nano-banana',
  standard: 'flux',
  premium: 'openai',
};

// --- Provider implementations ---

async function generateOpenAI(prompt, opts) {
  const client = getOpenAI();
  const response = await client.images.generate({
    model: 'gpt-image-1.5',
    prompt,
    n: 1,
    size: mapSize(opts.aspectRatio, 'openai'),
    quality: 'high',
    response_format: 'b64_json',
  });

  const b64 = response.data[0].b64_json;
  return {
    buffer: Buffer.from(b64, 'base64'),
    contentType: 'image/png',
    metadata: {
      provider: 'openai',
      model: 'gpt-image-1.5',
      revisedPrompt: response.data[0].revised_prompt || null,
    },
  };
}

async function generateFlux(prompt, opts) {
  initFal();
  const result = await fal.subscribe('fal-ai/flux-pro/v2', {
    input: {
      prompt,
      image_size: mapSize(opts.aspectRatio, 'fal'),
      num_images: 1,
      enable_safety_checker: true,
    },
  });

  const imageUrl = result.data.images[0].url;
  const res = await fetch(imageUrl);
  const buffer = Buffer.from(await res.arrayBuffer());

  return {
    buffer,
    contentType: 'image/png',
    metadata: {
      provider: 'flux',
      model: 'flux-pro-v2',
      seed: result.data.seed ?? null,
    },
  };
}

async function generateNanoBanana(prompt, opts) {
  initFal();
  const result = await fal.subscribe('fal-ai/imagen4/preview', {
    input: {
      prompt,
      image_size: mapSize(opts.aspectRatio, 'fal'),
      num_images: 1,
    },
  });

  const imageUrl = result.data.images[0].url;
  const res = await fetch(imageUrl);
  const buffer = Buffer.from(await res.arrayBuffer());

  return {
    buffer,
    contentType: 'image/png',
    metadata: {
      provider: 'nano-banana',
      model: 'imagen4-preview',
    },
  };
}

async function generateGrokImagine(prompt, opts) {
  const client = getGrok();
  const model = opts.grokPro ? 'grok-imagine-image-pro' : 'grok-imagine-image';
  const response = await client.images.generate({
    model,
    prompt,
    n: 1,
    response_format: 'b64_json',
  });

  const b64 = response.data[0].b64_json;
  return {
    buffer: Buffer.from(b64, 'base64'),
    contentType: 'image/png',
    metadata: {
      provider: 'grok-imagine',
      model,
      revisedPrompt: response.data[0].revised_prompt || null,
    },
  };
}

const PROVIDERS = {
  openai: generateOpenAI,
  flux: generateFlux,
  'nano-banana': generateNanoBanana,
  'grok-imagine': generateGrokImagine,
};

// --- Size mapping helpers ---

function mapSize(aspectRatio, target) {
  const ratios = {
    '1:1': { openai: '1024x1024', fal: 'square_hd' },
    '16:9': { openai: '1536x1024', fal: 'landscape_16_9' },
    '9:16': { openai: '1024x1536', fal: 'portrait_16_9' },
    '4:3': { openai: '1536x1024', fal: 'landscape_4_3' },
    '3:4': { openai: '1024x1536', fal: 'portrait_4_3' },
  };
  const ar = aspectRatio || '1:1';
  return ratios[ar]?.[target] || ratios['1:1'][target];
}

// --- Public API ---

/**
 * Generate an image using the specified provider (or quality-tier default).
 *
 * @param {object} params
 * @param {string} params.prompt - Text prompt
 * @param {string} [params.provider] - Explicit provider name
 * @param {string} [params.qualityTier='standard'] - budget | standard | premium
 * @param {string} [params.aspectRatio='1:1'] - Aspect ratio
 * @param {object} [params.providerOptions] - Extra provider-specific options
 * @returns {Promise<{ buffer: Buffer, metadata: object }>}
 */
export async function generateImage({
  prompt,
  provider,
  qualityTier = 'standard',
  aspectRatio = '1:1',
  providerOptions = {},
}) {
  const resolvedProvider = provider || TIER_PROVIDERS[qualityTier] || TIER_PROVIDERS.standard;
  const generateFn = PROVIDERS[resolvedProvider];

  if (!generateFn) {
    throw new Error(`Unknown image provider: ${resolvedProvider}`);
  }

  return withRetry(() => generateFn(prompt, { aspectRatio, ...providerOptions }));
}

export const providers = Object.keys(PROVIDERS);
export const qualityTiers = Object.keys(TIER_PROVIDERS);
