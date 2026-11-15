const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { conflict, forbidden, validation } = require('../utils/errors');
const C = require('./core');
const { SYS, CA, SM } = C;

const CONTENT_TYPES = ['VIDEO', 'DEVOTIONAL', 'QUIZ', 'DOCUMENT'];
const BIBLE = [
  ['char-david', 'David (Character)', 'CHARACTER'], ['char-paul', 'Paul (Character)', 'CHARACTER'], ['char-ruth', 'Ruth (Character)', 'CHARACTER'],
  ['char-daniel', 'Daniel (Character)', 'CHARACTER'], ['text-psalm-23', 'Psalm 23', 'TEXT'], ['text-romans-8', 'Romans 8', 'TEXT'],
  ['text-john-15', 'John 15', 'TEXT'], ['text-philippians-4', 'Philippians 4', 'TEXT'],
].map(([id, label, kind]) => ({ id, label, kind }));

router.get('/bible-links', C.allow(SYS, CA, SM), (req, res) => {
  const q = String(req.query.q || '').toLowerCase();
  res.json(C.list(BIBLE.filter((b) => !q || b.label.toLowerCase().includes(q))));
});

// ───────── content library & validation workflow ─────────
const TRANSITIONS = {
  DRAFT: { SUBMIT_FOR_REVIEW: 'IN_REVIEW', ARCHIVE: 'ARCHIVED' },
  IN_REVIEW: { APPROVE_AND_PUBLISH: 'PUBLISHED', REQUEST_CHANGES: 'DRAFT', ARCHIVE: 'ARCHIVED' },
  PUBLISHED: { ARCHIVE: 'ARCHIVED' },
  ARCHIVED: { RESTORE_TO_DRAFT: 'DRAFT' },
};
const VALIDATE = ['APPROVE_AND_PUBLISH', 'REQUEST_CHANGES'];
const contentDto = (c) => ({
  id: c.id, title: c.title, type: c.type, bibleLink: c.bibleLink, language: c.language || 'English', tags: c.tags || [], description: c.description || '',
  validatorName: c.validatorName || '', pathwayIds: c.pathwayIds || [], body: c.body || '', videoUrl: c.videoUrl || '', thumbnailUrl: c.thumbnailUrl || '',
  documentUrl: c.documentUrl || '', status: c.status, authorName: c.authorName, validatedAt: c.validatedAt || null, updatedAt: c.updatedAt || c.createdAt,
  version: c.version || 1, approvalTrail: c.trail || [],
});
const trail = (c, req, action, notes) => {
  (c.trail = c.trail || []).push({ id: store.uid(), action, actorName: req.user.fullName, notes: notes || null, createdAt: store.now() });
  c.updatedAt = store.now();
};
const rules = (partial) => ({
  title: { required: !partial, type: 'string', min: 2, max: 200 }, type: { required: !partial, type: 'string', enum: CONTENT_TYPES },
  bibleLink: { required: !partial, type: 'string', min: 1 }, language: { type: 'string' }, tags: { type: 'array' }, description: { type: 'string' },
  validatorName: { type: 'string' }, pathwayIds: { type: 'array' }, body: { type: 'string' }, videoUrl: { type: 'string' }, thumbnailUrl: { type: 'string' }, documentUrl: { type: 'string' },
});
const FIELDS = ['title', 'type', 'bibleLink', 'language', 'tags', 'description', 'validatorName', 'pathwayIds', 'body', 'videoUrl', 'thumbnailUrl', 'documentUrl'];
const pick = (b) => Object.fromEntries(FIELDS.filter((k) => b[k] !== undefined).map((k) => [k, b[k]]));

