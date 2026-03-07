/**
 * Wrap an async function with retry logic using exponential backoff + jitter.
 * Only retries on 429 (rate limit) and 5xx (server) errors.
 *
 * @param {function} fn - Async function to retry
 * @param {object} [options]
 * @param {number} [options.maxAttempts=3] - Maximum number of attempts
 * @param {number} [options.baseDelay=1000] - Base delay in ms (doubles each retry)
 * @returns {Promise<*>} Result of fn()
 */
export async function withRetry(fn, { maxAttempts = 3, baseDelay = 1000 } = {}) {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;

      if (attempt === maxAttempts || !isRetryable(err)) {
        throw err;
      }

      const delay = baseDelay * Math.pow(2, attempt - 1);
      const jitter = Math.random() * delay * 0.5;
      await sleep(delay + jitter);
    }
  }

  throw lastError;
}

function isRetryable(err) {
  const status = err.status || err.statusCode || err.response?.status;

  // Rate limited
  if (status === 429) return true;

  // Server errors
  if (status >= 500 && status < 600) return true;

  // Network errors (no status code)
  if (err.code === 'ECONNRESET' || err.code === 'ETIMEDOUT' || err.code === 'ECONNREFUSED') {
    return true;
  }

  // fetch errors
  if (err.cause?.code === 'ECONNRESET' || err.cause?.code === 'ETIMEDOUT') {
    return true;
  }

  return false;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
