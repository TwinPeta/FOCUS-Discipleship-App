const { ApiError } = require('../utils/errors');
const config = require('../config');

function notFoundHandler(req, res) {
  res.status(404).type('application/problem+json').json({
    type: 'about:blank', title: 'Not found', status: 404, code: 'route_not_found',
    detail: `${req.method} ${req.path} does not exist`,
  });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, _next) {
  if (err.type === 'entity.parse.failed') {
    err = new ApiError(400, 'invalid_json', 'Bad request', 'Request body is not valid JSON');
  }
  if (err.type === 'entity.too.large') {
    err = new ApiError(413, 'payload_too_large', 'Payload too large', 'Request body is too large');
  }
  const status = err instanceof ApiError ? err.status : 500;
  if (status === 500) console.error(err);
  const body = {
    type: `${config.baseUrl}/errors/${err.code || 'internal_error'}`,
    title: err instanceof ApiError ? err.title : 'Internal server error',
    status,
    code: err.code || 'internal_error',
  };
  if (err.detail) body.detail = err.detail;
  if (err.errors) body.errors = err.errors;
  if (err.retryAfter) res.set('Retry-After', String(err.retryAfter));
  res.status(status).type('application/problem+json').json(body);
}

module.exports = { notFoundHandler, errorHandler };