router.get('/content', C.allow(SYS, CA, SM), (req, res) => {
  let items = store.col('content');
  if (req.role === SM) items = items.filter((c) => c.status === 'PUBLISHED');
  if (req.query.status) items = items.filter((c) => c.status === String(req.query.status).toUpperCase());
  if (req.query.type) items = items.filter((c) => c.type === String(req.query.type).toUpperCase());
  const q = String(req.query.q || '').toLowerCase();
  if (q) items = items.filter((c) => `${c.title} ${(c.tags || []).join(' ')}`.toLowerCase().includes(q));
  items = [...items].sort((a, b) => ((a.updatedAt || a.createdAt) < (b.updatedAt || b.createdAt) ? 1 : -1));
  // Pathway builder asks for ?status=published and expects a bare array of picker options
  if (req.query.status) return res.json(items.map((c) => ({ id: c.id, title: c.title, type: c.type.toLowerCase(), published: c.status === 'PUBLISHED' })));
  const counts = {};
  store.col('content').forEach((c) => { counts[c.status] = (counts[c.status] || 0) + 1; });
  res.json(C.list(items.map(contentDto), { counts }));
});
router.get('/content/:id', C.allow(SYS, CA, SM), (req, res, next) => {
  try { const c = C.must('content', req.params.id, 'Content'); if (req.role === SM && c.status !== 'PUBLISHED') throw require('../utils/errors').notFound('Content'); res.json(contentDto(c)); } catch (e) { next(e); }
});
router.post('/content', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = check(req.body, rules(false));
    const c = store.insert('content', { ...pick(b), status: 'DRAFT', authorId: req.user.id, authorName: req.user.fullName, version: 1, updatedAt: store.now() });
    trail(c, req, 'CREATED');
    if (req.body.submitForReview) { c.status = 'IN_REVIEW'; trail(c, req, 'SUBMIT_FOR_REVIEW'); }
    res.status(201).json(contentDto(c));
  } catch (e) { next(e); }
});
router.patch('/content/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    const c = C.must('content', req.params.id, 'Content');
    if (c.status !== 'DRAFT') throw conflict('not_editable', 'Only drafts can be edited; request changes or restore to draft first');
    Object.assign(c, pick(check(req.body, rules(true))));
    c.version = (c.version || 1) + 1; trail(c, req, 'EDITED');
    res.json(contentDto(c));
  } catch (e) { next(e); }
});
router.post('/content/:id/transition', C.allow(SYS, CA), (req, res, next) => {
  try {
    const c = C.must('content', req.params.id, 'Content');
    const b = check(req.body, { action: { required: true, type: 'string', enum: [...new Set(Object.values(TRANSITIONS).flatMap(Object.keys))] }, notes: { type: 'string', max: 1000 } });
    const target = TRANSITIONS[c.status][b.action];
    if (!target) throw conflict('invalid_transition', `Cannot ${b.action} while ${c.status}`);
    if (VALIDATE.includes(b.action)) {
      if (c.authorId === req.user.id && req.role !== SYS) throw forbidden('self_validation', 'Content must be validated by someone other than its author');
      if (b.action === 'REQUEST_CHANGES' && !b.notes) throw validation([{ field: 'notes', message: 'explain what needs to change' }]);
    }
    c.status = target;
    if (b.action === 'APPROVE_AND_PUBLISH') { c.validatedAt = store.now(); c.validatorName = req.user.fullName; C.audit(req, 'content_published', c.title); }
    trail(c, req, b.action, b.notes);
    res.json(contentDto(c));
  } catch (e) { next(e); }
});

