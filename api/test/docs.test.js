process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const http = require('http');
const SwaggerParser = require('@apidevtools/swagger-parser');
const config = require('../src/config');
const { createApp } = require('../src/app');
const { SPECS, SPEC_DIR } = require('../src/docs');

// ── route table of the running app ──────────────────────────────────────────────
const app = createApp();
const routes = [];
(function walk(stack, prefix) {
  for (const l of stack) {
    if (l.route) {
      for (const m of Object.keys(l.route.methods)) routes.push([m.toUpperCase(), (prefix + l.route.path).replace(/\/$/, '')]);
    } else if (l.name === 'router' && l.handle.stack) {
      const m = l.regexp.source.match(/^\^\\\/(.*?)\\\/\?\(\?=\\\/\|\$\)$/);
      walk(l.handle.stack, prefix + (m ? `/${m[1].replace(/\\\//g, '/')}` : ''));
    }
  }
}(app._router.stack, ''));
const norm = (p) => p.replace(/:[A-Za-z]+/g, '{}').replace(/\{[^}]+\}/g, '{}');

// Routes that are deliberately not in the specs.
const NOT_DOCUMENTED = new Set([
  'GET /uploads/{}', // media files, served by id (documented in the description of POST /media)
]);
// Documented operations that are not plain HTTP routes in the Express stack.
const NOT_ROUTES = new Set(['GET /v1/realtime']); // WebSocket upgrade

const HTTP = ['get', 'post', 'put', 'patch', 'delete'];

for (const spec of SPECS) {
  const base = spec.prefix;
  const isAdmin = base === '/v1/admin';
  const file = path.join(SPEC_DIR, spec.file);

  test(`${spec.file} is a valid OpenAPI document`, async () => {
    await SwaggerParser.validate(file);
  });

  test(`${spec.file} documents exactly the routes the API serves`, async () => {
    const doc = await SwaggerParser.parse(file);
    const documented = new Set();
    for (const [p, item] of Object.entries(doc.paths)) {
      for (const m of HTTP) if (item[m]) documented.add(`${m.toUpperCase()} ${base}${norm(p)}`);
    }
    const served = new Set(
      routes.filter(([, p]) => p.startsWith(`${base}/`) && (isAdmin || !p.startsWith('/v1/admin/')))
        .map(([m, p]) => `${m} ${norm(p)}`),
    );
    const undocumented = [...served].filter((x) => !documented.has(x) && !NOT_DOCUMENTED.has(x));
    const phantom = [...documented].filter((x) => !served.has(x) && !NOT_ROUTES.has(x));
    assert.deepEqual(undocumented, [], 'routes without documentation');
    assert.deepEqual(phantom, [], 'documented operations that do not exist');
  });

  test(`${spec.file}: every operation is complete`, async () => {
    const doc = await SwaggerParser.parse(file);
    const declared = new Set((doc.tags || []).map((t) => t.name));
    const ids = new Set();
    const problems = [];
    for (const [p, item] of Object.entries(doc.paths)) {
      for (const m of HTTP) {
        const op = item[m];
        if (!op) continue;
        const at = `${m.toUpperCase()} ${p}`;
        if (!op.operationId) problems.push(`${at}: operationId`);
        else if (ids.has(op.operationId)) problems.push(`${at}: duplicate operationId ${op.operationId}`);
        else ids.add(op.operationId);
        if (!op.summary) problems.push(`${at}: summary`);
        if (!op.tags || !op.tags.length) problems.push(`${at}: tags`);
        for (const t of op.tags || []) if (!declared.has(t)) problems.push(`${at}: undeclared tag ${t}`);
        if (!Object.keys(op.responses || {}).some((c) => /^[12]/.test(c))) problems.push(`${at}: no success response`);
      }
    }
    assert.deepEqual(problems, []);
  });

  test(`${spec.file} has the metadata a published API needs`, async () => {
    const doc = await SwaggerParser.parse(file);
    assert.ok(doc.info.title && doc.info.version && doc.info.description, 'title, version, description');
    assert.ok(doc.info.contact && doc.info.license, 'contact and license');
    assert.ok(doc.components.securitySchemes && Object.keys(doc.components.securitySchemes).length, 'security schemes');
    assert.ok(doc.security && doc.security.length, 'default security');
    for (const t of doc.tags) assert.ok(t.description, `tag ${t.name} needs a description`);
    for (const s of doc.servers) assert.ok(!/\.example\b/.test(s.url), `placeholder server ${s.url}`);
  });
}

