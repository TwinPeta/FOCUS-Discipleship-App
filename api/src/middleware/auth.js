const jwt = require('jsonwebtoken');
const config = require('../config');
const store = require('../db/store');
const { unauthorized, forbidden, notFound } = require('../utils/errors');

function authenticate(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) return next(unauthorized());
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    const user = store.get('users', payload.sub);
    if (!user || user.deletedAt) return next(unauthorized());
    req.user = user;
    next();
  } catch {
    next(unauthorized('Invalid or expired token'));
  }
}

// Loads :communityId, checks it exists, and that the caller is an approved member.
function requireMember(req, _res, next) {
  const community = store.get('communities', req.params.communityId);
  if (!community) return next(notFound('Community'));
  const m = store.first(
    'memberships',
    (x) => x.communityId === community.id && x.userId === req.user.id && x.status === 'member'
  );
  if (!m) return next(forbidden('not_a_member', 'You are not a member of this community'));
  req.community = community;
  req.membership = m;
  next();
}

const isLeaderRole = (role) => role === 'super_mentor' || role === 'mentor';

function requireSuperMentor(communityId, userId) {
  const m = store.first(
    'memberships',
    (x) => x.communityId === communityId && x.userId === userId && x.status === 'member'
  );
  if (!m || m.role !== 'super_mentor') throw forbidden('forbidden', 'Only the super-mentor can do this');
}

module.exports = { authenticate, requireMember, requireSuperMentor, isLeaderRole };
