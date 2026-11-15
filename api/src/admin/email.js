// Lets a system administrator see why email is (not) working without server access.
const router = require('express').Router();
const mailer = require('../services/mailer');
const { ApiError, validation } = require('../utils/errors');
const { check } = require('../utils/validate');
const C = require('./core');

router.get('/email/status', C.allow(C.SYS), (_req, res) => res.json(mailer.status()));

// Sends one real email and answers with Resend's own result, so a wrong key, an unverified sender or a bad address is spelled out.
router.post('/email/test', C.allow(C.SYS), async (req, res, next) => {
  try {
    const b = check(req.body || {}, { to: { type: 'string', email: true } });
    const to = b.to || req.user.email;
    if (!to) throw validation([{ field: 'to', message: 'is required' }]);
    try {
      const out = await mailer.sendTest(to, req.user.fullName);
      res.json({ ok: true, to, id: out.id || null });
    } catch (e) {
      throw new ApiError(502, 'email_failed', 'Email could not be sent', e.message);
    }
  } catch (e) { next(e); }
});

module.exports = { router };
