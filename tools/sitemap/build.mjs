#!/usr/bin/env node
// Turn out/manifest.json + out/shots into one self-contained out/sitemap.html.
// Screenshots are inlined; the Save Page WE snapshots stay beside it in out/pages/.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = process.env.SITEMAP_OUT || join(HERE, 'out');
const m = JSON.parse(readFileSync(join(OUT, 'manifest.json'), 'utf8'));

// --standalone: a copy that works with nothing beside it (for hosting the one
// file somewhere), so it leaves out the links to the saved pages in out/pages/.
const standalone = process.argv.includes('--standalone');

const isParam = (s) => /^\[.+\]$/.test(s);
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const matchers = m.routes
  .map((r) => ({
    pattern: r.pattern,
    dynamic: r.pattern.includes('['),
    re: new RegExp('^' + r.pattern.split('/').map((s) => (isParam(s) ? '[^/?#]+' : esc(s))).join('/') + '/?$')
  }))
  .sort((a, b) => a.dynamic - b.dynamic);
const toPattern = (href) => {
  const path = href.split('?')[0].split('#')[0] || '/';
  return matchers.find((x) => x.re.test(path))?.pattern || null;
};

// Internal links become edges. Global nav links are on every page, so they are
// recorded once as "in nav" instead of as 30 identical edges.
const edges = new Map();
const inNav = new Set();
const dead = {};
// "Global nav" = an href present on most logged-in pages, whatever element it sits in.
const authed = m.routes.filter((r) => r.links && !r.anonymous);
const seenOn = {};
for (const r of authed) for (const href of new Set(r.links.map((l) => l.href))) seenOn[href] = (seenOn[href] || 0) + 1;
const globalHrefs = new Set(Object.keys(seenOn).filter((h) => authed.length > 3 && seenOn[h] >= authed.length * 0.7));
for (const r of m.routes) {
  for (const l of r.links || []) {
    const to = toPattern(l.href);
    if (!to) {
      (dead[r.pattern] ||= new Set()).add(l.href);
      continue;
    }
    if (globalHrefs.has(l.href)) {
      inNav.add(to);
      continue;
    }
    if (to === r.pattern) continue;
    const k = r.pattern + '\u0000' + to;
    const e = edges.get(k) || { from: r.pattern, to, count: 0, labels: [] };
    e.count++;
    if (l.text && e.labels.length < 4 && !e.labels.includes(l.text)) e.labels.push(l.text);
    edges.set(k, e);
  }
}

const images = {};
const routes = m.routes.map((r) => {
  const { links, ...rest } = r;
  for (const [vp, s] of Object.entries(r.shots || {})) {
    const p = join(OUT, s.file);
    if (existsSync(p)) images[`${r.pattern}|${vp}`] = 'data:image/webp;base64,' + readFileSync(p).toString('base64');
  }
  return {
    ...rest,
    inNav: inNav.has(r.pattern),
    unmatchedLinks: [...(dead[r.pattern] || [])].slice(0, 10),
    saved: !standalone && r.saved?.file && existsSync(join(OUT, r.saved.file)) ? r.saved.file : null
  };
});

const data = { ...m, routes, edges: [...edges.values()] };
const json = (o) => JSON.stringify(o).replace(/</g, '\\u003c');

const html = readFileSync(join(HERE, 'template.html'), 'utf8')
  .replace('/*__DATA__*/null', () => json(data))
  .replace('/*__IMAGES__*/null', () => json(images));

const dest = join(OUT, standalone ? 'sitemap-standalone.html' : 'sitemap.html');
writeFileSync(dest, html);
console.log(`${dest}  ${(html.length / 1048576).toFixed(1)} MB, ${routes.length} routes, ${Object.keys(images).length} screenshots, ${data.edges.length} links`);
