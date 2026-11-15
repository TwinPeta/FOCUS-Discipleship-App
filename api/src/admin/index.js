// Back-office (staff) API, mounted at /v1/admin. Point the back office at it with
// API_BASE_URL=http://<host>/v1/admin (its proxy appends the path the screens call).
const router = require('express').Router();
const { router: auth } = require('./auth');
const C = require('./core');

router.use('/auth', auth);               // login / logout / forgot / reset are public; /auth/me is guarded inside
router.use(C.adminAuth);
router.use('/', require('./people').router);
router.use('/', require('./content').router);
router.use('/', require('./governance').router);
router.use('/', require('./media').router);

module.exports = router;
