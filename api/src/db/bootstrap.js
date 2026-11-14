const bcrypt = require('bcryptjs');
const store = require('./store');

/**
 * Creates the first system administrator from ADMIN_EMAIL / ADMIN_PASSWORD / ADMIN_NAME when no system admin exists.
 * Returns the created user, or null if nothing was done. Never overwrites or changes an existing account.
 */
function ensureAdmin(env = process.env) {
  const email = (env.ADMIN_EMAIL || '').trim().toLowerCase();
  const password = env.ADMIN_PASSWORD || '';
  if (!email || !password) return null;
  if (store.first('users', (u) => !u.deletedAt && u.platformRole === 'system_admin')) return null;
  if (store.first('users', (u) => u.email === email)) {
    console.warn(`[bootstrap] ADMIN_EMAIL ${email} belongs to a non-admin account; not changing it.`);
    return null;
  }
  if (password.length < 10) throw new Error('ADMIN_PASSWORD must be at least 10 characters');
  return store.insert('users', {
    fullName: env.ADMIN_NAME || 'System Administrator', username: email.split('@')[0].replace(/[^a-z0-9_]/g, '_'), email,
    passwordHash: bcrypt.hashSync(password, 12), emailVerified: true, phoneVerified: false, minorStatus: 'adult',
    platformRole: 'system_admin', verifiedMentor: true, invited: false, suspended: false,
  });
}
module.exports = { ensureAdmin };
