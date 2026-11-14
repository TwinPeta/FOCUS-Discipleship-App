const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound } = require('../utils/errors');

router.post('/', (req, res, next) => {
  try {
    const b = check(req.body, {
      platform: { required: true, type: 'string', enum: ['ios', 'android'] },
      push_token: { required: true, type: 'string', max: 500 },
      app_version: { type: 'string', max: 30 },
      locale: { type: 'string', max: 10 },
    });
    // A token belongs to one user at a time (device handed over / re-login).
    store.remove('devices', (d) => d.pushToken === b.push_token);
    const d = store.insert('devices', {
      userId: req.user.id, platform: b.platform, pushToken: b.push_token,
      appVersion: b.app_version || null, locale: b.locale || 'en',
    });
    res.status(201).json({ id: d.id });
  } catch (e) { next(e); }
});

router.delete('/:deviceId', (req, res, next) => {
  const d = store.get('devices', req.params.deviceId);
  if (!d || d.userId !== req.user.id) return next(notFound('Device'));
  store.remove('devices', (x) => x.id === d.id);
  res.status(204).end();
});

module.exports = router;
