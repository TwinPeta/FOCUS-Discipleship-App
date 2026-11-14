const store = require('../db/store');
const { logEvent, awardBadge } = require('./activity');

const progressOf = (userId, pathwayId) =>
  store.first('pathwayProgress', (p) => p.userId === userId && p.pathwayId === pathwayId);

function summary(pathway, userId) {
  const all = store.col('pathways');
  const idx = all.findIndex((p) => p.id === pathway.id);
  const prog = progressOf(userId, pathway.id);
  const done = prog ? prog.completedStepIds.length : 0;
  const total = pathway.steps.length;
  const prev = idx > 0 ? all[idx - 1] : null;
  const prevDone = !prev || (progressOf(userId, prev.id)?.completedStepIds.length === prev.steps.length);
  let status;
  if (prog && done >= total) status = 'completed';
  else if (prog) status = 'in_progress';
  else if (idx >= 2 && !prevDone) status = 'locked';
  else status = 'available';
  const next = prog ? pathway.steps.find((s) => !prog.completedStepIds.includes(s.id)) : null;
  return {
    id: pathway.id,
    title: pathway.title,
    steps_total: total,
    steps_completed: done,
    current_step: next ? next.order : null,
    status,
    unlock_hint: status === 'locked' ? 'Unlocks after the previous pathway' : null,
  };
}

function detail(pathway, userId) {
  const prog = progressOf(userId, pathway.id);
  const done = prog ? prog.completedStepIds : [];
  const nextId = prog ? pathway.steps.find((s) => !done.includes(s.id))?.id : null;
  return {
    ...summary(pathway, userId),
    steps: pathway.steps.map((s) => ({
      id: s.id, order: s.order, title: s.title, type: s.type, resource_id: s.resourceId,
      duration_label: s.durationLabel,
      status: done.includes(s.id) ? 'done' : s.id === nextId ? 'current' : 'upcoming',
    })),
  };
}

// Marks a step done (idempotent). Returns { pathway, next_step_id, badges_awarded }.
function completeStep(userId, pathway, stepId) {
  const prog = progressOf(userId, pathway.id) ||
    store.insert('pathwayProgress', { userId, pathwayId: pathway.id, completedStepIds: [] });
  const badges = [];
  if (!prog.completedStepIds.includes(stepId)) {
    prog.completedStepIds.push(stepId);
    const step = pathway.steps.find((s) => s.id === stepId);
    logEvent(userId, 'pathway_step_completed', `Completed ${step.title}`);
    const b1 = awardBadge(userId, 'first_steps');
    if (b1) badges.push(b1);
    if (prog.completedStepIds.length >= pathway.steps.length) {
      const b2 = awardBadge(userId, 'pathway_complete');
      if (b2) badges.push(b2);
    }
  }
  const next = pathway.steps.find((s) => !prog.completedStepIds.includes(s.id));
  return { pathway: summary(pathway, userId), next_step_id: next ? next.id : null, badges_awarded: badges };
}

// When a quiz is passed, complete any enrolled pathway steps that point at it.
function onQuizPassed(userId, quizId) {
  const badges = [];
  store.col('pathways').forEach((p) => {
    if (!progressOf(userId, p.id)) return;
    p.steps.filter((s) => s.type === 'quiz' && s.resourceId === quizId).forEach((s) => {
      badges.push(...completeStep(userId, p, s.id).badges_awarded);
    });
  });
  return badges;
}

module.exports = { summary, detail, completeStep, onQuizPassed, progressOf };
