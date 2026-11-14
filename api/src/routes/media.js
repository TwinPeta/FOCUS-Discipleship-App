const router = require('express').Router();
const express = require('express');
const fs = require('fs');
const path = require('path');
const config = require('../config');
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, forbidden, ApiError } = require('../utils/errors');

const storage = require('../services/storage');

const UPLOAD_DIR = storage.UPLOAD_DIR;
const MB = 1024 * 1024;
const PURPOSES = ['profile_photo', 'post_photo', 'testimony_photo', 'testimony_video', 'report_evidence'];
const IMAGE = /^image\/(jpeg|png|webp|heic)$/;
const VIDEO = /^video\/(mp4|quicktime|webm)$/;

/**
 * With Cloudflare R2 the client uploads straight to a signed PUT URL, so the API learns the file
 * arrived by asking R2 (HEAD). Returns true when the media is uploaded and within its declared size.
 */
async function confirm(m) {
  if (m.status === 'ready') return true;
  if (!storage.enabled() || m.status !== 'pending') return false;
  const size = await storage.head(m);
  if (size === null) return false;
  if (size > m.sizeBytes) { m.status = 'rejected'; await storage.remove(m).catch(() => {}); return false; }
  m.status = 'ready';
  return true;
}

/** Before a request that references media ids is handled, make sure R2 uploads have actually landed. */
async function confirmReferenced(req, _res, next) {
  try {
    if (storage.enabled() && req.body && typeof req.body === 'object') {
      const ids = [...(Array.isArray(req.body.media_ids) ? req.body.media_ids : []), req.body.photo_media_id, req.body.evidence_media_id].filter((x) => typeof x === 'string');
      for (const id of ids) { const m = store.get('media', id); if (m && m.ownerId === req.user.id) await confirm(m); }
    }
    next();
  } catch (e) { next(e); }
}

router.post('/', async (req, res, next) => {
  try {
    const b = check(req.body, {
      purpose: { required: true, type: 'string', enum: PURPOSES },
      content_type: { required: true, type: 'string' },
      size_bytes: { required: true, type: 'number' },
    });
    const video = b.purpose === 'testimony_video';
    const okType = video ? VIDEO.test(b.content_type) : IMAGE.test(b.content_type);
    const max = video ? 200 * MB : 10 * MB;
    const errs = [];
    if (!okType) errs.push({ field: 'content_type', message: video ? 'must be mp4, quicktime or webm' : 'must be jpeg, png, webp or heic' });
    if (b.size_bytes <= 0 || b.size_bytes > max) errs.push({ field: 'size_bytes', message: `must be between 1 byte and ${max / MB} MB` });
    if (errs.length) throw require('../utils/errors').validation(errs);

    const m = store.insert('media', { ownerId: req.user.id, purpose: b.purpose, contentType: b.content_type, sizeBytes: b.size_bytes, status: 'pending' });
    const direct = storage.enabled(); // R2: signed URL straight to the bucket, no Authorization header
    res.status(201).json({
      media_id: m.id,
      upload_url: direct ? await storage.signedPutUrl(m) : `${config.baseUrl}/v1/media/${m.id}/upload`,
      upload_headers: direct ? { 'Content-Type': b.content_type } : { 'Content-Type': b.content_type, Authorization: 'Bearer <access_token>' },
      expires_at: new Date(Date.now() + 15 * 60000).toISOString(),
    });
  } catch (e) { next(e); }
});

// Optional: tell the API the direct upload finished (it is also verified lazily when the media is used).
router.post('/:mediaId/complete', async (req, res, next) => {
  try {
    const m = store.get('media', req.params.mediaId);
    if (!m) throw notFound('Media');
    if (m.ownerId !== req.user.id) throw forbidden();
    if (!(await confirm(m))) throw new ApiError(409, 'upload_incomplete', 'Conflict', 'The file has not been uploaded (or exceeds the declared size)');
    res.json({ media_id: m.id, status: m.status });
  } catch (e) { next(e); }
});

router.put('/:mediaId/upload', express.raw({ type: () => true, limit: '200mb' }), (req, res, next) => {
  try {
    const m = store.get('media', req.params.mediaId);
    if (!m) throw notFound('Media');
    if (m.ownerId !== req.user.id) throw forbidden();
    if (storage.enabled()) throw new ApiError(409, 'direct_upload_required', 'Conflict', 'Upload directly to the upload_url returned when the slot was created');
    if (m.status === 'ready') throw new ApiError(409, 'already_uploaded', 'Conflict', 'File already uploaded');
    if (!Buffer.isBuffer(req.body) || !req.body.length) throw new ApiError(400, 'empty_body', 'Bad request', 'No file bytes received');
    if (req.body.length > m.sizeBytes) throw new ApiError(413, 'payload_too_large', 'Payload too large', 'File larger than declared size');
    fs.writeFileSync(path.join(UPLOAD_DIR, m.id), req.body); // id is a server-generated UUID: no path traversal
    m.status = 'ready';
    res.status(204).end();
  } catch (e) { next(e); }
});

module.exports = router;
module.exports.UPLOAD_DIR = UPLOAD_DIR;
module.exports.confirm = confirm;
module.exports.confirmReferenced = confirmReferenced;
