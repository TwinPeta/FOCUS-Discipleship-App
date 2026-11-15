const config = require('../config');

/**
 * Transactional email via Resend.
 * - RESEND_API_KEY set  -> real delivery
 * - not set, non-production -> logged to the console (and kept in `outbox` for tests)
 * - not set, production -> logged as an error; callers are never blocked or failed by email problems
 */
const outbox = [];
let client = null;
/** Test hook: swap the Resend client. */
const useClient = (c) => { client = c; };

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function layout(title, bodyHtml) {
  return `<div style="font-family:system-ui,sans-serif;max-width:520px;margin:auto;padding:24px;color:#111">
<h2 style="margin:0 0 16px">${esc(title)}</h2>${bodyHtml}
<p style="color:#888;font-size:12px;margin-top:32px">FCU Student Community</p></div>`;
}
const button = (href, label) => `<p><a href="${esc(href)}" style="display:inline-block;background:#111;color:#fff;padding:10px 18px;border-radius:6px;text-decoration:none">${esc(label)}</a></p>`;

const templates = {
  otp: ({ code, purpose }) => ({
    subject: `Your FCU verification code: ${code}`,
    text: `Your ${purpose.replace('_', ' ')} code is ${code}. It expires in 10 minutes. If you didn't request it, ignore this email.`,
    html: layout('Your verification code', `<p style="font-size:32px;letter-spacing:6px;font-weight:700">${esc(code)}</p><p>It expires in 10 minutes. If you didn't request it, you can ignore this email.</p>`),
  }),
  staffReset: ({ name, link }) => ({
    subject: 'Reset your FCU back-office password',
    text: `Hi ${name}, reset your password here (valid for 1 hour): ${link}`,
    html: layout('Reset your password', `<p>Hi ${esc(name)}, use the button below to choose a new password. The link is valid for 1 hour.</p>${button(link, 'Reset password')}<p style="color:#888;font-size:12px">If you didn't ask for this, ignore this email.</p>`),
  }),
  invite: ({ name, link }) => ({
    subject: "You've been invited to FCU Student Community",
    text: `Hi ${name}, you've been invited. Set your password here (valid for 7 days): ${link}`,
    html: layout('Welcome to FCU Student Community', `<p>Hi ${esc(name)}, an administrator has created an account for you. Set your password to get started.</p>${button(link, 'Set your password')}`),
  }),
  // A notification the app also shows in-app (reply, approval, announcement...), for people who chose email.
  notification: ({ name, title, body }) => ({
    subject: title,
    text: `Hi ${name},\n\n${title}${body ? `\n\n${body}` : ''}\n\nOpen the FCU Student Community app to see more. You can change which emails you get under Settings > Notifications.`,
    html: layout(title, `<p>Hi ${esc(name)},</p>${body ? `<p>${esc(body)}</p>` : ''}<p>Open the FCU Student Community app to see more.</p><p style="color:#888;font-size:12px">You can change which emails you get under Settings &gt; Notifications.</p>`),
  }),
  guardianConsent: ({ guardianName, minorName, from, replyable }) => ({
    subject: `${minorName} joined FCU Student Community: we need your consent`,
    text: `Hello ${guardianName || ''},\n\n${minorName} signed up for FCU Student Community and is under 18, so we need a parent or guardian to confirm they may take part. Until then their account stays limited.\n\n${replyable ? 'Please reply to this email to give or decline your consent.' : `A member of the FOCUS team (${from}) will be in touch.`}`,
    html: layout('We need your consent', `<p>Hello ${esc(guardianName || '')},</p><p><strong>${esc(minorName)}</strong> signed up for FCU Student Community and is under 18, so we need a parent or guardian to confirm they may take part. Until then their account stays limited.</p><p>${replyable ? 'Please reply to this email to give or decline your consent.' : `A member of the FOCUS team (${esc(from)}) will be in touch.`}</p>`),
  }),
  reminder: ({ name, from }) => ({
    subject: 'Checking in on you',
    text: `Hi ${name}, ${from} is checking in. We'd love to see you back in the community.`,
    html: layout('Checking in', `<p>Hi ${esc(name)}, ${esc(from)} is checking in. We'd love to see you back in the community.</p>`),
  }),
};

// Resend answers 429 when sending too fast and 5xx when it has trouble: those are worth trying again. A 4xx
// (bad address, unverified sender) will not get better, so it fails at once.
const retryable = (error) => {
  const code = error && (error.statusCode || error.status);
  return !code || code === 429 || code >= 500 || /rate|timeout|fetch failed|network/i.test(String(error.message || error.name || ''));
};
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const retryBaseMs = () => (config.env === 'test' ? 1 : 1000);

/** Hands one message to Resend, trying again (1 s, 2 s, 4 s) on rate limits and server errors. */
async function deliver(msg) {
  if (!client) { const { Resend } = require('resend'); client = new Resend(config.resendApiKey); }
  let lastError;
  for (let attempt = 0; attempt < 4; attempt++) {
    if (attempt) await wait(retryBaseMs() * 2 ** (attempt - 1));
    try {
      const { data, error } = await client.emails.send(msg);
      if (!error) return data;
      lastError = Object.assign(new Error(`Resend: ${error.message || JSON.stringify(error)}`), { statusCode: error.statusCode });
    } catch (e) { lastError = e; }
    if (!retryable(lastError)) break;
  }
  throw lastError;
}

async function send(to, template, data) {
  const t = templates[template](data);
  const msg = { from: config.mailFrom, to, ...t, ...(config.mailReplyTo ? { replyTo: config.mailReplyTo } : {}) };
  if (config.env === 'test') { outbox.push({ template, ...msg }); return { id: 'test' }; }
  if (!config.resendApiKey) {
    if (config.env === 'production') { console.error(`[mail] RESEND_API_KEY not set; dropped "${t.subject}"`); return null; }
    console.log(`[mail:dev] to=${to} subject="${t.subject}"\n${t.text}`);
    outbox.push({ template, ...msg });
    return { id: 'dev' };
  }
  return deliver(msg);
}

// One at a time, at a steady pace: an announcement to a whole campus must not trip Resend's rate limit and lose emails.
let tail = Promise.resolve();
function notify(to, template, data) {
  if (config.env === 'test') { send(to, template, data).catch(() => {}); return; } // synchronous outbox; no pacing in tests
  tail = tail
    .then(() => send(to, template, data))
    .catch((e) => console.error(`[mail] ${template} to ${to} failed:`, e.message))
    .then(() => wait(config.resendApiKey ? config.mailGapMs : 0));
}

/** Settings that would make real emails useless or wrong (links to localhost, an unverified sender). Logged at startup. */
function configProblems(env = config) {
  const problems = [];
  if (env.env !== 'production') return problems;
  if (!env.resendApiKey) problems.push('RESEND_API_KEY is not set: no email will be delivered.');
  if (/@localhost>?$/.test(env.mailFrom)) problems.push('MAIL_FROM is not set (or is @localhost): Resend will reject every email. Use an address on a domain verified in Resend.');
  if (/localhost|127\.0\.0\.1/.test(env.backofficeUrl)) problems.push(`BACKOFFICE_URL is ${env.backofficeUrl}: password-reset and invite emails would link to it. Set it to the back office address, e.g. https://backoffice.focusuganda.org.`);
  return problems;
}

module.exports = { send, notify, deliver, useClient, configProblems, outbox, templates };
