// API documentation: Swagger UI at /docs and the OpenAPI specs.
//
//   /docs                  Swagger UI (assets are bundled with the app: nothing is loaded from a CDN)
//   /openapi.yaml          mobile API   (base path /v1)
//   /openapi-admin.yaml    staff API    (base path /v1/admin)
//
// Production switches (see config.js): DOCS_ENABLED, DOCS_USERNAME + DOCS_PASSWORD (HTTP Basic), DOCS_TRY_IT_OUT.
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const express = require('express');
const config = require('./config');

const SPEC_DIR = path.join(__dirname, '..', '..', 'docs', 'api');
const SPECS = [
  { url: '/openapi.yaml', file: 'openapi.yaml', prefix: '/v1', name: 'Mobile API' },
  { url: '/openapi-admin.yaml', file: 'openapi-admin.yaml', prefix: '/v1/admin', name: 'Back Office (staff) API' },
];

// No inline scripts and no third-party hosts. Swagger UI sets inline style attributes, hence 'unsafe-inline' for styles only.
const CSP = [
  "default-src 'none'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data:",
  "font-src 'self' data:",
  "connect-src 'self'",
  "base-uri 'none'",
  "form-action 'none'",
  "frame-ancestors 'none'",
].join('; ');

const digest = (v) => crypto.createHash('sha256').update(String(v)).digest();

/** HTTP Basic guard, active only when DOCS_USERNAME and DOCS_PASSWORD are set. Read per request so tests can toggle it. */
function guard(req, res, next) {
  if (!config.docsUser || !config.docsPass) return next();
  const [scheme, token] = String(req.headers.authorization || '').split(' ');
  if (scheme === 'Basic' && token) {
    const raw = Buffer.from(token, 'base64').toString('utf8');
    const i = raw.indexOf(':');
    const user = raw.slice(0, i);
    const pass = raw.slice(i + 1);
    // Compare digests so the check takes the same time whatever is guessed.
    const okUser = crypto.timingSafeEqual(digest(user), digest(config.docsUser));
    const okPass = crypto.timingSafeEqual(digest(pass), digest(config.docsPass));
    if (i >= 0 && okUser && okPass) return next();
  }
  res.set('WWW-Authenticate', 'Basic realm="FCU API docs", charset="UTF-8"');
  return res.status(401).type('text/plain').send('Authentication required');
}

const cache = new Map(); // file -> { mtimeMs, text }
function readSpec(file) {
  const full = path.join(SPEC_DIR, file);
  const { mtimeMs } = fs.statSync(full);
  const hit = cache.get(file);
  if (hit && hit.mtimeMs === mtimeMs) return hit.text;
  const text = fs.readFileSync(full, 'utf8');
  cache.set(file, { mtimeMs, text });
  return text;
}

/** The spec with its first server pointing at the environment that serves it, so "Try it out" hits this API. */
function specFor(spec, req) {
  const origin = config.env === 'production' ? config.baseUrl.replace(/\/$/, '') : `${req.protocol}://${req.get('host')}`;
  return readSpec(spec.file).replace(
    /^servers:\n/m,
    `servers:\n  - url: ${origin}${spec.prefix}\n    description: This server (${config.env})\n`,
  );
}

function page() {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>FCU API documentation</title>
<link rel="stylesheet" href="/docs/assets/swagger-ui.css">
<style>body{margin:0}</style>
</head>
<body>
<div id="ui"></div>
<script src="/docs/assets/swagger-ui-bundle.js"></script>
<script src="/docs/assets/swagger-ui-standalone-preset.js"></script>
<script src="/docs/swagger-init.js"></script>
</body>
</html>`;
}

function initScript() {
  const options = {
    urls: SPECS.map((s) => ({ url: s.url, name: s.name })),
    'urls.primaryName': SPECS[0].name,
    dom_id: '#ui',
    layout: 'StandaloneLayout', // needed for the API selector (two specs)
    deepLinking: true,
    displayRequestDuration: true,
    filter: true,
    persistAuthorization: true,
    docExpansion: 'list',
    defaultModelsExpandDepth: 0,
    tagsSorter: 'alpha',
    validatorUrl: null, // never send the spec to an external validator
    ...(config.docsTryItOut ? { tryItOutEnabled: true } : { supportedSubmitMethods: [] }),
  };
  // The presets are objects from the bundle, so they cannot go through JSON.
  return `window.addEventListener('load', function () {
  var options = ${JSON.stringify(options)};
  options.presets = [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset];
  window.ui = SwaggerUIBundle(options);
});
`;
}

function mount(app) {
  if (!config.docsEnabled) return;
  if (config.env === 'production' && !(config.docsUser && config.docsPass)) {
    console.warn('[docs] API documentation is public. Set DOCS_USERNAME and DOCS_PASSWORD, or DOCS_ENABLED=false.');
  }

  const router = express.Router();
  // Only the documentation paths: this router sits in front of the API, which must never see the guard.
  router.use(['/docs', ...SPECS.map((s) => s.url)], guard, (_req, res, next) => {
    res.set({ 'Cache-Control': 'private, no-cache', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer' });
    next();
  });

  for (const spec of SPECS) {
    router.get(spec.url, (req, res, next) => {
      try { res.type('application/yaml').send(specFor(spec, req)); } catch (e) { next(e); }
    });
  }
  router.get('/docs', (_req, res) => res.set('Content-Security-Policy', CSP).type('html').send(page()));
  router.get('/docs/', (_req, res) => res.redirect(301, '/docs'));
  router.get('/docs/swagger-init.js', (_req, res) => res.set('Content-Security-Policy', CSP).type('application/javascript').send(initScript()));
  router.use('/docs/assets', express.static(require('swagger-ui-dist').getAbsoluteFSPath(), {
    index: false, dotfiles: 'deny', maxAge: '1d', immutable: false,
    setHeaders: (res) => res.set('Cache-Control', 'public, max-age=86400'),
  }));
  app.use(router);
}

module.exports = { mount, SPECS, SPEC_DIR };
