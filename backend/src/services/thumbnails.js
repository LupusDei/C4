import ffmpeg from 'fluent-ffmpeg';
import { mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';

/**
 * Extract a thumbnail frame from a video file.
 *
 * @param {string} videoPath - Absolute path to the source video
 * @param {string} outputPath - Absolute path for the output JPEG thumbnail
 * @param {object} [options]
 * @param {number} [options.timestamp=1] - Timestamp in seconds to extract
 * @param {string} [options.size='480x?'] - Output size (width x height, ? = auto)
 * @returns {Promise<string>} The outputPath on success
 */
export async function generateThumbnail(videoPath, outputPath, options = {}) {
  const { timestamp = 1, size = '480x?' } = options;

  await mkdir(dirname(outputPath), { recursive: true });

  return new Promise((resolve, reject) => {
    ffmpeg(videoPath)
      .screenshots({
        timestamps: [timestamp],
        filename: 'thumb.jpg',
        folder: dirname(outputPath),
        size,
      })
      .on('end', () => {
        // fluent-ffmpeg writes to folder/thumb.jpg — rename if outputPath differs
        const actual = `${dirname(outputPath)}/thumb.jpg`;
        if (actual !== outputPath) {
          import('node:fs').then((fs) => {
            fs.renameSync(actual, outputPath);
            resolve(outputPath);
          });
        } else {
          resolve(outputPath);
        }
      })
      .on('error', (err) => reject(new Error(`Thumbnail generation failed: ${err.message}`)));
  });
}
