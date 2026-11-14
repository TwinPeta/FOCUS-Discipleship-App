const { validation } = require('./errors');

/**
 * Tiny schema validator. rules: { field: { required, type, min, max, pattern, enum, email } }
 * Throws a 422 with field-level errors.
 */
function check(body, rules) {
  const errors = [];
  const b = body && typeof body === 'object' ? body : {};
  for (const [field, r] of Object.entries(rules)) {
    const v = b[field];
    if (v === undefined || v === null || v === '') {
      if (r.required) errors.push({ field, message: 'is required' });
      continue;
    }
    if (r.type === 'string' && typeof v !== 'string') errors.push({ field, message: 'must be a string' });
    else if (r.type === 'boolean' && typeof v !== 'boolean') errors.push({ field, message: 'must be a boolean' });
    else if (r.type === 'number' && typeof v !== 'number') errors.push({ field, message: 'must be a number' });
    else if (r.type === 'array' && !Array.isArray(v)) errors.push({ field, message: 'must be an array' });
    else {
      if (typeof v === 'string') {
        if (r.min && v.trim().length < r.min) errors.push({ field, message: `must be at least ${r.min} characters` });
        if (r.max && v.length > r.max) errors.push({ field, message: `must be at most ${r.max} characters` });
        if (r.pattern && !r.pattern.test(v)) errors.push({ field, message: r.patternMessage || 'has an invalid format' });
        if (r.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) errors.push({ field, message: 'must be a valid email' });
      }
      if (Array.isArray(v) && r.maxItems && v.length > r.maxItems)
        errors.push({ field, message: `at most ${r.maxItems} items` });
      if (r.enum && !r.enum.includes(v)) errors.push({ field, message: `must be one of: ${r.enum.join(', ')}` });
    }
  }
  if (errors.length) throw validation(errors);
  return b;
}

const isTrue = (v) => v === true;

module.exports = { check, isTrue };
