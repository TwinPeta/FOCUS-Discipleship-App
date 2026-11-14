const path = require('path');
const fs = require('fs');
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const config = require('./config');
const store = require('./db/store');
const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/error');
const { UPLOAD_DIR, confirm } = require('./routes/media');
const storage = require('./services/storage');
const pg = require('./db/prisma');

function corsOptions() {
  const allowed = new Set([...config.corsOrigins, config.baseUrl.replace(/\/$/, '')]);
  return {
    origin(origin, cb) {
      // No Origin header (curl, mobile apps, same-origin) or open dev mode -> allow
      if (!origin || config.corsOpen || allowed.has(origin)) return cb(null, true);
      return cb(null, false);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    exposedHeaders: ['ETag', 'Retry-After', 'X-RateLimit-Remaining'],
    maxAge: 600,
  };
}

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors(corsOptions()));
  if (config.env !== 'test') app.use(morgan('tiny'));
  app.use(express.json({ limit: '1mb' }));
  app.use(pg.persistAfterWrites);

  // Uploaded media. Looked up by id in the store (never by raw path); report evidence is private.
  app.get('/uploads/:id', async (req, res, next) => {
    try {
      const m = store.get('media', req.params.id);
      if (!m || m.purpose === 'report_evidence') return next();
      if (storage.enabled()) {
        if (!(await confirm(m))) return next();
        return res.set('Cache-Control', 'private, max-age=300').redirect(302, await storage.readUrl(m));
      }
      if (m.status !== 'ready') return next();
      res.type(m.contentType).sendFile(path.join(UPLOAD_DIR, m.id));
    } catch (e) { next(e); }
  });

  // API docs: raw OpenAPI spec + Swagger UI (assets from CDN, so relax CSP for this page only)
  const DOCS_DIR = path.join(__dirname, '..', '..', 'docs', 'api');
  const serveSpec = (file, prefix) => (req, res, next) => {
    const f = path.join(DOCS_DIR, file);
    if (!fs.existsSync(f)) return next();
    // Point the first server at the environment actually serving the docs, so "Try it out" works
    const origin = config.env === 'production' ? config.baseUrl.replace(/\/$/, '') : `${req.protocol}://${req.get('host')}`;
    const yaml = fs.readFileSync(f, 'utf8').replace(
      /^servers:\n/m,
      `servers:\n  - url: ${origin}${prefix}\n    description: This server (${config.env})\n`,
    );
    res.type('application/yaml').send(yaml);
  };
  app.get('/openapi.yaml', serveSpec('openapi.yaml', '/v1'));
  app.get('/openapi-admin.yaml', serveSpec('openapi-admin.yaml', '/v1/admin'));
  app.get('/docs', (_req, res) => {
    res.set('Content-Security-Policy', [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
      "img-src 'self' data: https:",
      "connect-src 'self'",
    ].join('; '));
    res.type('html').send(`<!doctype html><html><head><meta charset="utf-8"><title>FCU API Docs</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui.css"></head>
<body><div id="ui"></div>
<script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.17.14/swagger-ui-bundle.js"></script>
<script>SwaggerUIBundle({urls:[{url:'/openapi.yaml',name:'Mobile API'},{url:'/openapi-admin.yaml',name:'Back Office (staff) API'}],'urls.primaryName':'Mobile API',dom_id:'#ui',persistAuthorization:true,tryItOutEnabled:true})</script>
</body></html>`);
  });

  app.use('/v1', routes);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