// ───────── pathways ─────────
const stepRules = { contentId: { required: true, type: 'string' }, title: { required: true, type: 'string' }, contentType: { required: true, type: 'string', enum: ['video', 'devotional', 'document', 'quiz'] } };
function pathwayDto(p) {
  const badge = p.badgeAwardedId && store.get('adminBadges', p.badgeAwardedId);
  return {
    id: p.id, name: p.name, theme: p.theme, level: p.level, description: p.description || '', steps: p.steps || [], unlockRule: p.unlockRule || 'none',
    badgeAwardedId: p.badgeAwardedId || null, badgeName: badge ? badge.name : null, learnersCount: store.where('pathwayProgress', (x) => x.pathwayId === p.id).length,
    published: !!p.published, updatedAt: p.updatedAt || p.createdAt,
  };
}
function pathwayInput(body, partial) {
  const b = check(body, {
    name: { required: !partial, type: 'string', min: 2 }, theme: { required: !partial, type: 'string', min: 2 },
    level: { type: 'string', enum: ['Beginner', 'Intermediate', 'Advanced'] }, description: { type: 'string' },
    unlockRule: { type: 'string', enum: ['none', 'previous_pathway', 'profile_complete', 'mentor_assigned'] },
  });
  const out = { ...b };
  if (!partial) { out.level = out.level || 'Beginner'; out.unlockRule = out.unlockRule || 'none'; }
  if (body.steps !== undefined || !partial) {
    if (!Array.isArray(body.steps) || !body.steps.length) throw validation([{ field: 'steps', message: 'Pathway must contain at least one step' }]);
    out.steps = body.steps.map((s, i) => {
      check(s, stepRules);
      if (!store.get('content', s.contentId)) throw validation([{ field: `steps[${i}].contentId`, message: 'unknown content item' }]);
      return { id: s.id || store.uid(), contentId: s.contentId, title: s.title, contentType: s.contentType, order: i, required: s.required !== false };
    });
  }
  if (body.badgeAwardedId !== undefined) {
    if (body.badgeAwardedId && !store.get('adminBadges', body.badgeAwardedId)) throw validation([{ field: 'badgeAwardedId', message: 'unknown badge' }]);
    out.badgeAwardedId = body.badgeAwardedId || null;
  }
  if (typeof body.published === 'boolean') out.published = body.published;
  return out;
}
function assertPublishable(p) {
  const bad = (p.steps || []).filter((s) => store.get('content', s.contentId)?.status !== 'PUBLISHED');
  if (bad.length) throw conflict('unpublished_content', `Steps use unpublished content: ${bad.map((s) => s.title).join(', ')}`);
}
router.get('/pathways', C.allow(SYS, CA, SM), (_req, res) => res.json(C.list(store.col('adminPathways').map(pathwayDto))));
router.get('/pathways/:id', C.allow(SYS, CA, SM), (req, res, next) => { try { res.json(pathwayDto(C.must('adminPathways', req.params.id, 'Pathway'))); } catch (e) { next(e); } });
router.post('/pathways', C.allow(SYS, CA), (req, res, next) => {
  try {
    const d = pathwayInput(req.body, false);
    const p = store.insert('adminPathways', { published: false, ...d, updatedAt: store.now() });
    if (p.published) assertPublishable(p);
    res.status(201).json(pathwayDto(p));
  } catch (e) { next(e); }
});
function savePathway(req, res, next) {
  try {
    const p = C.must('adminPathways', req.params.id, 'Pathway');
    const next_ = { ...p, ...pathwayInput(req.body, true) };
    if (next_.published) assertPublishable(next_);
    Object.assign(p, next_, { updatedAt: store.now() });
    res.json(pathwayDto(p));
  } catch (e) { next(e); }
}
router.patch('/pathways/:id', C.allow(SYS, CA), savePathway);
router.put('/pathways/:id', C.allow(SYS, CA), savePathway);
router.delete('/pathways/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    const p = C.must('adminPathways', req.params.id, 'Pathway');
    if (store.first('pathwayProgress', (x) => x.pathwayId === p.id)) throw conflict('pathway_in_use', 'Learners are enrolled; unpublish instead of deleting');
    store.remove('adminPathways', (x) => x.id === p.id);
    res.status(204).end();
  } catch (e) { next(e); }
});

