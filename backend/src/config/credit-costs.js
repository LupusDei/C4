/**
 * Credit cost matrix for all AI providers and quality tiers.
 *
 * Structure: CREDIT_COSTS[type][key] = cost
 * - image costs are per image
 * - video costs are per 5-second clip
 * - video_extension is per second
 * - assembly and captioning are flat rates
 */
export const CREDIT_COSTS = {
  image: {
    'budget:nano-banana': 2,
    'standard:flux': 5,
    'standard:grok-imagine': 2,
    'premium:grok-imagine-pro': 7,
    'premium:openai': 10,
  },
  video: {
    'budget:hailuo': 5,
    'standard:kling': 10,
    'standard:grok-imagine-video': 5,
    'premium:runway': 25,
  },
  video_extension: 2, // per second
  assembly: 3,        // flat
  captioning: 1,      // flat
};

// Default costs when provider not specified
const DEFAULT_COSTS = {
  image: { budget: 2, standard: 5, premium: 10 },
  video: { budget: 5, standard: 10, premium: 25 },
};

/**
 * Look up the credit cost for a generation type.
 *
 * @param {'image'|'video'|'video_extension'|'assembly'|'captioning'} type
 * @param {string} [provider] - Provider name (e.g. 'flux', 'openai', 'kling')
 * @param {'budget'|'standard'|'premium'} [tier='standard'] - Quality tier
 * @returns {number} Credit cost
 */
export function getCreditCost(type, provider, tier = 'standard') {
  // Flat-rate types
  if (type === 'video_extension') return CREDIT_COSTS.video_extension;
  if (type === 'assembly') return CREDIT_COSTS.assembly;
  if (type === 'captioning') return CREDIT_COSTS.captioning;

  const tierCosts = CREDIT_COSTS[type];
  if (!tierCosts) return 5; // safe fallback

  // Try exact provider+tier match
  if (provider) {
    const key = `${tier}:${provider}`;
    if (key in tierCosts) return tierCosts[key];
  }

  // Fall back to tier default
  return DEFAULT_COSTS[type]?.[tier] ?? 5;
}