// ── what is served ──────────────────────────────────────────────────────────────
function get(server, p, headers = {}) {
  return new Promise((resolve, reject) => {
    http.get({ port: server.address().port, path: p, headers }, (res) => {
      let body = '';
      res.on('data', (c) => { body += c; });
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, body }));
    }).on('error', reject);
  });
}
const listen = () => new Promise((r) => { const s = http.createServer(app).listen(0, () => r(s)); });

test('Swagger UI is served from this server with a strict CSP', async () => {
  const server = await listen();
  try {
    const page = await get(server, '/docs');
    assert.equal(page.status, 200);
    assert.match(page.headers['content-security-policy'], /script-src 'self'(;|$)/);
    assert.doesNotMatch(page.headers['content-security-policy'], /unsafe-inline[^;]*;[^;]*$|script-src[^;]*unsafe/);
    assert.doesNotMatch(page.body, /https?:\/\/(?!localhost)/, 'no third-party hosts in the page');
    assert.doesNotMatch(page.body, /<script>[^<]/, 'no inline scripts');
    assert.equal((await get(server, '/docs/assets/swagger-ui-bundle.js')).status, 200);
    assert.equal((await get(server, '/docs/assets/swagger-ui.css')).status, 200);
    assert.equal((await get(server, '/docs/assets/swagger-ui-standalone-preset.js')).status, 200);
    assert.match(page.body, /swagger-ui-standalone-preset\.js/, 'the API selector needs the standalone preset');
    const init = await get(server, '/docs/swagger-init.js');
    assert.equal(init.status, 200);
    assert.match(init.body, /"validatorUrl":null/);
    assert.match(init.body, /openapi-admin\.yaml/);
    assert.match(init.body, /"layout":"StandaloneLayout"/);
    assert.match(init.body, /SwaggerUIStandalonePreset/);
  } finally { server.close(); }
});

test('the spec points its first server at the host serving it', async () => {
  const server = await listen();
  try {
    const mobile = await get(server, '/openapi.yaml');
    assert.equal(mobile.status, 200);
    assert.match(mobile.headers['content-type'], /yaml/);
    assert.match(mobile.body, new RegExp(`servers:\\n  - url: http://localhost:${server.address().port}/v1\\n`));
    const admin = await get(server, '/openapi-admin.yaml');
    assert.match(admin.body, /\/v1\/admin\n/);
  } finally { server.close(); }
});

test('docs can sit behind HTTP Basic auth without touching the API', async () => {
  const server = await listen();
  const saved = [config.docsUser, config.docsPass];
  config.docsUser = 'docs';
  config.docsPass = 'correct horse';
  try {
    for (const p of ['/docs', '/openapi.yaml', '/openapi-admin.yaml', '/docs/assets/swagger-ui.css']) {
      const denied = await get(server, p);
      assert.equal(denied.status, 401, p);
      assert.match(denied.headers['www-authenticate'], /^Basic/);
    }
    const bad = `Basic ${Buffer.from('docs:wrong').toString('base64')}`;
    assert.equal((await get(server, '/docs', { Authorization: bad })).status, 401);
    const good = `Basic ${Buffer.from('docs:correct horse').toString('base64')}`;
    assert.equal((await get(server, '/docs', { Authorization: good })).status, 200);
    assert.equal((await get(server, '/openapi.yaml', { Authorization: good })).status, 200);
    // The API itself is not behind the docs password.
    assert.equal((await get(server, '/v1/health')).status, 200);
  } finally {
    [config.docsUser, config.docsPass] = saved;
    server.close();
  }
});
