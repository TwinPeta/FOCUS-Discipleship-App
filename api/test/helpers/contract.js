// Checks real API traffic against the OpenAPI documents, so the docs cannot drift from the code.
// Every test that calls the API through `record()` gets its responses checked:
//   - the operation must be documented (method + path),
//   - a success status must be a documented one,
//   - a documented JSON body must match its schema (error bodies are checked against `Problem`).
const path = require('path');
const SwaggerParser = require('@apidevtools/swagger-parser');
const Ajv2020 = require('ajv/dist/2020');
const addFormats = require('ajv-formats');
const { SPEC_DIR } = require('../../src/docs');

const HTTP = ['get', 'post', 'put', 'patch', 'delete'];

async function load(file, base) {
  const doc = await SwaggerParser.dereference(path.join(SPEC_DIR, file));
  const ajv = new Ajv2020({ strict: false, allErrors: true });
  addFormats(ajv);
  const ops = [];
  for (const [p, item] of Object.entries(doc.paths)) {
    const re = new RegExp(`^${base}${p.replace(/[.*+?^$()|[\]\\]/g, '\\$&').replace(/\{[^}]+\}/g, '[^/]+')}/?$`);
    for (const m of HTTP) if (item[m]) ops.push({ method: m.toUpperCase(), re, template: p, op: item[m], validators: new Map() });
  }
  return { ajv, ops, base, violations: new Set(), checked: 0 };
}

function validatorFor(c, entry, status) {
  if (entry.validators.has(status)) return entry.validators.get(status);
  const res = entry.op.responses[status] || entry.op.responses.default;
  const media = res && res.content && (res.content['application/json'] || res.content['application/problem+json']);
  const v = media && media.schema ? c.ajv.compile(media.schema) : null;
  entry.validators.set(status, v);
  return v;
}

/** Check one exchange. `url` is the path with the base, e.g. /v1/me/communities?x=1. */
function check(c, method, url, status, body) {
  const pathname = url.split('?')[0];
  if (!pathname.startsWith(c.base + '/')) return;
  const entry = c.ops.find((o) => o.method === method && o.re.test(pathname));
  if (!entry) {
    // Another spec's routes (e.g. /v1/admin seen by the mobile spec) are not this document's business.
    if (c.base === '/v1' && pathname.startsWith('/v1/admin/')) return;
    c.violations.add(`${method} ${pathname}: not documented`);
    return;
  }
  c.checked += 1;
  entry.hit = true;
  sample(method, c.base + entry.template, status, body);
  const at = `${method} ${entry.template} -> ${status}`;
  const documented = entry.op.responses[status] || entry.op.responses.default;
  if (!documented) {
    if (status < 400) c.violations.add(`${at}: success status is not documented`);
    return;
  }
  const v = validatorFor(c, entry, String(status));
  if (v && body !== null && body !== undefined && !v(body)) {
    const first = v.errors.slice(0, 3).map((e) => `${e.instancePath || '/'} ${e.message}`).join('; ');
    c.violations.add(`${at}: body does not match the schema (${first})`);
  }
}

/** Operations no test has called yet (their responses are not checked against the schema). */
const unexercised = (c) => c.ops.filter((o) => !o.hit).map((o) => `${o.method} ${o.template}`);

// `CONTRACT_SAMPLES=/path/file.json npm test` also saves every successful JSON response, so schemas can be
// (re)generated from real data instead of written by hand.
const samples = [];
function sample(method, template, status, body) {
  if (process.env.CONTRACT_SAMPLES && status < 300 && body !== null && typeof body === 'object') samples.push({ method, template, status, body });
}
process.on('exit', () => {
  if (process.env.CONTRACT_SAMPLES && samples.length) {
    const file = process.env.CONTRACT_SAMPLES;
    const prev = require('fs').existsSync(file) ? JSON.parse(require('fs').readFileSync(file, 'utf8')) : [];
    require('fs').writeFileSync(file, JSON.stringify([...prev, ...samples]));
  }
});

module.exports = { load, check, unexercised };
