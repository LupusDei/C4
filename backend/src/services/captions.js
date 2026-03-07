import { createClient } from '@deepgram/sdk';
import { readFile } from 'node:fs/promises';
import config from '../config.js';

let deepgram;
function getClient() {
  if (!deepgram) {
    deepgram = createClient(config.ai.deepgramApiKey);
  }
  return deepgram;
}

/**
 * Transcribe audio/video using Deepgram Nova-3.
 * Returns word-level timestamped transcript.
 *
 * @param {Buffer} audioBuffer - Audio or video file buffer
 * @param {string} [mimetype='audio/mp4'] - MIME type of the input
 * @returns {Promise<{ words: Array<{ word: string, start: number, end: number, confidence: number }>, transcript: string }>}
 */
export async function transcribe(audioBuffer, mimetype = 'audio/mp4') {
  const client = getClient();

  const { result } = await client.listen.prerecorded.transcribeFile(
    audioBuffer,
    {
      model: 'nova-3',
      smart_format: true,
      punctuate: true,
      utterances: true,
      mimetype,
    },
  );

  const channel = result.results?.channels?.[0];
  const alternative = channel?.alternatives?.[0];

  if (!alternative) {
    throw new Error('Deepgram returned no transcription results');
  }

  const words = (alternative.words || []).map((w) => ({
    word: w.punctuated_word || w.word,
    start: w.start,
    end: w.end,
    confidence: w.confidence,
  }));

  return {
    words,
    transcript: alternative.transcript || '',
  };
}

/**
 * Convert a word-level transcript to SRT subtitle format.
 * Groups words into caption segments of ~6-8 words each.
 *
 * @param {{ words: Array<{ word: string, start: number, end: number }> }} transcript
 * @param {object} [options]
 * @param {number} [options.maxWordsPerLine=7] - Max words per caption line
 * @param {number} [options.maxDuration=4] - Max duration per caption in seconds
 * @returns {string} SRT formatted subtitles
 */
export function generateSRT(transcript, options = {}) {
  const { maxWordsPerLine = 7, maxDuration = 4 } = options;
  const { words } = transcript;

  if (!words || words.length === 0) return '';

  const segments = [];
  let currentWords = [];
  let segmentStart = words[0].start;

  for (const word of words) {
    currentWords.push(word);
    const elapsed = word.end - segmentStart;

    if (currentWords.length >= maxWordsPerLine || elapsed >= maxDuration) {
      segments.push({
        start: segmentStart,
        end: word.end,
        text: currentWords.map((w) => w.word).join(' '),
      });
      currentWords = [];
      segmentStart = word.end;
    }
  }

  // Flush remaining words
  if (currentWords.length > 0) {
    segments.push({
      start: segmentStart,
      end: currentWords[currentWords.length - 1].end,
      text: currentWords.map((w) => w.word).join(' '),
    });
  }

  return segments
    .map((seg, i) => {
      const startTC = formatTimecode(seg.start);
      const endTC = formatTimecode(seg.end);
      return `${i + 1}\n${startTC} --> ${endTC}\n${seg.text}\n`;
    })
    .join('\n');
}

/**
 * Convenience: transcribe a file and return SRT.
 *
 * @param {string} filePath - Path to audio/video file
 * @returns {Promise<string>} SRT content
 */
export async function transcribeToSRT(filePath) {
  const buffer = await readFile(filePath);
  const transcript = await transcribe(buffer);
  return generateSRT(transcript);
}

// --- Helpers ---

function formatTimecode(seconds) {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  const ms = Math.round((seconds % 1) * 1000);
  return `${pad(h)}:${pad(m)}:${pad(s)},${pad3(ms)}`;
}

function pad(n) {
  return String(n).padStart(2, '0');
}

function pad3(n) {
  return String(n).padStart(3, '0');
}
