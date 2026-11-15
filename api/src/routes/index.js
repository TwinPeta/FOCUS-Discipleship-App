const router = require('express').Router();
const { authenticate } = require('../middleware/auth');
const { activeSuspension } = require('../utils/sanctions');

// Public
router.use('/public', require('./landing'));
router.use('/auth', require('./auth'));
router.use('/lookups', require('./lookups'));

router.use('/admin', require('../admin'));
router.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Everything below requires a valid access token
router.use(authenticate);
// A suspended student can still read (and see why), but cannot post, message, join or change anything until it ends.
router.use((req, _res, next) => {
  if (req.user.suspended && !['GET', 'HEAD'].includes(req.method) && activeSuspension(req.user)) {
    return next(require('../utils/errors').forbidden('account_suspended', 'Your account is suspended'));
  }
  next();
});
router.use(require('./media').confirmReferenced); // verifies R2 uploads referenced by media_ids / photo_media_id
router.use('/me', require('./me'));
router.use('/pathways', require('./pathways'));
router.use('/media', require('./media'));
router.use('/devices', require('./devices'));
router.use('/', require('./communities'));
router.use('/', require('./posts'));
router.use('/', require('./prayer'));
router.use('/', require('./testimonies'));
router.use('/', require('./resources'));
router.use('/', require('./messages'));
router.use('/', require('./safety'));
router.use('/', require('./meetings'));
router.use('/', require('./moderation'));

module.exports = router;
