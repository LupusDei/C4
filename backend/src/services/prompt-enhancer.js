import Anthropic from '@anthropic-ai/sdk';
import config from '../config.js';

// --- Anthropic client (lazy-initialized) ---

let anthropicClient;
function getAnthropic() {
  if (!anthropicClient) {
    anthropicClient = new Anthropic({ apiKey: config.ai.anthropicApiKey });
  }
  return anthropicClient;
}

// --- Provider template configs ---

const PROVIDER_HINTS = {
  flux: {
    style: 'Photography-centric',
    hints: [
      'Use specific focal lengths (e.g., 35mm, 85mm, 200mm)',
      'Reference aperture values (f/1.4, f/2.8, f/11)',
      'Mention film stocks (Kodak Portra 400, Fuji Velvia 50)',
      'Describe exposure and grain characteristics',
      'Specify lens types (anamorphic, tilt-shift, macro)',
    ],
  },
  openai: {
    style: 'Conceptual/descriptive',
    hints: [
      'Emphasize mood and atmosphere',
      'Reference artistic styles and movements',
      'Use metaphor and narrative elements',
      'Describe emotional tone and feeling',
      'Reference well-known visual aesthetics',
    ],
  },
  'grok-imagine': {
    style: 'Balanced technical and descriptive',
    hints: [
      'Balance technical and descriptive language',
      'Emphasize clarity and detail',
      'Mix photographic terms with artistic concepts',
      'Be specific about subject and environment',
      'Include both mood and technical specifications',
    ],
  },
  'nano-banana': {
    style: 'Simple and clear',
    hints: [
      'Clear subject description',
      'Clean composition directives',
      'Good lighting descriptions',
      'Simple and direct language',
      'Focus on the essential visual elements',
    ],
  },
};

const REMIX_SYSTEM_PROMPT = `You are a creative director. Take this image generation prompt and create a meaningful variation. Keep the core concept and mood but change specific elements: different angle, setting, time of day, color palette, or composition. The variation should feel fresh but clearly related to the original. Return ONLY the new prompt text.`;

const SYSTEM_PROMPT_TEMPLATE = `You are a professional creative director for AI image generation. Enhance the user's rough prompt into a production-quality prompt. Add specific details about lighting, composition, color palette, mood, texture, and style. Adapt your language to work best with {provider}. Keep the core concept but make it vivid and specific. Return ONLY the enhanced prompt text, no explanations.`;

/**
 * Resolve which provider hints to use.
 * "auto" falls back to a balanced default (grok-imagine style).
 */
function resolveProviderConfig(provider) {
  const key = provider && provider !== 'auto' ? provider : 'grok-imagine';
  return PROVIDER_HINTS[key] || PROVIDER_HINTS['grok-imagine'];
}

/**
 * Enhance a user prompt using Claude for provider-aware optimization.
 *
 * @param {string} prompt - The user's raw prompt
 * @param {string} [provider='auto'] - Target image provider
 * @returns {Promise<{ original: string, enhanced: string, providerHints: string[] }>}
 */
export async function enhancePrompt(prompt, provider = 'auto') {
  const providerConfig = resolveProviderConfig(provider);
  const providerLabel = provider && provider !== 'auto' ? provider : 'general-purpose';

  const systemPrompt = SYSTEM_PROMPT_TEMPLATE.replace('{provider}', providerLabel);

  const userMessage = [
    `Provider style: ${providerConfig.style}`,
    `Key considerations: ${providerConfig.hints.join('; ')}`,
    '',
    `User prompt: ${prompt}`,
  ].join('\n');

  const client = getAnthropic();

  const response = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    system: systemPrompt,
    messages: [
      { role: 'user', content: userMessage },
    ],
  });

  const enhanced = response.content
    .filter((block) => block.type === 'text')
    .map((block) => block.text)
    .join('')
    .trim();

  return {
    original: prompt,
    enhanced,
    providerHints: providerConfig.hints,
  };
}

/**
 * Remix a prompt using Claude — creates a meaningful variation.
 * @param {string} prompt - The original prompt text
 * @returns {Promise<string>} Remixed prompt text
 */
export async function remixPrompt(prompt) {
  const client = getAnthropic();

  const message = await client.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 1024,
    system: REMIX_SYSTEM_PROMPT,
    messages: [{ role: 'user', content: prompt }],
  });

  return message.content[0].text.trim();
}
