const config = require('../config');

/**
 * Transactional email via Resend.
 * - RESEND_API_KEY set  -> real delivery
 * - not set, non-production -> logged to the console (and kept in `outbox` for tests)
 * - not set, production -> logged as an error; callers are never blocked or failed by email problems
 */
const outbox = [];
let client = null;

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
  reminder: ({ name, from }) => ({
    subject: 'Checking in on you',
    text: `Hi ${name}, ${from} is checking in. We'd love to see you back in the community.`,
    html: layout('Checking in', `<p>Hi ${esc(name)}, ${esc(from)} is checking in. We'd love to see you back in the community.</p>`),
  }),
};

async function send(to, template, data) {
  const t = templates[template](data);
  const msg = { from: config.mailFrom, to, ...t };
  if (config.env === 'test') { outbox.push({ template, ...msg }); return { id: 'test' }; }
  if (!config.resendApiKey) {
    if (config.env === 'production') { console.error(`[mail] RESEND_API_KEY not set; dropped "${t.subject}"`); return null; }
    console.log(`[mail:dev] to=${to} subject="${t.subject}"\n${t.text}`);
    outbox.push({ template, ...msg });
    return { id: 'dev' };
  }
  if (!client) { const { Resend } = require('resend'); client = new Resend(config.resendApiKey); }
  const { data: out, error } = await client.emails.send(msg);
  if (error) throw new Error(`Resend: ${error.message || JSON.stringify(error)}`);
  return out;
}

/** Fire-and-forget: email failure must never fail the request that triggered it. */
function notify(to, template, data) {
  send(to, template, data).catch((e) => console.error(`[mail] ${template} to ${to} failed:`, e.message));
}

module.exports = { send, notify, outbox, templates };
