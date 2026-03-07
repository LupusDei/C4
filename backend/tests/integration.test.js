import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildTestApp } from './setup.js';

let app, store, jobs;

before(async () => {
  ({ fastify: app, store, jobs } = await buildTestApp());
});

after(async () => {
  await app.close();
});

// --- Credit flow tests ---

describe('Credit flow', () => {
  it('GET /api/credits/balance returns current balance', async () => {
    const res = await app.inject({ method: 'GET', url: '/api/credits/balance' });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.equal(body.balance, 100);
    assert.ok(body.account_id);
  });

  it('POST /api/credits/allocate is idempotent', async () => {
    const res = await app.inject({ method: 'POST', url: '/api/credits/allocate' });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.equal(body.created, false);
    assert.equal(body.balance, 100);
  });
});

// --- Project CRUD tests ---

describe('Project CRUD', () => {
  let projectId;

  it('POST /api/projects creates a project', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/projects',
      payload: { title: 'Test Project', description: 'A test project' },
    });
    assert.equal(res.statusCode, 201);
    const body = JSON.parse(res.body);
    assert.ok(body.id);
    assert.equal(body.title, 'Test Project');
    projectId = body.id;
  });

  it('GET /api/projects lists projects', async () => {
    const res = await app.inject({ method: 'GET', url: '/api/projects' });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.ok(Array.isArray(body));
    assert.ok(body.length >= 1);
  });

  it('GET /api/projects/:id returns a project', async () => {
    const res = await app.inject({ method: 'GET', url: `/api/projects/${projectId}` });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.equal(body.id, projectId);
    assert.equal(body.title, 'Test Project');
  });

  it('PUT /api/projects/:id updates a project', async () => {
    const res = await app.inject({
      method: 'PUT',
      url: `/api/projects/${projectId}`,
      payload: { title: 'Updated Project' },
    });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.equal(body.title, 'Updated Project');
  });

  it('DELETE /api/projects/:id deletes a project', async () => {
    const res = await app.inject({ method: 'DELETE', url: `/api/projects/${projectId}` });
    assert.equal(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.equal(body.message, 'Project deleted');
  });

  it('GET /api/projects/:id returns 404 for deleted project', async () => {
    const res = await app.inject({ method: 'GET', url: `/api/projects/${projectId}` });
    assert.equal(res.statusCode, 404);
  });
});

// --- Image generation route tests ---

describe('POST /api/generate/image', () => {
  let projectId;

  before(async () => {
    // Create a project for generation tests
    const res = await app.inject({
      method: 'POST',
      url: '/api/projects',
      payload: { title: 'Gen Project' },
    });
    projectId = JSON.parse(res.body).id;
  });

  it('returns 202 with jobId and assetId', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/generate/image',
      payload: {
        prompt: 'A beautiful sunset over mountains',
        projectId,
        qualityTier: 'standard',
      },
    });
    assert.equal(res.statusCode, 202);
    const body = JSON.parse(res.body);
    assert.ok(body.jobId);
    assert.ok(body.assetId);
    assert.equal(body.status, 'queued');
  });

  it('dispatches a BullMQ job', async () => {
    const lastJob = jobs[jobs.length - 1];
    assert.equal(lastJob.name, 'generate-image');
    assert.equal(lastJob.data.prompt, 'A beautiful sunset over mountains');
    assert.equal(lastJob.data.projectId, projectId);
  });

  it('creates a pending asset in DB', async () => {
    const asset = store.assets.find((a) => a.type === 'image' && a.status === 'pending');
    assert.ok(asset);
    assert.equal(asset.project_id, projectId);
  });

  it('returns 402 when credits are insufficient', async () => {
    // Drain credits
    store.credit_accounts[0].balance = 0;

    const res = await app.inject({
      method: 'POST',
      url: '/api/generate/image',
      payload: {
        prompt: 'Should fail',
        projectId,
        qualityTier: 'premium',
      },
    });
    assert.equal(res.statusCode, 402);
    const body = JSON.parse(res.body);
    assert.equal(body.error, 'insufficient_credits');

    // Restore credits for other tests
    store.credit_accounts[0].balance = 100;
  });

  it('validates required fields', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/generate/image',
      payload: { qualityTier: 'standard' },
    });
    assert.equal(res.statusCode, 400);
  });
});

// --- Video generation route tests ---

describe('POST /api/generate/video', () => {
  let projectId;

  before(async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/projects',
      payload: { title: 'Video Project' },
    });
    projectId = JSON.parse(res.body).id;
  });

  it('returns 202 with jobId for text-to-video', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/generate/video',
      payload: {
        prompt: 'A car driving through a city',
        projectId,
        duration: 5,
        qualityTier: 'standard',
      },
    });
    assert.equal(res.statusCode, 202);
    const body = JSON.parse(res.body);
    assert.ok(body.jobId);
    assert.ok(body.assetId);
  });

  it('dispatches a generate-video BullMQ job', async () => {
    const videoJobs = jobs.filter((j) => j.name === 'generate-video');
    assert.ok(videoJobs.length >= 1);
    const last = videoJobs[videoJobs.length - 1];
    assert.equal(last.data.prompt, 'A car driving through a city');
    assert.equal(last.data.duration, 5);
  });
});

// --- Retry utility tests ---

describe('withRetry', () => {
  it('retries on 429 and succeeds', async () => {
    const { withRetry } = await import('../src/lib/retry.js');
    let attempts = 0;
    const result = await withRetry(async () => {
      attempts++;
      if (attempts < 3) {
        const err = new Error('Rate limited');
        err.status = 429;
        throw err;
      }
      return 'ok';
    }, { maxAttempts: 3, baseDelay: 10 });

    assert.equal(result, 'ok');
    assert.equal(attempts, 3);
  });

  it('does not retry on 400 client error', async () => {
    const { withRetry } = await import('../src/lib/retry.js');
    let attempts = 0;
    await assert.rejects(async () => {
      await withRetry(async () => {
        attempts++;
        const err = new Error('Bad request');
        err.status = 400;
        throw err;
      }, { maxAttempts: 3, baseDelay: 10 });
    }, { message: 'Bad request' });

    assert.equal(attempts, 1);
  });

  it('retries on 500 server error', async () => {
    const { withRetry } = await import('../src/lib/retry.js');
    let attempts = 0;
    const result = await withRetry(async () => {
      attempts++;
      if (attempts < 2) {
        const err = new Error('Server error');
        err.status = 500;
        throw err;
      }
      return 'recovered';
    }, { maxAttempts: 3, baseDelay: 10 });

    assert.equal(result, 'recovered');
    assert.equal(attempts, 2);
  });
});