// ───────── badges ─────────
const RULES = {
  join_community: (n) => 'Awarded upon successfully joining a campus community',
  finish_quizzes: (n) => `Score a passing grade on ${n} discipleship quizzes`,
  pray_requests: (n) => `Pray for ${n} community prayer requests on the prayer wall`,
  complete_pathway: (n) => 'Finish all required steps in a discipleship pathway',
  attend_meetings_streak: (n) => `Attend ${n} weekly fellowship meetings in a row`,
};
const badgeDto = (b) => ({
  id: b.id, name: b.name, description: b.description, ruleType: b.ruleType, ruleTargetCount: b.ruleTargetCount, ruleDescription: RULES[b.ruleType](b.ruleTargetCount),
  icon: b.icon, earnedCount: b.earnedCount || 0, visibleOnProfile: b.visibleOnProfile !== false, status: b.status, updatedAt: b.updatedAt || b.createdAt,
});
function badgeInput(body, partial) {
  const b = check(body, {
    name: { required: !partial, type: 'string', min: 2, max: 60 }, description: { required: !partial, type: 'string', max: 300 },
    ruleType: { required: !partial, type: 'string', enum: Object.keys(RULES) }, icon: { type: 'string' }, status: { type: 'string', enum: ['active', 'draft', 'archived'] },
  });
  if (body.ruleTargetCount !== undefined || !partial) {
    if (!Number.isInteger(body.ruleTargetCount) || body.ruleTargetCount < 1 || body.ruleTargetCount > 1000) throw validation([{ field: 'ruleTargetCount', message: 'must be a whole number between 1 and 1000' }]);
    b.ruleTargetCount = body.ruleTargetCount;
  }
  if (typeof body.visibleOnProfile === 'boolean') b.visibleOnProfile = body.visibleOnProfile;
  return b;
}
router.get('/badges', C.allow(SYS, CA, SM), (_req, res) => res.json(C.list(store.col('adminBadges').map(badgeDto))));
router.post('/badges', C.allow(SYS, CA), (req, res, next) => {
  try {
    const d = badgeInput(req.body, false);
    if (store.first('adminBadges', (x) => x.name.toLowerCase() === d.name.toLowerCase())) throw conflict('badge_exists', 'A badge with this name already exists');
    res.status(201).json(badgeDto(store.insert('adminBadges', { icon: 'award', status: 'draft', ...d, updatedAt: store.now() })));
  } catch (e) { next(e); }
});
const saveBadge = (req, res, next) => { try { const b = C.must('adminBadges', req.params.id, 'Badge'); Object.assign(b, badgeInput(req.body, true), { updatedAt: store.now() }); res.json(badgeDto(b)); } catch (e) { next(e); } };
router.put('/badges/:id', C.allow(SYS, CA), saveBadge);
router.patch('/badges/:id', C.allow(SYS, CA), saveBadge);
router.delete('/badges/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = C.must('adminBadges', req.params.id, 'Badge');
    if (store.first('adminPathways', (p) => p.badgeAwardedId === b.id)) throw conflict('badge_in_use', 'A pathway awards this badge');
    store.remove('adminBadges', (x) => x.id === b.id); res.status(204).end();
  } catch (e) { next(e); }
});

// ───────── announcements ─────────
function annDto(a) {
  const c = a.communityId && store.get('communities', a.communityId);
  return { id: a.id, title: a.title, message: a.message, audienceType: a.audienceType, communityId: a.communityId || null, communityName: a.audienceType === 'all' ? 'All Communities' : (c ? c.name : null), imageUrl: a.imageUrl || null, scheduledFor: a.scheduledFor || null, status: a.status, authorName: a.authorName, createdAt: a.createdAt };
}
const { deliver, publishDue } = require('../utils/announcements');
router.get('/announcements', C.allow(SYS, CA, SM), (req, res) => {
  publishDue();
  res.json(C.list(store.col('announcements').filter((a) => req.scope === null || a.audienceType === 'all' || C.inScope(req.scope, a.communityId)).sort((x, y) => (x.createdAt < y.createdAt ? 1 : -1)).map(annDto)));
});
router.post('/announcements', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = check(req.body, { title: { required: true, type: 'string', min: 2, max: 120 }, message: { required: true, type: 'string', min: 2, max: 2000 }, audienceType: { required: true, type: 'string', enum: ['all', 'community'] }, publishTiming: { type: 'string', enum: ['now', 'scheduled'] }, scheduledFor: { type: 'string' }, imageUrl: { type: 'string' }, communityId: { type: 'string' } });
    if (b.audienceType === 'community') { if (!b.communityId) throw validation([{ field: 'communityId', message: 'is required for a community audience' }]); C.must('communities', b.communityId, 'Community'); }
    const scheduled = b.publishTiming === 'scheduled';
    if (scheduled && !(Date.parse(b.scheduledFor) > Date.now())) throw validation([{ field: 'scheduledFor', message: 'must be a future date-time' }]);
    const a = store.insert('announcements', { title: b.title.trim(), message: b.message.trim(), audienceType: b.audienceType, communityId: b.audienceType === 'community' ? b.communityId : null, imageUrl: b.imageUrl || null, scheduledFor: scheduled ? b.scheduledFor : null, status: scheduled ? 'scheduled' : 'published', authorName: req.user.fullName });
    if (!scheduled) deliver(a);
    res.status(201).json(annDto(a));
  } catch (e) { next(e); }
});
router.patch('/announcements/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    const a = C.must('announcements', req.params.id, 'Announcement');
    if (a.status === 'published') throw conflict('already_published', 'Published announcements cannot be edited');
    const b = check(req.body, { title: { type: 'string', min: 2 }, message: { type: 'string', min: 2 }, scheduledFor: { type: 'string' }, imageUrl: { type: 'string' } });
    Object.assign(a, b); res.json(annDto(a));
  } catch (e) { next(e); }
});

