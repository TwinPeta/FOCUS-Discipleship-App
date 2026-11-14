// RFC 7807 problem+json errors
class ApiError extends Error {
  constructor(status, code, title, detail, errors) {
    super(title);
    this.status = status;
    this.code = code;
    this.title = title;
    this.detail = detail;
    this.errors = errors;
  }
}

const badRequest = (code, title, detail) => new ApiError(400, code, title, detail);
const unauthorized = (detail = 'Missing or invalid credentials') =>
  new ApiError(401, 'unauthorized', 'Unauthorized', detail);
const forbidden = (code = 'forbidden', detail = 'You are not allowed to do this') =>
  new ApiError(403, code, 'Forbidden', detail);
const notFound = (what = 'Resource') => new ApiError(404, 'not_found', 'Not found', `${what} not found`);
const conflict = (code, detail) => new ApiError(409, code, 'Conflict', detail);
const validation = (errors) =>
  new ApiError(422, 'validation_failed', 'Validation failed', 'One or more fields are invalid', errors);

module.exports = { ApiError, badRequest, unauthorized, forbidden, notFound, conflict, validation };
