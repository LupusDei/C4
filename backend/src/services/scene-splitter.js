import OpenAI from 'openai';
import config from '../config.js';

let client;
function getClient() {
  if (!client) {
    client = new OpenAI({ apiKey: config.ai.openaiApiKey });
  }
  return client;
}

/**
 * Generate N visual prompt variations that preserve the core concept
 * but vary style, angle, lighting, and composition.
 *
 * @param {string} visualPrompt - The original visual prompt to perturb
 * @param {number} count - Number of variations to generate (1-5)
 * @returns {Promise<string[]>} Array of prompt variation strings
 */
export async function perturbPrompt(visualPrompt, count) {
  if (!visualPrompt || count < 1) return [];

  const ai = getClient();

  const response = await ai.chat.completions.create({
    model: 'gpt-4o-mini',
    temperature: 0.9,
    messages: [
      {
        role: 'system',
        content: `You are a visual prompt variation generator. Given an original image/video generation prompt, create exactly ${count} variations that preserve the core visual concept and subject matter but vary the style, camera angle, lighting, color palette, or composition. Each variation should be a complete, self-contained prompt. Return ONLY a JSON array of strings, no other text.`,
      },
      {
        role: 'user',
        content: `Original prompt: "${visualPrompt}"\n\nGenerate ${count} variations as a JSON array of strings.`,
      },
    ],
  });

  const content = response.choices[0]?.message?.content?.trim();
  if (!content) return [];

  try {
    // Parse the JSON array from the response
    const parsed = JSON.parse(content);
    if (Array.isArray(parsed)) {
      return parsed.slice(0, count).map(String);
    }
  } catch {
    // If JSON parsing fails, try to extract prompts from the text
    // Split by numbered lines as fallback
    const lines = content.split('\n').filter((l) => l.trim().length > 0);
    return lines.slice(0, count).map((l) => l.replace(/^\d+[\.\)]\s*/, '').replace(/^["']|["']$/g, ''));
  }

  return [];
}
