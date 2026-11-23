const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const config = require('../config');
const store = require('../db/store');

const sockets = new Map(); // userId -> Set<ws>
let wss = null;

// The app sends its access token as a WebSocket subprotocol
// ("fcu.bearer", <token>), so it is not in the URL that proxies log. Older
// apps still send ?token=, which stays accepted.
const BEARER_PROTOCOL = 'fcu.bearer';

function tokenOf(req) {
  const offered = String(req.headers['sec-websocket-protocol'] || '')
    .split(',')
    .map((p) => p.trim())
    .filter(Boolean);
  const at = offered.indexOf(BEARER_PROTOCOL);
  if (at !== -1 && offered[at + 1]) return offered[at + 1];
  return new URL(req.url, 'http://x').searchParams.get('token');
}

function attach(server) {
  wss = new WebSocketServer({
    server,
    path: '/v1/realtime',
    // Answer with the marker only, never echo the token back.
    handleProtocols: (protocols) => (protocols.has(BEARER_PROTOCOL) ? BEARER_PROTOCOL : false),
  });
  wss.on('connection', (ws, req) => {
    let userId;
    try {
      const token = tokenOf(req);
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
