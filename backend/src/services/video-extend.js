import OpenAI from 'openai';
import ffmpeg from 'fluent-ffmpeg';
import { writeFile, unlink, mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import config from '../config.js';

const MAX_SEGMENT_DURATION = 8.7; // Grok Imagine max input video length (seconds)
const POLL_INTERVAL = 4000;
const MAX_POLLS = 150;

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

/**
 * Extend a video using Grok Imagine's continuation capability.
 * Chains multiple extension calls if maxDuration requires it.
 *
 * @param {object} params
 * @param {string} params.videoUrl - URL or local path of the source video
 * @param {string} params.prompt - Continuation description
 * @param {number} [params.maxDuration=15] - Target total duration in seconds (max 30)
 * @param {function} [params.onProgress] - Progress callback (0-100)
 * @returns {Promise<{ buffer: Buffer, contentType: string, metadata: object }>}
 */
export async function extendVideo({ videoUrl, prompt, maxDuration = 15, onProgress }) {
  const targetDuration = Math.min(maxDuration, 30);
  const tmpDir = await mkdtemp(join(tmpdir(), 'c4-extend-'));
  const tempFiles = [];

  try {
    // Download original video to temp
    let currentVideoPath = join(tmpDir, 'input.mp4');
    await downloadToFile(videoUrl, currentVideoPath);
    tempFiles.push(currentVideoPath);

    let currentDuration = await getVideoDuration(currentVideoPath);
    let iteration = 0;

    while (currentDuration < targetDuration) {
      iteration++;
      const progressBase = Math.round((currentDuration / targetDuration) * 100);
      if (onProgress) onProgress(Math.min(progressBase, 95));

      // Generate extension from current video
      const extensionBuffer = await generateExtensionClip(currentVideoPath, prompt);
      const extensionPath = join(tmpDir, `ext-${iteration}.mp4`);
      await writeFile(extensionPath, extensionBuffer);
      tempFiles.push(extensionPath);

      // Concatenate current + extension
      const concatenatedPath = join(tmpDir, `concat-${iteration}.mp4`);
      await concatenateVideos(currentVideoPath, extensionPath, concatenatedPath);
      tempFiles.push(concatenatedPath);

      currentVideoPath = concatenatedPath;
      currentDuration = await getVideoDuration(currentVideoPath);
    }

    // Read final concatenated video
    const { readFile } = await import('node:fs/promises');
    const buffer = await readFile(currentVideoPath);

    if (onProgress) onProgress(100);

    return {
      buffer,
      contentType: 'video/mp4',
      metadata: {
        provider: 'grok-imagine',
        operation: 'video-extend',
        iterations: iteration,
        finalDuration: currentDuration,
      },
    };
  } finally {
    // Clean up temp files
    for (const f of tempFiles) {
      await unlink(f).catch(() => {});
    }
    await import('node:fs/promises').then((fs) => fs.rm(tmpDir, { recursive: true, force: true })).catch(() => {});
  }
}

async function generateExtensionClip(videoPath, prompt) {
  const client = getGrok();

  // Upload or use URL — for local files, we need to read and base64 encode
  // In production the video would already be at a public URL via storage
  const videoUrl = videoPath.startsWith('http') ? videoPath : `file://${videoPath}`;

  const response = await client.post('/videos/generations', {
    body: {
      model: 'grok-imagine-video',
      prompt,
      video_url: videoUrl,
    },
  });

  const requestId = response.request_id;

  // Poll for completion
  for (let i = 0; i < MAX_POLLS; i++) {
    const status = await client.get(`/videos/${requestId}`);

    if (status.status === 'completed' || status.status === 'complete') {
      const resultUrl = status.video_url || status.output?.video_url;
      if (!resultUrl) throw new Error('Grok extension returned no video URL');
      const res = await fetch(resultUrl);
      return Buffer.from(await res.arrayBuffer());
    }

    if (status.status === 'failed') {
      throw new Error(`Grok video extension failed: ${status.error || 'unknown'}`);
    }

    await sleep(POLL_INTERVAL);
  }

  throw new Error('Grok video extension timed out');
}

function concatenateVideos(videoA, videoB, outputPath) {
  return new Promise((resolve, reject) => {
    const proc = ffmpeg(videoA)
      .input(videoB)
      .on('end', () => resolve(outputPath))
      .on('error', (err) => reject(new Error(`Concatenation failed: ${err.message}`)))
      .mergeToFile(outputPath, tmpdir());
    // mergeToFile handles demux concat with temp dir for intermediate files
  });
}

function getVideoDuration(videoPath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(videoPath, (err, metadata) => {
      if (err) return reject(new Error(`ffprobe failed: ${err.message}`));
      resolve(metadata.format.duration || 0);
    });
  });
}

async function downloadToFile(url, destPath) {
  if (url.startsWith('file://')) {
    const { copyFile } = await import('node:fs/promises');
    await copyFile(url.replace('file://', ''), destPath);
    return;
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to download video: ${res.status}`);
  const buffer = Buffer.from(await res.arrayBuffer());
  await writeFile(destPath, buffer);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export { MAX_SEGMENT_DURATION };
