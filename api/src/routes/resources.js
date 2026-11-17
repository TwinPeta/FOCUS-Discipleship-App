const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, validation } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember } = require('../middleware/auth');
const { logEvent, awardBadge } = require('../utils/activity');
const { onQuizPassed } = require('../utils/pathways');
const S = require('../utils/serialize');

const TYPES = ['video', 'devotional', 'quiz', 'document'];

// Resources are visible to members of the owning community, or to anyone for general-library items.
function canSee(resource, userId) {
  return store.first('memberships', (m) => m.communityId === resource.communityId && m.userId === userId && m.status === 'member');
}
function loadResource(req, _res, next) {
  const r = store.get('resources', req.params.resourceId);
  if (!r || r.status !== 'published' || !canSee(r, req.user.id)) return next(notFound('Resource'));
  req.resource = r;
  next();
}

router.get('/communities/:communityId/resources', requireMember, (req, res, next) => {
  try {
    const { type, category, q, tag, bible_book: book } = req.query;
    check({ type, category }, { type: { enum: TYPES }, category: { enum: ['bible_characters', 'bible_texts'] } });
    const needle = q ? String(q).toLowerCase() : null;
    const items = store.where('resources', (r) =>
      r.communityId === req.community.id && r.status === 'published' &&
      (!type || r.type === type) && (!category || r.category === category) &&
      (!tag || (r.tags || []).includes(tag)) &&
      (!book || (r.bibleBook || '').toLowerCase() === String(book).toLowerCase()) &&
      (!needle || r.title.toLowerCase().includes(needle) || (r.tags || []).some((t) => t.includes(needle)))
    ).sort(byNewest);
    const page = paginate(items, req.query);
    res.json({ items: page.items.map((r) => S.resource(r, req.user.id)), next_cursor: page.next_cursor });
  } catch (e) { next(e); }
});

router.get('/resources/:resourceId', loadResource, (req, res) => {
  res.json(S.resource(req.resource, req.user.id, { detail: true }));
});

router.put('/resources/:resourceId/progress', loadResource, (req, res, next) => {
  try {
    const b = check(req.body, { position_seconds: { type: 'number' }, completed: { type: 'boolean' } });
    let rec = store.first('resourceProgress', (p) => p.resourceId === req.resource.id && p.userId === req.user.id);
    if (!rec) rec = store.insert('resourceProgress', { resourceId: req.resource.id, userId: req.user.id, positionSeconds: 0, completed: false });
    if (b.position_seconds !== undefined) rec.positionSeconds = Math.max(0, Math.floor(b.position_seconds));
    if (b.completed === true && !rec.completed) {
      rec.completed = true;
      logEvent(req.user.id, req.resource.type === 'video' ? 'video_watched' : 'resource_completed',
        `${req.resource.type === 'video' ? 'Watched' : 'Completed'} ${req.resource.title}`);
    }
    res.status(204).end();
  } catch (e) { next(e); }
});

function loadQuiz(req, _res, next) {
  const quiz = store.get('quizzes', req.params.quizId);
  const r = store.get('resources', req.params.quizId);
  if (!quiz || !r || !canSee(r, req.user.id)) return next(notFound('Quiz'));
  req.quiz = quiz;
  next();
}

/** The caller's most recent attempt (their own choices and score; the correct answers are never sent). */
function lastAttempt(quizId, userId) {
  const a = store.where('quizAttempts', (x) => x.quizId === quizId && x.userId === userId)
    .sort((x, y) => String(y.createdAt).localeCompare(String(x.createdAt)))[0];
  if (!a) return null;
  return {
    score: a.score, total: a.total, passed: !!a.passed, created_at: a.createdAt,
    answers: (a.answers || []).map((x) => ({ question_id: x.questionId, option_id: x.optionId })),
  };
}

router.get('/quizzes/:quizId', loadQuiz, (req, res) => {
  res.json({
    id: req.quiz.id,
    title: req.quiz.title,
    pass_mark_percent: req.quiz.passMarkPercent,
    questions: req.quiz.questions.map((q) => ({ id: q.id, text: q.text, options: q.options })), // answers withheld
    my_last_attempt: lastAttempt(req.quiz.id, req.user.id),
  });
});

router.post('/quizzes/:quizId/attempts', loadQuiz, (req, res, next) => {
  try {
    const b = check(req.body, { answers: { required: true, type: 'array' } });
    const errs = [];
    const given = new Map();
    b.answers.forEach((a, i) => {
      const q = req.quiz.questions.find((x) => x.id === a?.question_id);
      if (!q) errs.push({ field: `answers[${i}].question_id`, message: 'unknown question' });
      else if (!q.options.some((o) => o.id === a.option_id)) errs.push({ field: `answers[${i}].option_id`, message: 'unknown option' });
      else given.set(q.id, a.option_id);
    });
    if (errs.length) throw validation(errs);
    const total = req.quiz.questions.length;
    const score = req.quiz.questions.filter((q) => given.get(q.id) === q.correct).length;
    const passed = (score / total) * 100 >= req.quiz.passMarkPercent;
    store.insert('quizAttempts', {
      quizId: req.quiz.id, userId: req.user.id, score, total, passed,
      answers: [...given].map(([questionId, optionId]) => ({ questionId, optionId })),
    });
    const badges = [];
    if (passed) {
      logEvent(req.user.id, 'quiz_completed', `Completed ${req.quiz.title}`);
      const b = awardBadge(req.user.id, 'quiz_finisher');
      if (b) badges.push(b);
      badges.push(...onQuizPassed(req.user.id, req.quiz.id));
    }
    res.status(201).json({ score, total, passed, badges_awarded: badges });
  } catch (e) { next(e); }
});

// ───── Private reflection on a devotional: only its author ever reads it ─────
function progressOf(req) {
  return store.first('resourceProgress', (p) => p.resourceId === req.resource.id && p.userId === req.user.id);
}
const reflectionDto = (p) => ({ text: (p && p.reflection) || '', updated_at: (p && p.reflectionAt) || null });

router.get('/resources/:resourceId/reflection', loadResource, (req, res) => res.json(reflectionDto(progressOf(req))));

router.put('/resources/:resourceId/reflection', loadResource, (req, res, next) => {
  try {
    // Empty text is allowed: it clears the reflection.
    const text = req.body && req.body.text;
    if (typeof text !== 'string') throw validation([{ field: 'text', message: 'is required' }]);
    check({ text }, { text: { type: 'string', max: 5000 } });
    let rec = progressOf(req);
    if (!rec) rec = store.insert('resourceProgress', { resourceId: req.resource.id, userId: req.user.id, positionSeconds: 0, completed: false });
    rec.reflection = text;
    rec.reflectionAt = store.now();
    res.json(reflectionDto(rec));
  } catch (e) { next(e); }
});

module.exports = router;
