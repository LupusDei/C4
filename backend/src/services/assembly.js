import Creatomate from 'creatomate';
import { readFile } from 'node:fs/promises';
import config from '../config.js';

let client;
function getClient() {
  if (!client) {
    client = new Creatomate.Client(config.ai.creatomateApiKey);
  }
  return client;
}

const ASPECT_DIMENSIONS = {
  '16:9': { width: 1920, height: 1080 },
  '9:16': { width: 1080, height: 1920 },
  '1:1': { width: 1080, height: 1080 },
  '4:3': { width: 1440, height: 1080 },
};

const TRANSITION_MAP = {
  none: null,
  crossfade: { type: 'crossfade', duration: 0.5 },
  fade: { type: 'fade', duration: 0.5 },
};

/**
 * Assemble multiple video clips into a single video via Creatomate.
 *
 * @param {object} params
 * @param {Array<{ filePath: string, duration?: number }>} params.clips - Ordered clip list
 * @param {string} [params.aspectRatio='16:9'] - Output aspect ratio
 * @param {string} [params.transition='none'] - Transition type between clips
 * @param {string} [params.srtContent] - Optional SRT caption content to burn in
 * @returns {Promise<{ buffer: Buffer, contentType: string, metadata: object }>}
 */
export async function assembleVideo({ clips, aspectRatio = '16:9', transition = 'none', srtContent }) {
  const api = getClient();
  const dims = ASPECT_DIMENSIONS[aspectRatio] || ASPECT_DIMENSIONS['16:9'];
  const trans = TRANSITION_MAP[transition] || null;

  // Build Creatomate render source
  const elements = [];
  let trackTime = 0;

  for (const clip of clips) {
    const element = {
      type: 'video',
      source: clip.filePath,
      time: trackTime,
      ...(clip.duration ? { duration: clip.duration } : {}),
    };

    if (trans && trackTime > 0) {
      element.transition = trans;
      // Overlap by transition duration
      element.time = Math.max(0, trackTime - (trans.duration || 0));
    }

    elements.push(element);
    trackTime += clip.duration || 5;
  }

  // Add captions track if SRT provided
  if (srtContent) {
    elements.push({
      type: 'text',
      transcript_source: 'custom',
      transcript: srtContent,
      y: '85%',
      width: '90%',
      font_family: 'Inter',
      font_weight: 700,
      font_size: '4.5 vmin',
      fill_color: '#ffffff',
      stroke_color: '#000000',
      stroke_width: '0.3 vmin',
      text_align: 'center',
      time: 0,
      duration: trackTime,
    });
  }

  const source = new Creatomate.Source({
    outputFormat: 'mp4',
    width: dims.width,
    height: dims.height,
    elements,
  });

  // Submit render and poll
  const renders = await api.render({ source });
  const render = renders[0];

  // Creatomate SDK polls automatically and resolves when done
  if (render.status === 'failed') {
    throw new Error(`Creatomate assembly failed: ${render.errorMessage || 'unknown error'}`);
  }

  // Download the rendered video
  const res = await fetch(render.url);
  if (!res.ok) throw new Error(`Failed to download assembled video: ${res.status}`);
  const buffer = Buffer.from(await res.arrayBuffer());

  return {
    buffer,
    contentType: 'video/mp4',
    metadata: {
      provider: 'creatomate',
      renderId: render.id,
      clipCount: clips.length,
      aspectRatio,
      transition,
      hasCaptions: !!srtContent,
    },
  };
}
