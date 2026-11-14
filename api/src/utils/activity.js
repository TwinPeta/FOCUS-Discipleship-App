const store = require('../db/store');

// Log an activity event (private "My activity", also feeds tracking FR-02).
function logEvent(userId, type, label) {
  return store.insert('events', { userId, type, label });
}

const BADGES = [
  { key: 'first_steps', name: 'First steps' },
  { key: 'quiz_finisher', name: 'Quiz finisher' },
  { key: 'prayer_partner', name: 'Prayer partner' },
  { key: 'pathway_complete', name: 'Pathway complete' },
];

function ensureBadges() {
  BADGES.forEach((b) => {
    if (!store.first('badges', (x) => x.key === b.key)) store.insert('badges', { ...b, iconUrl: null });
  });
}

// Awards a badge once. Returns the badge DTO if newly awarded, else null.
function awardBadge(userId, key) {
  ensureBadges();
  const badge = store.first('badges', (b) => b.key === key);
  if (!badge || store.first('userBadges', (ub) => ub.userId === userId && ub.badgeId === badge.id)) return null;
  const ub = store.insert('userBadges', { userId, badgeId: badge.id });
  return badgeDto(badge, ub);
}

function badgeDto(badge, ub) {
  return {
    id: badge.id, name: badge.name, icon_url: badge.iconUrl,
    earned: !!ub, earned_at: ub ? ub.createdAt : null,
  };
}

function myBadges(userId) {
  ensureBadges();
  return store.col('badges').map((b) =>
    badgeDto(b, store.first('userBadges', (ub) => ub.userId === userId && ub.badgeId === b.id))
  );
}

module.exports = { logEvent, awardBadge, myBadges, ensureBadges };
