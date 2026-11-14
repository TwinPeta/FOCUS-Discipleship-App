const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const config = require('../config');
const store = require('../db/store');

const sockets = new Map(); // userId -> Set<ws>
let wss = null;

function attach(server) {
  wss = new WebSocketServer({ server, path: '/v1/realtime' });
  wss.on('connection', (ws, req) => {
    let userId;
    try {
      const token = new URL(req.url, 'http://x').searchParams.get('token');
      userId = jwt.verify(token, config.jwtSecret).sub;
      if (!store.get('users', userId)) throw new Error('no user');
    } catch {
      ws.close(4401, 'unauthorized');
      return;
    }
    if (!sockets.has(userId)) sockets.set(userId, new Set());
    sockets.get(userId).add(ws);
    broadcastPresence(userId);
    ws.on('close', () => {
      const set = sockets.get(userId);
      if (set) { set.delete(ws); if (!set.size) sockets.delete(userId); }
      broadcastPresence(userId);
    });
    ws.on('error', () => {});
  });
  return wss;
}

const isOnline = (userId) => sockets.has(userId);

function emit(userId, event, data) {
  const set = sockets.get(userId);
  if (!set) return false;
  const payload = JSON.stringify({ event, data, at: new Date().toISOString() });
  set.forEach((ws) => ws.readyState === 1 && ws.send(payload));
  return true;
}

function onlineCount(communityId) {
  return store
    .where('memberships', (m) => m.communityId === communityId && m.status === 'member')
    .filter((m) => isOnline(m.userId)).length;
}

function broadcastPresence(userId) {
  store
    .where('memberships', (m) => m.userId === userId && m.status === 'member')
    .forEach((m) => {
      const count = onlineCount(m.communityId);
      store
        .where('memberships', (x) => x.communityId === m.communityId && x.status === 'member')
        .forEach((x) => emit(x.userId, 'presence.updated', { community_id: m.communityId, online_count: count }));
    });
}

module.exports = { attach, emit, isOnline, onlineCount };
