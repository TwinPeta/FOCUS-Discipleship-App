// Phone push through Firebase Cloud Messaging (HTTP v1). No Firebase library: the service-account key signs a short JWT
// (node crypto), which is traded for an access token, and each message is one POST. FCM then delivers to Android and,
// when an APNs key is added in the Firebase console, to iPhones.
// Not configured -> every call is a quiet no-op, so the rest of the app never depends on it.
const crypto = require('crypto');
const fs = require('fs');
const config = require('../config');
const store = require('../db/store');

const CHANNEL = 'fcu_general'; // the Android channel the app creates (mobile/lib/core/push/push_service.dart)
const outbox = []; // tests: what would have been sent
const recent = []; // last results, for the back-office status card
const record = (e) => { recent.unshift({ at: new Date().toISOString(), ...e }); recent.length = Math.min(recent.length, 20); };
const mask = (id) => `${String(id).slice(0, 6)}...`;

let fetchImpl = (...a) => fetch(...a);
const useFetch = (f) => { fetchImpl = f || ((...a) => fetch(...a)); token = null; };

let accountCache; // undefined = not read yet; null = not configured
function account() {
  if (accountCache !== undefined) return accountCache;
  accountCache = null;
  try {
    const raw = config.fcm.serviceAccountJson || (config.fcm.serviceAccountFile && fs.readFileSync(config.fcm.serviceAccountFile, 'utf8')) || '';
    if (raw) {
      const j = JSON.parse(raw);
      if (j.client_email && j.private_key && j.project_id) accountCache = { email: j.client_email, key: String(j.private_key).replace(/\\n/g, '\n'), project: j.project_id };
      else console.error('[push] the service account key is missing client_email, private_key or project_id');
    }
  } catch (e) { console.error('[push] cannot read the service account key:', e.message); }
  return accountCache;
}
/** Test hook: re-read the configuration. */
const reset = () => { accountCache = undefined; token = null; };
const enabled = () => !!account() && config.fcm.enabled;

const b64 = (o) => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o)).toString('base64url');
let token = null; // { value, exp }
async function accessToken() {
  if (token && token.exp > Date.now() + 60e3) return token.value;
  const a = account();
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({ iss: a.email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3600 })}`;
  const sig = crypto.createSign('RSA-SHA256').update(unsigned).sign(a.key).toString('base64url');
  const res = await fetchImpl('https://oauth2.googleapis.com/token', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${sig}` }),
  });
  const j = await res.json().catch(() => ({}));
  if (!res.ok || !j.access_token) throw new Error(`Google sign-in failed: ${j.error_description || j.error || res.status}`);
  token = { value: j.access_token, exp: Date.now() + (j.expires_in || 3600) * 1000 };
  return token.value;
}

// FCM says the token is dead (app uninstalled, token rotated): the device is forgotten so we stop trying.
const DEAD = new Set(['UNREGISTERED', 'INVALID_ARGUMENT', 'NOT_FOUND', 'SENDER_ID_MISMATCH']);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/** One message to one device token. Returns { ok, dead, error }. Retries rate limits and server errors. */
async function sendToken(deviceToken, { title, body, data }) {
  const message = {
    token: deviceToken,
    notification: { title, ...(body ? { body } : {}) },
    data: Object.fromEntries(Object.entries(data || {}).map(([k, v]) => [k, String(v)])), // FCM wants strings
    android: { priority: 'HIGH', notification: { channel_id: CHANNEL } },
    apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
  };
  let last = 'unknown error';
  for (let attempt = 0; attempt < 3; attempt++) {
    if (attempt) await wait((config.env === 'test' ? 1 : 1000) * 2 ** (attempt - 1));
    const res = await fetchImpl(`https://fcm.googleapis.com/v1/projects/${account().project}/messages:send`, {
      method: 'POST', headers: { Authorization: `Bearer ${await accessToken()}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ message }),
    });
    if (res.ok) return { ok: true };
    const j = await res.json().catch(() => ({}));
    const err = (j.error && j.error.details || []).map((d) => d.errorCode).find(Boolean) || (j.error && j.error.status) || '';
    last = (j.error && j.error.message) || `HTTP ${res.status}`;
    if (res.status === 401) token = null; // expired: sign in again next attempt
    else if (DEAD.has(err) || res.status === 404) return { ok: false, dead: true, error: last };
    else if (res.status !== 429 && res.status < 500) return { ok: false, error: last };
  }
  return { ok: false, error: last };
}

/** Pushes to every device a user has registered. Never throws. Returns { sent, failed, devices }. */
async function sendToUser(userId, payload) {
  const devices = store.where('devices', (d) => d.userId === userId);
  const result = { sent: 0, failed: 0, devices: devices.length };
  if (!devices.length) return result;
  if (config.env === 'test') { devices.forEach((d) => outbox.push({ userId, platform: d.platform, ...payload })); result.sent = devices.length; return result; }
  if (!enabled()) return result;
  for (const d of devices) {
    try {
      const r = await sendToken(d.pushToken, payload);
      if (r.ok) result.sent++; else { result.failed++; if (r.dead) store.remove('devices', (x) => x.id === d.id); }
      record({ user: mask(userId), platform: d.platform, ok: r.ok, ...(r.error ? { error: r.dead ? `${r.error} (device removed)` : r.error } : {}) });
    } catch (e) {
      result.failed++;
      record({ user: mask(userId), platform: d.platform, ok: false, error: e.message });
    }
  }
  return result;
}

// Fire and forget, in order: a slow push must never slow the request that caused it.
let tail = Promise.resolve();
function notifyUser(userId, payload) {
  if (config.env !== 'test' && !enabled()) return;
  tail = tail.then(() => sendToUser(userId, payload)).catch((e) => console.error('[push] failed:', e.message));
  if (config.env === 'test') tail.catch(() => {});
}

function status() {
  const devices = store.col('devices');
  return {
    configured: !!account(),
    enabled: enabled(),
    projectId: account() ? account().project : null,
    devices: { total: devices.length, android: devices.filter((d) => d.platform === 'android').length, ios: devices.filter((d) => d.platform === 'ios').length },
    recent: recent.slice(),
  };
}

const flush = () => tail; // tests: wait for queued pushes

module.exports = { enabled, status, flush, sendToUser, notifyUser, sendToken, useFetch, reset, outbox, recent, CHANNEL };
