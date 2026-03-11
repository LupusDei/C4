import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import { join, extname } from 'node:path';
import { writeFile, mkdir } from 'node:fs/promises';
import { generateImage } from '../services/ai-image.js';
import { generateVideo } from '../services/ai-video.js';
import { extendVideo } from '../services/video-extend.js';
import { assembleVideo } from '../services/assembly.js';
import { transcribeToSRT } from '../services/captions.js';
import { generateThumbnail } from '../services/thumbnails.js';
import config from '../config.js';
import { getCreditCost } from '../config/credit-costs.js';

/**
 * Create and start the generation worker.
 * Expects db (knex instance), wsBroadcast function, and storagePath to be passed in.
 *
 * @param {object} deps
 * @param {import('knex').Knex} deps.db - Knex database instance
 * @param {function} deps.wsBroadcast - Broadcast a message to all WebSocket clients
 * @param {string} deps.storagePath - Base path for asset storage
 * @returns {Worker}
 */
export function createGenerationWorker({ db, wsBroadcast, storagePath }) {
  const connection = new IORedis(config.redis.url, { maxRetriesPerRequest: null });

  const worker = new Worker(
    'generation',
    async (job) => {
      const { type } = job.data;

      switch (type || job.name) {
        case 'generate-image':
          return handleImageGeneration(job, { db, wsBroadcast, storagePath });
        case 'generate-video':
          return handleVideoGeneration(job, { db, wsBroadcast, storagePath });
        case 'video-extend':
          return handleVideoExtension(job, { db, wsBroadcast, storagePath });
        case 'assemble':
          return handleAssembly(job, { db, wsBroadcast, storagePath });
        default:
          throw new Error(`Unknown job type: ${type || job.name}`);
      }
    },
    {
      connection,
      concurrency: 2,
      removeOnComplete: { count: 100 },
      removeOnFail: { count: 50 },
    },
  );

  worker.on('failed', (job, err) => {
    console.error(`Job ${job?.id} failed:`, err.message);
  });

  return worker;
}

// --- Image generation handler ---

async function handleImageGeneration(job, { db, wsBroadcast, storagePath }) {
  const { jobId, assetId, projectId, prompt, provider, qualityTier, aspectRatio, sceneId, storyboardId, variationIndex } = job.data;

  broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 10, status: 'generating', storyboardId, sceneId });

  try {
    const result = await generateImage({ prompt, provider, qualityTier, aspectRatio });

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 80, status: 'saving', storyboardId, sceneId });

    // Save to storage
    const ext = result.contentType === 'image/png' ? '.png' : '.jpg';
    const assetDir = join(storagePath, 'assets', projectId, assetId);
    await mkdir(assetDir, { recursive: true });
    const filePath = join(assetDir, `image${ext}`);
    await writeFile(filePath, result.buffer);

    // Update asset record
    await db('assets').where({ id: assetId }).update({
      status: 'complete',
      file_path: filePath,
      metadata: JSON.stringify(result.metadata),
      updated_at: new Date(),
    });

    await deductCredits(db, assetId);
    await markOlderPromptsAsNotKept(db, projectId, prompt, assetId);

    // Link asset to storyboard scene if applicable
    if (sceneId) {
      await linkAssetToScene(db, sceneId, assetId, variationIndex);
    }

    broadcast(wsBroadcast, jobId, 'generation:complete', { assetId, filePath, storyboardId, sceneId });
    return { assetId, filePath };
  } catch (err) {
    await markFailed(db, assetId, err.message);
    await refundCredits(db, assetId);
    broadcast(wsBroadcast, jobId, 'generation:error', { error: err.message, storyboardId, sceneId });
    throw err;
  }
}

// --- Video generation handler ---

