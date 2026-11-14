const fs = require('fs');
const path = require('path');
const config = require('../config');

/**
 * Object storage for user media.
 * - R2 configured  -> Cloudflare R2 via the S3 API; clients upload straight to R2 with a signed PUT URL.
 * - otherwise      -> local ./uploads folder, uploaded through the API (dev/tests).
 */
const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');
const keyOf = (m) => `media/${m.purpose}/${m.id}`;
const enabled = () => config.r2Enabled;

let s3 = null;
function client() {
  if (!s3) {
    const { S3Client } = require('@aws-sdk/client-s3');
    s3 = new S3Client({
      region: 'auto',
      requestChecksumCalculation: 'WHEN_REQUIRED', // otherwise presigned PUTs embed a CRC32 of an empty body and R2 rejects real uploads
      responseChecksumValidation: 'WHEN_REQUIRED',
      endpoint: `https://${config.r2.accountId}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId: config.r2.accessKeyId, secretAccessKey: config.r2.secretAccessKey },
    });
  }
  return s3;
}
/** Test hook */
function useClient(c) { s3 = c; }

async function signedPutUrl(m, expiresIn = 900) {
  const { PutObjectCommand } = require('@aws-sdk/client-s3');
  const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
  // ContentType + ContentLength are part of the signature: the client can't upload a different type/size.
  return getSignedUrl(client(), new PutObjectCommand({ Bucket: config.r2.bucket, Key: keyOf(m), ContentType: m.contentType, ContentLength: m.sizeBytes }), { expiresIn });
}

/** Returns the stored size in bytes, or null if the object doesn't exist yet. */
async function head(m) {
  const { HeadObjectCommand } = require('@aws-sdk/client-s3');
  try {
    const r = await client().send(new HeadObjectCommand({ Bucket: config.r2.bucket, Key: keyOf(m) }));
    return r.ContentLength;
  } catch (e) {
    if (e.name === 'NotFound' || e.$metadata?.httpStatusCode === 404) return null;
    throw e;
  }
}

async function readUrl(m) {
  if (config.r2.publicUrl) return `${config.r2.publicUrl}/${keyOf(m)}`;
  const { GetObjectCommand } = require('@aws-sdk/client-s3');
  const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
  return getSignedUrl(client(), new GetObjectCommand({ Bucket: config.r2.bucket, Key: keyOf(m) }), { expiresIn: 3600 });
}

async function remove(m) {
  if (enabled()) {
    const { DeleteObjectCommand } = require('@aws-sdk/client-s3');
    await client().send(new DeleteObjectCommand({ Bucket: config.r2.bucket, Key: keyOf(m) }));
  } else {
    fs.rmSync(path.join(UPLOAD_DIR, m.id), { force: true });
  }
}

module.exports = { enabled, keyOf, signedPutUrl, head, readUrl, remove, useClient, UPLOAD_DIR };
