// File uploads for the back office (cover photos, thumbnails, videos, documents, story videos).
// Same storage as the mobile app: with Cloudflare R2 the browser PUTs straight to a signed URL (nothing large passes
// through this server); without it the file is sent to the API and kept on local disk (dev/tests). Either way the
// finished file has a permanent address, `<BASE_URL>/uploads/<id>`, which is what content records store.
const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();
const config = require('../config');
const store = require('../db/store');
const storage = require('../services/storage');
const { check } = require('../utils/validate');
const { ApiError, notFound, validation } = require('../utils/errors');
const { mediaUrl } = require('../utils/serialize');
const { confirm } = require('../routes/media');
const C = require('./core');

const MB = 1024 * 1024;
const IMAGE = ['image/jpeg', 'image/png', 'image/webp'];
const VIDEO = ['video/mp4', 'video/webm', 'video/quicktime'];
const DOCUMENT = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
// purpose -> allowed content types and size ceiling
const PURPOSES = {
  cover_photo: { types: ['image/jpeg', 'image/png'], max: 5 * MB },
  content_thumbnail: { types: IMAGE, max: 5 * MB },
  content_video: { types: VIDEO, max: 500 * MB },
  content_document: { types: DOCUMENT, max: 25 * MB },
  story_video: { types: VIDEO, max: 200 * MB },
};

const mine = (req) => {
  const m = store.get('media', req.params.id);
  if (!m || m.ownerId !== req.user.id || !PURPOSES[m.purpose]) throw notFound('Upload');
  return m;
};

router.post('/media', async (req, res, next) => {
  try {
    const b = check(req.body, {
      purpose: { required: true, type: 'string', enum: Object.keys(PURPOSES) },
      content_type: { required: true, type: 'string' },
      size_bytes: { required: true, type: 'number' },
    });
    const rule = PURPOSES[b.purpose];
    const errors = [];
    if (!rule.types.includes(b.content_type)) errors.push({ field: 'content_type', message: `must be one of: ${rule.types.join(', ')}` });
    if (!Number.isInteger(b.size_bytes) || b.size_bytes <= 0 || b.size_bytes > rule.max) errors.push({ field: 'size_bytes', message: `must be between 1 byte and ${rule.max / MB} MB` });
    if (errors.length) throw validation(errors);

    const m = store.insert('media', { ownerId: req.user.id, purpose: b.purpose, contentType: b.content_type, sizeBytes: b.size_bytes, status: 'pending' });
    const direct = storage.enabled();
    res.status(201).json({
      media_id: m.id,
      url: mediaUrl(m),
      direct, // true: PUT the file to upload_url as is; false: send it to PUT /media/{id}/upload through the API
      upload_url: direct ? await storage.signedPutUrl(m) : null,
      upload_headers: { 'Content-Type': b.content_type },
      expires_at: new Date(Date.now() + 15 * 60000).toISOString(),
    });
  } catch (e) { next(e); }
});

// Local-disk mode only (with R2 the browser uploads directly to the signed URL).
router.put('/media/:id/upload', express.raw({ type: () => true, limit: '500mb' }), (req, res, next) => {
  try {
    const m = mine(req);
    if (storage.enabled()) throw new ApiError(409, 'direct_upload_required', 'Conflict', 'Upload directly to the upload_url returned when the slot was created');
    if (m.status === 'ready') throw new ApiError(409, 'already_uploaded', 'Conflict', 'File already uploaded');
    if (!Buffer.isBuffer(req.body) || !req.body.length) throw new ApiError(400, 'empty_body', 'Bad request', 'No file bytes received');
    if (req.body.length > m.sizeBytes) throw new ApiError(413, 'payload_too_large', 'Payload too large', 'File larger than declared size');
    fs.mkdirSync(storage.UPLOAD_DIR, { recursive: true });
    fs.writeFileSync(path.join(storage.UPLOAD_DIR, m.id), req.body); // id is a server-generated UUID: no path traversal
    m.status = 'ready';
    res.status(204).end();
  } catch (e) { next(e); }
});

// Confirms the file arrived (asks R2 when direct) and returns its permanent address.
router.post('/media/:id/complete', async (req, res, next) => {
  try {
    const m = mine(req);
    if (!(await confirm(m))) throw new ApiError(409, 'upload_incomplete', 'Conflict', 'The file has not been uploaded (or exceeds the declared size)');
    res.json({ media_id: m.id, status: m.status, url: mediaUrl(m) });
  } catch (e) { next(e); }
});

module.exports = { router, PURPOSES };
