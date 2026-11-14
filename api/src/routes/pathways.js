const router = require('express').Router();
const store = require('../db/store');
const { notFound, conflict, forbidden, validation } = require('../utils/errors');
const P = require('../utils/pathways');

const load = (req, _res, next) => {
  const p = store.get('pathways', req.params.pathwayId);
  if (!p) return next(notFound('Pathway'));
  req.pathway = p;
  next();
};

router.get('/', (req, res) => {
  const items = store.col('pathways').map((p) => P.summary(p, req.user.id));
  res.json({ current: items.find((p) => p.status === 'in_progress') || null, items });
});

router.get('/:pathwayId', load, (req, res) => res.json(P.detail(req.pathway, req.user.id)));

router.put('/:pathwayId/enrollment', load, (req, res, next) => {
  try {
    const s = P.summary(req.pathway, req.user.id);
    if (s.status === 'locked') throw forbidden('pathway_locked', s.unlock_hint);
    if (s.status === 'in_progress' || s.status === 'completed') throw conflict('already_enrolled', 'You already started this pathway');
    store.insert('pathwayProgress', { userId: req.user.id, pathwayId: req.pathway.id, completedStepIds: [] });
    res.json(P.summary(req.pathway, req.user.id));
  } catch (e) { next(e); }
});

router.post('/:pathwayId/steps/:stepId/complete', load, (req, res, next) => {
  try {
    const step = req.pathway.steps.find((s) => s.id === req.params.stepId);
    if (!step) throw notFound('Step');
    if (!P.progressOf(req.user.id, req.pathway.id)) throw conflict('not_enrolled', 'Start the pathway first');
    if (step.type === 'quiz') {
      const passed = store.first('quizAttempts', (a) => a.userId === req.user.id && a.quizId === step.resourceId && a.passed);
      if (!passed) throw validation([{ field: 'step', message: 'Quiz steps complete by passing the quiz' }]);
    }
    res.json(P.completeStep(req.user.id, req.pathway, step.id));
  } catch (e) { next(e); }
});

module.exports = router;
