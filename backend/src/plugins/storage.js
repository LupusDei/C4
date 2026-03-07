import fp from 'fastify-plugin';
import { mkdir, writeFile, unlink, access } from 'node:fs/promises';
import { join } from 'node:path';
import config from '../config.js';

async function storage(fastify) {
  const basePath = config.storage.path;

  async function ensureDir(projectId) {
    const dir = join(basePath, 'assets', projectId);
    await mkdir(dir, { recursive: true });
    return dir;
  }

  async function saveFile(projectId, assetId, ext, buffer) {
    const dir = await ensureDir(projectId);
    const filePath = join(dir, `${assetId}.${ext}`);
    await writeFile(filePath, buffer);
    return filePath;
  }

  function getFilePath(projectId, assetId, ext) {
    return join(basePath, 'assets', projectId, `${assetId}.${ext}`);
  }

  async function deleteFile(filePath) {
    try {
      await access(filePath);
      await unlink(filePath);
    } catch {
      // File doesn't exist, nothing to delete
    }
  }

  fastify.decorate('storage', { saveFile, getFilePath, deleteFile, ensureDir });
  fastify.log.info({ path: basePath }, 'Storage initialized');
}

export default fp(storage, { name: 'storage' });
