import fp from 'fastify-plugin';
import websocket from '@fastify/websocket';
import { randomUUID } from 'node:crypto';

async function ws(fastify) {
  await fastify.register(websocket);

  const clients = new Map();

  function broadcast(event, data) {
    const message = JSON.stringify({ event, data });
    for (const [, socket] of clients) {
      if (socket.readyState === 1) {
        socket.send(message);
      }
    }
  }

  function sendToClient(clientId, event, data) {
    const socket = clients.get(clientId);
    if (socket && socket.readyState === 1) {
      socket.send(JSON.stringify({ event, data }));
    }
  }

  fastify.register(async function (app) {
    app.get('/ws', { websocket: true }, (socket, req) => {
      const clientId = randomUUID();
      clients.set(clientId, socket);
      fastify.log.info({ clientId }, 'WebSocket client connected');

      socket.send(JSON.stringify({ event: 'connected', data: { clientId } }));

      socket.on('close', () => {
        clients.delete(clientId);
        fastify.log.info({ clientId }, 'WebSocket client disconnected');
      });

      socket.on('error', (err) => {
        fastify.log.error({ clientId, err }, 'WebSocket error');
        clients.delete(clientId);
      });
    });
  });

  fastify.decorate('ws', { broadcast, sendToClient, clients });
}

export default fp(ws, { name: 'websocket' });
