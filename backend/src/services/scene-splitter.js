import OpenAI from 'openai';
import config from '../config.js';

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
async function splitWithLLM(scriptText) {
  const client = new OpenAI({ apiKey: config.ai.openaiApiKey });

  let response;
  try {
    response = await client.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: scriptText },
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
  const scenes = Array.isArray(parsed) ? parsed : parsed.scenes || parsed.data || parsed.result;

  if (!Array.isArray(scenes) || scenes.length === 0) {
    throw new Error('LLM did not return a valid array of scenes');
  }

  return scenes.map((scene) => ({
    narration_text: String(scene.narration_text || ''),
    visual_prompt: String(scene.visual_prompt || ''),
    duration_seconds: Number(scene.duration_seconds) || 5.0,
  }));
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
