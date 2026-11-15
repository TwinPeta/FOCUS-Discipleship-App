// Lets a system administrator see whether phone push is set up and send a test to their own phone.
const router = require('express').Router();
const push = require('../services/push');
const store = require('../db/store');
const { ApiError } = require('../utils/errors');
const C = require('./core');

router.get('/push/status', C.allow(C.SYS), (_req, res) => res.json(push.status()));

// Sends a real push to the signed-in administrator's registered phones and says exactly what happened.
router.post('/push/test', C.allow(C.SYS), async (req, res, next) => {
  try {
    if (!push.enabled()) throw new ApiError(409, 'push_not_configured', 'Push is not set up', 'Set FCM_SERVICE_ACCOUNT_JSON (or FCM_SERVICE_ACCOUNT_FILE) on the server and restart it. See the README, "Phone push".');
    const devices = store.where('devices', (d) => d.userId === req.user.id);
    if (!devices.length) throw new ApiError(409, 'no_device', 'No phone registered', 'Sign in to the student app on a phone with this account first, and allow notifications; the phone registers itself.');
    const out = await push.sendToUser(req.user.id, { title: 'FCU test notification', body: 'If you can read this on your phone, push works.', data: { type: 'announcement', target_route: '/notifications' } });
    if (!out.sent) throw new ApiError(502, 'push_failed', 'Push could not be delivered', (push.status().recent[0] || {}).error || 'The push service refused the message.');
    res.json({ ok: true, sent: out.sent, failed: out.failed });
  } catch (e) { next(e); }
});

module.exports = { router };