// ───────── landing stories ─────────
const storyDto = (s) => ({ id: s.id, studentName: s.studentName, institution: s.institution, videoUrl: s.videoUrl, duration: s.duration, visible: s.visible !== false, order: s.order, consentObtained: !!s.consentObtained, createdAt: s.createdAt });
router.get('/stories', C.allow(SYS, CA), (_req, res) => res.json(C.list([...store.col('adminStories')].sort((a, b) => a.order - b.order).map(storyDto))));
router.post('/stories', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = check(req.body, { studentName: { required: true, type: 'string', min: 2 }, institution: { required: true, type: 'string' }, videoUrl: { required: true, type: 'string' }, duration: { required: true, type: 'string', pattern: /^\d{1,2}:\d{2}$/, patternMessage: 'use m:ss' } });
    if (req.body.consentObtained !== true) throw validation([{ field: 'consentObtained', message: 'Written student consent is required before publishing a story' }]);
    res.status(201).json(storyDto(store.insert('adminStories', { ...b, consentObtained: true, visible: true, order: store.col('adminStories').length })));
  } catch (e) { next(e); }
});
router.patch('/stories/:id', C.allow(SYS, CA), (req, res, next) => { try { const s = C.must('adminStories', req.params.id, 'Story'); if (typeof req.body.visible === 'boolean') s.visible = req.body.visible; res.json(storyDto(s)); } catch (e) { next(e); } });
router.put('/stories/reorder', C.allow(SYS, CA), (req, res, next) => {
  try {
    const list = req.body && req.body.stories;
    if (!Array.isArray(list)) throw validation([{ field: 'stories', message: 'must be an array' }]);
    list.forEach((s, i) => { const row = store.get('adminStories', s.id || s); if (row) row.order = Number.isInteger(s.order) ? s.order : i; });
    res.json(C.list([...store.col('adminStories')].sort((a, b) => a.order - b.order).map(storyDto)));
  } catch (e) { next(e); }
});

// ───────── notification rules & settings ─────────
const RULE_SEED = [
  ['join_request_approved', 'Join request approved', 'Student', 'Welcome to {{community}}', 'Your request was approved. See you at the next meeting!'],
  ['join_request_declined', 'Join request declined', 'Student', 'About your join request', 'Your request to join {{community}} could not be approved.'],
  ['inactivity_reminder', 'Inactivity reminder', 'Student', 'We miss you', 'It has been a while. Come back and continue your pathway.'],
  ['new_announcement', 'New announcement', 'Student', '{{title}}', '{{message}}'],
  ['prayer_received', 'Prayer received', 'Student', 'Someone prayed for you', 'A member of your community prayed for your request.'],
  ['report_received', 'Report received', 'Staff', 'New report to review', 'A report was filed in {{community}}.'],
  ['testimony_published', 'Testimony published', 'Student', 'Your story is live', 'Your testimony was approved and published.'],
];
function ensureRules() {
  if (store.col('notificationRules').length) return;
  RULE_SEED.forEach(([triggerKey, triggerLabel, recipient, title, message]) => store.insert('notificationRules', { triggerKey, triggerLabel, recipient, channels: { inApp: true, email: triggerKey !== 'prayer_received', sms: false }, enabled: true, template: { title, message }, updatedAt: store.now() }));
}
const ruleDto = (r) => ({ id: r.id, triggerKey: r.triggerKey, triggerLabel: r.triggerLabel, recipient: r.recipient, channels: r.channels, enabled: r.enabled, template: r.template, updatedAt: r.updatedAt });
router.get('/notifications/rules', C.allow(SYS, CA), (_req, res) => { ensureRules(); res.json(C.list(store.col('notificationRules').map(ruleDto))); });
router.patch('/notifications/rules/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    ensureRules();
    const r = C.must('notificationRules', req.params.id, 'Notification rule');
    const b = req.body || {};
    let template = r.template;
    if (b.template !== undefined) {
      check(b.template, { title: { required: true, type: 'string', min: 1, max: 120 }, message: { required: true, type: 'string', min: 1, max: 500 } });
      template = { title: b.template.title, message: b.template.message };
    } else if (b.title || b.message) template = { title: b.title || r.template.title, message: b.message || r.template.message };
    const channels = b.channels && typeof b.channels === 'object' ? { ...r.channels, ...Object.fromEntries(Object.entries(b.channels).filter(([, v]) => typeof v === 'boolean')) } : r.channels;
    if (!channels.inApp && !channels.email && !channels.sms) throw validation([{ field: 'channels', message: 'enable at least one channel' }]);
    r.channels = channels; r.template = template;
    if (typeof b.enabled === 'boolean') r.enabled = b.enabled;
    r.updatedAt = store.now(); res.json(ruleDto(r));
  } catch (e) { next(e); }
});

