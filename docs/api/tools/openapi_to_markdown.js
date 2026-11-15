#!/usr/bin/env node
// Turns an OpenAPI 3.x YAML spec into a Markdown endpoint reference.
//
//   node docs/api/tools/openapi_to_markdown.js <spec.yaml> <out.md> [--app-src <dir>]
//
// Needs `js-yaml` (npm install js-yaml). With --app-src, every endpoint is
// marked with whether the Flutter app's Dart code calls that path.
// Regenerate whenever docs/api/openapi*.yaml changes.
'use strict';
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const [, , specPath, outPath, ...rest] = process.argv;
if (!specPath || !outPath) {
  console.error('usage: openapi_to_markdown.js <spec.yaml> <out.md> [--app-src <dir>]');
  process.exit(2);
}
const appSrcIdx = rest.indexOf('--app-src');
const appSrc = appSrcIdx >= 0 ? rest[appSrcIdx + 1] : null;
const spec = yaml.load(fs.readFileSync(specPath, 'utf8'));
const METHODS = ['get', 'post', 'put', 'patch', 'delete'];

// ---------- helpers ----------
function resolve(obj, seen = new Set()) {
  if (!obj || typeof obj !== 'object') return obj;
  if (obj.$ref) {
    if (seen.has(obj.$ref)) return { $circular: obj.$ref };
    const target = obj.$ref.replace(/^#\//, '').split('/').reduce((o, k) => o && o[k], spec);
    return resolve(target, new Set([...seen, obj.$ref]));
  }
  return obj;
}
const refName = (s) => (s && s.$ref ? s.$ref.split('/').pop() : null);
const cell = (t) => String(t ?? '').replace(/\|/g, '\\|').replace(/\r?\n+/g, ' ').trim();

function typeOf(schemaIn) {
  if (!schemaIn) return '';
  const name = refName(schemaIn);
  const s = resolve(schemaIn);
  if (!s) return name || '';
  if (s.$circular) return `[${s.$circular.split('/').pop()}](#schema-${s.$circular.split('/').pop().toLowerCase()})`;
  const link = (n) => `[${n}](#schema-${n.toLowerCase()})`;
  if (name && (s.type === 'object' || s.properties || s.allOf || s.oneOf)) return link(name);
  if (s.oneOf || s.anyOf) return (s.oneOf || s.anyOf).map(typeOf).join(' \\| ');
  if (s.allOf) return s.allOf.map(typeOf).join(' & ');
  let t = Array.isArray(s.type) ? s.type.join(' \\| ') : s.type || (s.properties ? 'object' : '');
  if (t === 'array' || (Array.isArray(s.type) && s.type.includes('array'))) {
    t = `array of ${typeOf(s.items) || 'any'}`;
  }
  if (s.enum) t += ` (${s.enum.map((e) => '`' + e + '`').join(', ')})`;
  if (s.format) t += ` · ${s.format}`;
  return t;
}

function constraints(s) {
  s = resolve(s) || {};
  const c = [];
  if (s.minLength != null) c.push(`min ${s.minLength} chars`);
  if (s.maxLength != null) c.push(`max ${s.maxLength} chars`);
  if (s.minimum != null) c.push(`≥ ${s.minimum}`);
  if (s.maximum != null) c.push(`≤ ${s.maximum}`);
  if (s.maxItems != null) c.push(`max ${s.maxItems} items`);
  if (s.pattern) c.push(`pattern \`${s.pattern}\``);
  if (s.default !== undefined) c.push(`default \`${JSON.stringify(s.default)}\``);
  if (s.nullable || (Array.isArray(s.type) && s.type.includes('null'))) c.push('nullable');
  return c.join(', ');
}

function fieldsTable(schemaIn) {
  let s = resolve(schemaIn);
  if (!s) return '';
  if (s.allOf) {
    const merged = { properties: {}, required: [] };
    for (const part of s.allOf) {
      const p = resolve(part) || {};
      Object.assign(merged.properties, p.properties || {});
      merged.required.push(...(p.required || []));
    }
    s = merged;
  }
  if (!s.properties) return '';
  const req = new Set(s.required || []);
  const rows = Object.entries(s.properties).map(([k, v]) => {
    const r = resolve(v) || {};
    return `| \`${k}\` | ${typeOf(v)} | ${req.has(k) ? 'yes' : ''} | ${cell([r.description, constraints(v)].filter(Boolean).join(' — '))} |`;
  });
  return ['| Field | Type | Required | Notes |', '|---|---|---|---|', ...rows].join('\n');
}

function example(media) {
  if (!media) return null;
  if (media.example !== undefined) return media.example;
  if (media.examples) {
    const first = Object.values(media.examples)[0];
    return resolve(first)?.value;
  }
  const s = resolve(media.schema);
  return s && s.example !== undefined ? s.example : null;
}

// ---------- which paths does the app call? ----------
let appPaths = null;
if (appSrc) {
  appPaths = new Set();
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.dart')) {
        const src = fs.readFileSync(p, 'utf8');
        for (const m of src.matchAll(/'(\/[A-Za-z0-9_\-/${}.!()]+)'/g)) {
          appPaths.add(m[1].replace(/\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*/g, '{}').split('?')[0]);
        }
      }
    }
  };
  walk(appSrc);
}
const norm = (p) => p.replace(/\{[^}]+\}/g, '{}');
const usedByApp = (p) => (appPaths ? (appPaths.has(norm(p)) ? 'yes' : '—') : null);

