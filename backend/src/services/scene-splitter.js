import OpenAI from 'openai';
import config from '../config.js';

let client;
function getClient() {
  if (!client) {
    client = new OpenAI({ apiKey: config.ai.openaiApiKey });
  }
  return client;
}

const SYSTEM_PROMPT = `You are a professional script analyst and storyboard planner. Your job is to break a script into individual scenes for a storyboard.

For each scene, provide:
1. narration_text: The dialogue, narration, or voiceover text for that scene. Keep the original wording as much as possible.
2. visual_prompt: A detailed visual description suitable for AI image/video generation. Describe the setting, characters, actions, lighting, camera angle, and mood. Be specific and vivid.
3. duration_seconds: Estimated duration in seconds for this scene (typically 3-15 seconds).

Rules:
- Split at natural scene boundaries (location changes, topic shifts, dramatic beats).
- Each scene should be a self-contained visual moment.
- Visual prompts should be detailed enough for an AI image generator to produce a relevant image.
- Duration should reflect the amount of narration/action in the scene.
- Maximum 20 scenes.
- Return valid JSON only — no markdown, no explanation, no code fences.

Return a JSON array of objects with exactly these keys: narration_text, visual_prompt, duration_seconds.

Example output:
[
  {
    "narration_text": "Welcome to the world of tomorrow.",
    "visual_prompt": "A futuristic cityscape at dawn, gleaming skyscrapers with holographic billboards, flying vehicles in the sky, warm golden light breaking through clouds, wide establishing shot.",
    "duration_seconds": 5
  }
]`;

/**
 * Split a script into scenes using an LLM.
 *
 * Uses OpenAI if OPENAI_API_KEY is configured, otherwise falls back to
 * a simple heuristic paragraph-based splitter.
 *
 * @param {string} scriptText - The full script/narration text to split
 * @returns {Promise<Array<{narration_text: string, visual_prompt: string, duration_seconds: number}>>}
 */
export async function splitScript(scriptText) {
  if (!scriptText || scriptText.trim().length === 0) {
    throw new Error('Script text is empty');
  }

  if (config.ai.openaiApiKey) {
    return splitWithLLM(scriptText);
  }

  return splitWithHeuristic(scriptText);
}

/**
 * Split script using OpenAI chat completions with structured output.
 */
/**
 * Sanitize user script text to prevent prompt injection.
 * Strips patterns that look like system prompt overrides.
 */
function sanitizeScriptText(text) {
  return text
    .replace(/\[system\]/gi, '[filtered]')
    .replace(/\[INST\]/gi, '[filtered]')
    .replace(/<<SYS>>.*?<<\/SYS>>/gs, '')
    .replace(/system\s*:\s*/gi, '')
    .replace(/you are now/gi, 'the character is now')
    .replace(/ignore (all )?(previous|above|prior) instructions/gi, '')
    .replace(/disregard (all )?(previous|above|prior) instructions/gi, '')
    .replace(/forget (all )?(previous|above|prior) instructions/gi, '');
}

async function splitWithLLM(scriptText) {
  const ai = getClient();

  const sanitized = sanitizeScriptText(scriptText);

  let response;
  try {
    response = await ai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: `Please split the following script into scenes.\n\n---BEGIN SCRIPT---\n${sanitized}\n---END SCRIPT---`,
        },
      ],
      temperature: 0.3,
      response_format: { type: 'json_object' },
    });
  } catch (err) {
    throw new Error(`LLM API call failed: ${err.message}`);
  }

  const content = response.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error('LLM returned empty response');
  }

  let parsed;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new Error('LLM returned malformed JSON');
  }

  // The model may wrap the array in an object like { scenes: [...] }
  let scenes = Array.isArray(parsed) ? parsed : parsed.scenes || parsed.data || parsed.result;

  if (!Array.isArray(scenes) || scenes.length === 0) {
    throw new Error('LLM did not return a valid array of scenes');
  }

  // Cap at 20 scenes maximum
  let truncated = false;
  if (scenes.length > 20) {
    scenes = scenes.slice(0, 20);
    truncated = true;
  }

  const result = scenes.map((scene) => ({
    narration_text: String(scene.narration_text || ''),
    visual_prompt: String(scene.visual_prompt || ''),
    duration_seconds: Number(scene.duration_seconds) || 5.0,
  }));

  if (truncated) {
    result[result.length - 1].narration_text += ' [Note: Script was truncated to 20 scenes maximum]';
  }

  return result;
}

/**
 * Fallback heuristic splitter: splits on double newlines (paragraphs)
 * and generates basic visual prompts from the text.
 */
function splitWithHeuristic(scriptText) {
  const paragraphs = scriptText
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  if (paragraphs.length === 0) {
    // Single block of text — treat the whole thing as one scene
    return [{
      narration_text: scriptText.trim(),
      visual_prompt: `Visual scene depicting: ${scriptText.trim().substring(0, 200)}`,
      duration_seconds: Math.max(5, Math.min(15, Math.ceil(scriptText.trim().split(/\s+/).length / 3))),
    }];
  }

  return paragraphs.map((paragraph) => {
    const wordCount = paragraph.split(/\s+/).length;
    const duration = Math.max(3, Math.min(15, Math.ceil(wordCount / 3)));

    return {
      narration_text: paragraph,
      visual_prompt: `Visual scene depicting: ${paragraph.substring(0, 300)}`,
      duration_seconds: duration,
    };
  });
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