const SETTING_DEFAULTS = {
  charter: { version: '1.0', effectiveDate: new Date().toISOString().slice(0, 10), text: 'Community charter pending approval from FOCUS Uganda.', requireAcceptance: true, repromptOnChange: true },
  consents: { accountCreationText: 'I agree to the terms of use.', communitySpacesText: 'I agree to follow the community charter.', mentorContactText: 'I agree to be contacted by my mentor.' },
  minors: { ageThreshold: 18, requireGuardianConsent: true, limitAdultDirectMessages: true, requireVerifiedMentors: true },
  retention: { inactiveRetentionMonths: 24, deletionDeadlineDays: 30 },
};
const SETTING_RULES = {
  charter: { version: { required: true, type: 'string' }, effectiveDate: { required: true, type: 'string' }, text: { required: true, type: 'string', min: 10 } },
  consents: { accountCreationText: { required: true, type: 'string', min: 5 }, communitySpacesText: { required: true, type: 'string', min: 5 }, mentorContactText: { required: true, type: 'string', min: 5 } },
  minors: {}, retention: {},
};
const intIn = (v, lo, hi, field) => { if (!Number.isInteger(v) || v < lo || v > hi) throw validation([{ field, message: `must be a whole number between ${lo} and ${hi}` }]); return v; };
router.get('/settings/inactivity-threshold', C.allow(SYS, CA, SM), (_req, res) => res.json({ days: C.getSetting('inactivityDays', 14) }));
router.put('/settings/inactivity-threshold', C.allow(SYS), (req, res, next) => {
  try { const days = intIn(req.body && req.body.days, 1, 365, 'days'); C.setSetting('inactivityDays', days); C.audit(req, 'settings_updated', 'Inactivity threshold'); res.json({ days }); } catch (e) { next(e); }
});
router.get('/settings/:section', C.allow(SYS, CA), (req, res, next) => {
  const d = SETTING_DEFAULTS[req.params.section];
  if (!d) return next(require('../utils/errors').notFound('Settings section'));
  res.json({ ...d, ...C.getSetting(req.params.section, {}) });
});
router.patch('/settings/:section', C.allow(SYS), (req, res, next) => {
  try {
    const sec = req.params.section; const d = SETTING_DEFAULTS[sec];
    if (!d) throw require('../utils/errors').notFound('Settings section');
    const b = check(req.body, SETTING_RULES[sec]);
    const out = {};
    for (const k of Object.keys(d)) {
      if (req.body[k] === undefined) continue;
      if (typeof d[k] === 'boolean') { if (typeof req.body[k] !== 'boolean') throw validation([{ field: k, message: 'must be a boolean' }]); out[k] = req.body[k]; }
      else if (typeof d[k] === 'number') out[k] = intIn(req.body[k], k === 'ageThreshold' ? 13 : 1, k === 'ageThreshold' ? 21 : k === 'inactiveRetentionMonths' ? 120 : 90, k);
      else out[k] = b[k] !== undefined ? b[k] : req.body[k];
    }
    C.setSetting(sec, { ...C.getSetting(sec, {}), ...out });
    C.audit(req, 'settings_updated', `${sec} settings`);
    res.json({ ...d, ...C.getSetting(sec, {}) });
  } catch (e) { next(e); }
});

module.exports = { router };