async function handleVideoGeneration(job, { db, wsBroadcast, storagePath }) {
  const { jobId, assetId, projectId, prompt, provider, qualityTier, duration, aspectRatio, resolution, imageUrl, sceneId, storyboardId, variationIndex } = job.data;

  broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 5, status: 'dispatching', storyboardId, sceneId });

  try {
    const { poll, metadata } = await generateVideo({
      prompt, provider, qualityTier, duration, aspectRatio, resolution, imageUrl,
    });

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 15, status: 'generating', storyboardId, sceneId });

    const result = await poll((progress) => {
      broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 15 + Math.round(progress * 0.65), status: 'generating', storyboardId, sceneId });
    });

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 85, status: 'saving', storyboardId, sceneId });

    // Save video to storage
    const assetDir = join(storagePath, 'assets', projectId, assetId);
    await mkdir(assetDir, { recursive: true });
    const videoPath = join(assetDir, 'video.mp4');
    await writeFile(videoPath, result.buffer);

    // Generate thumbnail (non-fatal if it fails)
    const thumbPath = join(assetDir, 'thumb.jpg');
    await generateThumbnail(videoPath, thumbPath).catch(() => {});

    await db('assets').where({ id: assetId }).update({
      status: 'complete',
      file_path: videoPath,
      thumbnail_path: thumbPath,
      metadata: JSON.stringify(metadata),
      updated_at: new Date(),
    });

    await deductCredits(db, assetId);
    await markOlderPromptsAsNotKept(db, projectId, prompt, assetId);

    // Link asset to storyboard scene if applicable
    if (sceneId) {
      await linkAssetToScene(db, sceneId, assetId, variationIndex);
    }

    broadcast(wsBroadcast, jobId, 'generation:complete', { assetId, filePath: videoPath, storyboardId, sceneId });
    return { assetId, filePath: videoPath };
  } catch (err) {
    await markFailed(db, assetId, err.message);
    await refundCredits(db, assetId);
    broadcast(wsBroadcast, jobId, 'generation:error', { error: err.message, storyboardId, sceneId });
    throw err;
  }
}

// --- Video extension handler ---

async function handleVideoExtension(job, { db, wsBroadcast, storagePath }) {
  const { jobId, assetId, sourceAssetId, projectId, prompt, maxDuration } = job.data;

  broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 5, status: 'preparing' });

  try {
    const source = await db('assets').where({ id: sourceAssetId }).first();
    if (!source) throw new Error(`Source asset ${sourceAssetId} not found`);

    const result = await extendVideo({
      videoUrl: source.file_path,
      prompt,
      maxDuration,
      onProgress: (progress) => {
        broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 5 + Math.round(progress * 0.8), status: 'extending' });
      },
    });

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 90, status: 'saving' });

    const assetDir = join(storagePath, 'assets', projectId, assetId);
    await mkdir(assetDir, { recursive: true });
    const videoPath = join(assetDir, 'video.mp4');
    await writeFile(videoPath, result.buffer);

    const thumbPath = join(assetDir, 'thumb.jpg');
    await generateThumbnail(videoPath, thumbPath).catch(() => {});

    await db('assets').where({ id: assetId }).update({
      status: 'complete',
      file_path: videoPath,
      thumbnail_path: thumbPath,
      metadata: JSON.stringify(result.metadata),
      updated_at: new Date(),
    });

    await deductCredits(db, assetId);

    broadcast(wsBroadcast, jobId, 'generation:complete', { assetId, filePath: videoPath });
    return { assetId, filePath: videoPath };
  } catch (err) {
    await markFailed(db, assetId, err.message);
    await refundCredits(db, assetId);
    broadcast(wsBroadcast, jobId, 'generation:error', { error: err.message });
    throw err;
  }
}

// --- Assembly handler ---

async function handleAssembly(job, { db, wsBroadcast, storagePath }) {
  const { jobId, assetId, projectId, clips, aspectRatio, enableCaptions, transition, srtContent: preGeneratedSrt, storyboardId } = job.data;

  broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 5, status: 'preparing', storyboardId });

  try {
    // Use pre-generated SRT (from storyboard script) or transcribe from audio
    let srtContent = preGeneratedSrt || null;
    if (!srtContent && enableCaptions && clips.length > 0) {
      broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 10, status: 'transcribing', storyboardId });
      // Transcribe each clip and concatenate SRT
      // For simplicity, transcribe the first clip (multi-clip SRT merging is complex)
      try {
        srtContent = await transcribeToSRT(clips[0].filePath);
      } catch {
        // Captions are non-fatal — proceed without them
        srtContent = null;
      }
    }

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 30, status: 'assembling', storyboardId });

    const result = await assembleVideo({
      clips,
      aspectRatio,
      transition,
      srtContent,
    });

    broadcast(wsBroadcast, jobId, 'generation:progress', { progress: 85, status: 'saving', storyboardId });

    // Save assembled video
    const assetDir = join(storagePath, 'assets', projectId, assetId);
    await mkdir(assetDir, { recursive: true });
    const videoPath = join(assetDir, 'assembled.mp4');
    await writeFile(videoPath, result.buffer);

    // Generate thumbnail
    const thumbPath = join(assetDir, 'thumb.jpg');
    await generateThumbnail(videoPath, thumbPath).catch(() => {});

    await db('assets').where({ id: assetId }).update({
      status: 'complete',
      file_path: videoPath,
      thumbnail_path: thumbPath,
      metadata: JSON.stringify(result.metadata),
      updated_at: new Date(),
    });

    await deductCredits(db, assetId);

    // Update storyboard status if this is a storyboard assembly
    if (storyboardId) {
      await db('storyboards').where({ id: storyboardId }).update({
        status: 'assembled',
        updated_at: new Date(),
      });
    }

    broadcast(wsBroadcast, jobId, 'generation:complete', { assetId, filePath: videoPath, storyboardId });
    return { assetId, filePath: videoPath };
  } catch (err) {
    await markFailed(db, assetId, err.message);
    await refundCredits(db, assetId);
    broadcast(wsBroadcast, jobId, 'generation:error', { error: err.message, storyboardId });
    throw err;
  }
}