// ---------- collect operations ----------
const tags = (spec.tags || []).map((t) => t.name);
const byTag = {};
for (const [p, item] of Object.entries(spec.paths || {})) {
  for (const m of METHODS) {
    const op = item[m];
    if (!op) continue;
    const tag = (op.tags || ['Other'])[0];
    if (!tags.includes(tag)) tags.push(tag);
    (byTag[tag] = byTag[tag] || []).push({ path: p, method: m, op, shared: item.parameters || [] });
  }
}
const anchor = (m, p) => `${m}-${p}`.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const authOf = (op) => {
  const sec = op.security !== undefined ? op.security : spec.security || [];
  if (!sec.length || sec.every((s) => Object.keys(s).length === 0)) return 'none (public)';
  return sec.map((s) => Object.keys(s).join(' + ') || 'none').join(' or ');
};

// ---------- write ----------
const out = [];
const servers = (spec.servers || []).map((s) => `\`${s.url}\`${s.description ? ` (${s.description})` : ''}`);
out.push(`# ${spec.info.title} — endpoint reference`, '');
out.push(`> Generated from \`${path.basename(specPath)}\` (OpenAPI ${spec.openapi}, API version ${spec.info.version}) by \`docs/api/tools/openapi_to_markdown.js\`. Do not edit by hand; regenerate.`, '');
out.push(`**Servers:** ${servers.join(', ') || '—'}`, '');
const total = Object.values(byTag).reduce((n, l) => n + l.length, 0);
out.push(`**${total} operations** in ${tags.length} groups.${appPaths ? ' The "App" column says whether the Flutter app\'s code calls the path today.' : ''}`, '');

out.push('## Index', '');
for (const tag of tags) {
  const list = byTag[tag];
  if (!list) continue;
  const tagDesc = (spec.tags || []).find((t) => t.name === tag)?.description;
  out.push(`### ${tag}`, '');
  if (tagDesc) out.push(cell(tagDesc), '');
  out.push(`| Method | Path | Summary | Auth${appPaths ? ' | App' : ''} |`, `|---|---|---|---${appPaths ? '|---' : ''}|`);
  for (const { path: p, method: m, op } of list) {
    out.push(`| \`${m.toUpperCase()}\` | [\`${p}\`](#${anchor(m, p)}) | ${cell(op.summary)} | ${authOf(op)}${appPaths ? ` | ${usedByApp(p)}` : ''} |`);
  }
  out.push('');
}

out.push('## Endpoints', '');
for (const tag of tags) {
  const list = byTag[tag];
  if (!list) continue;
  out.push(`## ${tag}`, '');
  for (const { path: p, method: m, op, shared } of list) {
    out.push(`<a id="${anchor(m, p)}"></a>`, `### \`${m.toUpperCase()} ${p}\``, '');
    if (op.summary) out.push(`**${cell(op.summary)}**`, '');
    if (op.description) out.push(op.description.trim(), '');
    out.push(`- **Auth:** ${authOf(op)}`);
    if (op.operationId) out.push(`- **Operation id:** \`${op.operationId}\``);
    if (appPaths) out.push(`- **Called by the app:** ${usedByApp(p)}`);
    if (op.deprecated) out.push('- **Deprecated**');
    out.push('');
    const params = [...shared, ...(op.parameters || [])].map((x) => resolve(x)).filter(Boolean);
    if (params.length) {
      out.push('**Parameters**', '', '| Name | In | Type | Required | Notes |', '|---|---|---|---|---|');
      for (const prm of params) {
        out.push(`| \`${prm.name}\` | ${prm.in} | ${typeOf(prm.schema)} | ${prm.required ? 'yes' : ''} | ${cell([prm.description, constraints(prm.schema)].filter(Boolean).join(' — '))} |`);
      }
      out.push('');
    }
    const body = resolve(op.requestBody);
    if (body && body.content) {
      for (const [ct, media] of Object.entries(body.content)) {
        const name = refName(media.schema);
        out.push(`**Request body** (\`${ct}\`${body.required ? ', required' : ''})${name ? `: [${name}](#schema-${name.toLowerCase()})` : ''}`, '');
        if (body.description) out.push(cell(body.description), '');
        const t = fieldsTable(media.schema);
        if (t) out.push(t, '');
        else if (media.schema) out.push(`Type: ${typeOf(media.schema)}`, '');
        const ex = example(media);
        if (ex != null) out.push('Example:', '```json', JSON.stringify(ex, null, 2), '```', '');
      }
    }
    if (op.responses) {
      out.push('**Responses**', '', '| Status | Meaning | Body |', '|---|---|---|');
      for (const [code, rIn] of Object.entries(op.responses)) {
        const r = resolve(rIn) || {};
        const media = r.content && Object.values(r.content)[0];
        out.push(`| \`${code}\` | ${cell(r.description)} | ${media ? typeOf(media.schema) : '—'} |`);
      }
      out.push('');
      const ok = Object.entries(op.responses).find(([c]) => c.startsWith('2'));
      const okMedia = ok && resolve(ok[1])?.content && Object.values(resolve(ok[1]).content)[0];
      const okEx = example(okMedia);
      if (okEx != null) out.push('Example response:', '```json', JSON.stringify(okEx, null, 2), '```', '');
    }
  }
}

const schemas = spec.components?.schemas || {};
if (Object.keys(schemas).length) {
  out.push('## Schemas', '');
  for (const [name, s] of Object.entries(schemas)) {
    const r = resolve(s);
    out.push(`<a id="schema-${name.toLowerCase()}"></a>`, `### ${name}`, '');
    if (r.description) out.push(r.description.trim(), '');
    const t = fieldsTable(s);
    out.push(t || `Type: ${typeOf(s)}`, '');
  }
}

fs.writeFileSync(outPath, out.join('\n'));
console.log(`wrote ${outPath}: ${total} operations, ${Object.keys(schemas).length} schemas`);
