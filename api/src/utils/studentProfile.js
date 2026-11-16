const store = require('../db/store');

/**
 * Student profile details collected at sign-up beyond the basics: home
 * church, year of study (university students), and student-added
 * institutes. Stored on the user document (kept in `extra`, no column).
 */

const INSTITUTION_TYPES = ['university', 'institute', 'high_school'];
/** Types offered to new students (high school is kept only for old accounts). */
const SIGNUP_TYPES = ['university', 'institute'];
const MAX_YEAR = 7;
const CHURCH_FIELDS = ['name', 'location', 'pastor'];

/** Validates `home_church` ({ name, location, pastor }, all required). */
function homeChurchInput(v, errs, field = 'home_church') {
  if (!v || typeof v !== 'object' || Array.isArray(v)) {
    errs.push({ field, message: 'is required' });
    return null;
  }
  const out = {};
  for (const k of CHURCH_FIELDS) {
    const s = typeof v[k] === 'string' ? v[k].trim() : '';
    if (s.length < 2) errs.push({ field: `${field}.${k}`, message: 'is required' });
    else if (s.length > 120) errs.push({ field: `${field}.${k}`, message: 'must be at most 120 characters' });
    else out[k] = s;
  }
  return out;
}

/** Year of study: a whole number 1..7, required for university students. */
function yearOfStudyInput(v, type, errs) {
  if (v === undefined || v === null) {
    if (type === 'university') errs.push({ field: 'year_of_study', message: 'is required for university students' });
    return null;
  }
  if (!Number.isInteger(v) || v < 1 || v > MAX_YEAR) {
    errs.push({ field: 'year_of_study', message: `must be a whole number from 1 to ${MAX_YEAR}` });
    return null;
  }
  return v;
}

/**
 * An institute the student typed because it was not listed: reuse one with
 * the same name in the country, otherwise add it hidden from the sign-up
 * list (staff review it in the back office) with its General community.
 */
function findOrAddInstitute(name, country) {
  const clean = name.trim().replace(/\s+/g, ' ');
  const existing = store.first('institutions', (i) =>
    i.country === country && i.name.toLowerCase() === clean.toLowerCase());
  if (existing) return existing;
  const inst = store.insert('institutions', {
    name: clean, type: 'institute', country, shownInSignup: false, addedByStudent: true,
  });
  store.insert('communities', {
    type: 'general', name: 'General community', initials: 'GE', institutionId: inst.id,
    description: `Everyone at ${inst.name}, open to all.`,
  });
  return inst;
}

const homeChurchOut = (u) => (u.homeChurch ? {
  name: u.homeChurch.name, location: u.homeChurch.location, pastor: u.homeChurch.pastor,
} : null);

module.exports = {
  INSTITUTION_TYPES, SIGNUP_TYPES, MAX_YEAR,
  homeChurchInput, yearOfStudyInput, findOrAddInstitute, homeChurchOut,
};