// --- Shared helpers ---

function broadcast(wsBroadcast, jobId, event, data) {
  // Strip undefined fields so non-storyboard jobs don't get null storyboardId/sceneId
  const payload = { jobId };
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined) {
      payload[key] = value;
    }
  }
  wsBroadcast(event, payload);
}

/**
 * Link a generated asset to a storyboard scene.
 * If variationIndex is defined, appends to the scene's variations JSONB array.
 * Otherwise, sets the scene's primary asset_id.
 */
async function linkAssetToScene(db, sceneId, assetId, variationIndex) {
  if (variationIndex !== undefined && variationIndex !== null) {
    // Append to variations JSONB array
    await db('scenes').where({ id: sceneId }).update({
      variations: db.raw(`COALESCE(variations, '[]'::jsonb) || ?::jsonb`, [JSON.stringify([assetId])]),
      updated_at: new Date(),
    });
  } else {
    // Set primary asset
    await db('scenes').where({ id: sceneId }).update({
      asset_id: assetId,
      updated_at: new Date(),
    });
  }
}

async function deductCredits(db, assetId) {
  const asset = await db('assets').where({ id: assetId }).first();
  if (!asset) return;

  // Verify cost matches canonical credit-costs config
  const expectedCost = getCreditCost(asset.type, asset.provider, asset.quality_tier || 'standard');
  const cost = asset.credit_cost || expectedCost;

  const account = await db('credit_accounts').first();
  if (!account) return;

  await db('credit_accounts').where({ id: account.id }).decrement('balance', cost).update({ updated_at: new Date() });
  await db('credit_transactions').insert({
    account_id: account.id,
    amount: cost,
    type: 'debit',
    description: `Generation: ${asset.type} (${asset.provider || 'auto'})`,
    created_at: new Date(),
  });
}

async function refundCredits(db, assetId) {
  const asset = await db('assets').where({ id: assetId }).first();
  if (!asset || asset.credit_cost <= 0) return;

  const account = await db('credit_accounts').first();
  if (!account) return;

  await db('credit_accounts').where({ id: account.id }).increment('balance', asset.credit_cost).update({ updated_at: new Date() });
  await db('credit_transactions').insert({
    account_id: account.id,
    amount: asset.credit_cost,
    type: 'refund',
    description: `Refund: failed ${asset.type} generation`,
    created_at: new Date(),
  });
}

/**
 * Regeneration detection: if the user generates with the exact same original_prompt
 * in the same project within 5 minutes, mark the older entries as kept: false.
 */
async function markOlderPromptsAsNotKept(db, projectId, originalPrompt, currentAssetId) {
  try {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    await db('prompt_history')
      .where('project_id', projectId)
      .where('original_prompt', originalPrompt)
      .where('kept', true)
      .where('created_at', '>=', fiveMinutesAgo)
      .whereNot('asset_id', currentAssetId)
      .update({ kept: false });
  } catch (err) {
    // Non-fatal — don't fail the generation if kept tracking fails
    console.error('Failed to update kept status for older prompts:', err.message);
  }
}

async function markFailed(db, assetId, errorMessage) {
  await db('assets').where({ id: assetId }).update({
    status: 'failed',
    metadata: db.raw(`jsonb_set(COALESCE(metadata, '{}')::jsonb, '{error}', ?::jsonb)`, [JSON.stringify(errorMessage)]),
    updated_at: new Date(),
  });
}
