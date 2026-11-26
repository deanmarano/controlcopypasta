#!/usr/bin/env node
// Crawl every SvelteKit route in the live app through the remote Firefox and write
// out/manifest.json + out/shots/*.webp + out/pages/*.html. build.mjs turns that into
// the single-file map.
//
//   node capture.mjs                    everything
//   node capture.mjs --only=/recipes    routes whose pattern starts with a prefix
//   node capture.mjs --include=admin    also capture normally skipped sections
//   node capture.mjs --no-pages         skip the Save Page WE snapshots
import { readdirSync, mkdirSync, writeFileSync, rmSync, statSync, renameSync, existsSync, readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { Driver, sleep } from './driver.mjs';
import * as cfg from './config.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..', '..');
const ROUTES_DIR = join(REPO, 'frontend', 'src', 'routes');
const OUT = process.env.SITEMAP_OUT || join(HERE, 'out');
const SHOTS = join(OUT, 'shots');
const PAGES = join(OUT, 'pages');
const TMP = join(tmpdir(), `sitemap-tiles-${process.pid}`);
const STASH_KEY = '__sitemap_token_stash';
const HARNESS = `${cfg.BASE_URL}/robots.txt`; // any same-origin, script-free document
const DOWNLOADS = process.env.RFD_DOWNLOADS || ''; // host path of the remote Firefox's Downloads folder
const SAVE_TIMEOUT = Number(process.env.SITEMAP_SAVE_TIMEOUT || 90) * 1000;
const CONTAINER = process.env.RFD_BROWSER_CONTAINER || 'remote-firefox.web.1';

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  })
);
const include = String(args.include || '').split(',').filter(Boolean);
const only = args.only ? String(args.only).split(',') : null;
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);

// ── routes ───────────────────────────────────────────────────────────────────

function discoverRoutes(dir = ROUTES_DIR, prefix = '') {
  const out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (e.isDirectory()) {
      // (group) folders don't add a URL segment
      const seg = /^\(.*\)$/.test(e.name) ? '' : `/${e.name}`;
      out.push(...discoverRoutes(join(dir, e.name), prefix + seg));
    } else if (e.name === '+page.svelte') {
      out.push({ pattern: prefix || '/', file: relative(REPO, join(dir, e.name)) });
    }
  }
  return out;
}

function sectionFor(pattern) {
  for (const s of cfg.SECTIONS) {
    if (s.exact?.includes(pattern)) return s.id;
    if (s.match.some((m) => m !== '/' && (pattern === m || pattern.startsWith(m + '/') || m === ''))) return s.id;
  }
  return 'other';
}

const slug = (pattern) => pattern.replace(/^\//, '').replace(/[\[\]]/g, '_').replace(/\//g, '.') || 'index';
const isParam = (seg) => /^\[.+\]$/.test(seg);
const toRegex = (pattern) =>
  new RegExp('^' + pattern.split('/').map((s) => (isParam(s) ? '[^/?#]+' : s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))).join('/') + '/?$');

// ── in-page helpers (run inside the controlled tab) ──────────────────────────

const HARNESS_SETUP = `
  const d = document;
  d.documentElement.style.cssText = 'margin:0;padding:0;scrollbar-width:none;background:#fff';
  d.body.style.cssText = 'margin:0;padding:0;background:#fff';
  d.body.textContent = '';
  const f = d.createElement('iframe');
  f.id = 'sm-frame';
  // pointer-events:none keeps the real mouse pointer from leaving :hover styles in the shots
  f.style.cssText = 'position:absolute;top:0;left:0;border:0;display:block;background:#fff;pointer-events:none';
  const sp = d.createElement('div');
  sp.id = 'sm-spacer';
  sp.style.cssText = 'width:1px;height:1px';
  d.body.append(f, sp);
  return {w: innerWidth, h: innerHeight, dpr: devicePixelRatio};
`;

// Load a route in the harness iframe and wait until it stops changing.
const LOAD = `
  const f = document.getElementById('sm-frame');
  window.scrollTo(0, 0);
  f.style.width = arg.width + 'px';
  f.style.height = arg.height + 'px';
  document.getElementById('sm-spacer').style.height = '1px';
  await new Promise((res) => {
    const done = () => { f.removeEventListener('load', done); res(); };
    f.addEventListener('load', done);
    setTimeout(done, 10000);
    f.src = 'about:blank';
    setTimeout(() => { f.src = arg.url; }, 50);
  });
  // first load event may be the about:blank one
  await new Promise((r) => setTimeout(r, 400));
  const t0 = Date.now();
  let last = '', stable = 0;
  while (Date.now() - t0 < 16000) {
    await new Promise((r) => setTimeout(r, 250));
    let doc;
    try { doc = f.contentDocument; } catch (e) { continue; }
    if (!doc || !doc.body || doc.location.href === 'about:blank') continue;
    const text = doc.body.innerText || '';
    const busy = /^\\s*(Loading|Can't reach the server)/.test(text) || doc.querySelector('.loading, .spinner, [aria-busy="true"]');
    const imgs = [...doc.images].filter((i) => !i.complete).length;
    const sig = doc.documentElement.scrollHeight + ':' + text.length + ':' + imgs + ':' + doc.location.pathname;
    if (sig === last && !imgs && !(busy && Date.now() - t0 < 9000)) stable++; else stable = 0;
    last = sig;
    if (stable >= 4) break;
  }
  const doc = f.contentDocument;
  const full = Math.max(doc.documentElement.scrollHeight, doc.body.scrollHeight, arg.height);
  const height = Math.min(full, arg.maxHeight);
  f.style.height = height + 'px';
  document.getElementById('sm-spacer').style.height = (height + innerHeight) + 'px';
  await new Promise((r) => setTimeout(r, 350));
  const clean = (s) => (s || '').replace(/\\s+/g, ' ').trim();
  const info = {
    height, fullHeight: full,
    finalPath: doc.location.pathname + doc.location.search,
    title: doc.title,
    h1: clean((doc.querySelector('h1') || {}).innerText).slice(0, 120),
    headings: [...doc.querySelectorAll('h2')].map((h) => clean(h.innerText)).filter(Boolean).slice(0, 8).map((s) => s.slice(0, 60)),
    actions: [...new Set([...doc.querySelectorAll('main button, main [role=button], main a.btn-primary, main a.btn-secondary, main input[type=submit]')]
      .map((b) => clean(b.innerText || b.value || b.getAttribute('aria-label')).slice(0, 40)).filter(Boolean))].slice(0, 24),
    inputs: doc.querySelectorAll('main input:not([type=hidden]), main textarea, main select').length,
    images: doc.images.length,
    words: clean((doc.querySelector('main') || doc.body).innerText).split(' ').length,
  };
  if (arg.links) {
    info.links = [...doc.querySelectorAll('a[href]')].map((a) => {
      let u; try { u = new URL(a.href, doc.location.href); } catch (e) { return null; }
      if (u.origin !== doc.location.origin) return null;
      return { href: u.pathname + u.search, text: clean(a.innerText).slice(0, 50), nav: !!a.closest('header, footer, .mobile-menu') };
    }).filter(Boolean);
    info.external = [...new Set([...doc.querySelectorAll('a[href^="http"]')].map((a) => { try { return new URL(a.href).hostname; } catch (e) { return null; } })
      .filter((h) => h && h !== doc.location.hostname))].slice(0, 12);
  }
  return info;
`;

// Same settle loop for a page loaded directly in the tab (used before Save Page WE).
const SETTLE_TOP = `
  const t0 = Date.now();
  let last = '', stable = 0;
  while (Date.now() - t0 < 14000) {
    await new Promise((r) => setTimeout(r, 250));
    const text = document.body ? document.body.innerText : '';
    const busy = /^\\s*(Loading|Can't reach the server)/.test(text);
    const imgs = [...document.images].filter((i) => !i.complete).length;
    const sig = document.documentElement.scrollHeight + ':' + text.length + ':' + imgs;
    if (sig === last && !imgs && !busy) stable++; else stable = 0;
    last = sig;
    if (stable >= 4) break;
  }
  return location.pathname + location.search;
`;

// ── capture ──────────────────────────────────────────────────────────────────

const d = new Driver();
let view; // harness viewport {w,h}

async function enterHarness() {
  await d.newWindow(HARNESS); // reuses + focuses our single-tab window on this domain
  const here = await d.run('return location.href');
  if (here !== HARNESS) {
    await d.navigate(HARNESS);
  }
  view = await d.run(HARNESS_SETUP);
}

async function shoot(route, vp, wantLinks) {
  const width = Math.min(vp.width, view.w);
  const info = await d.run(LOAD, {
    url: cfg.BASE_URL + route.url,
    width,
    height: vp.height,
    maxHeight: cfg.MAX_HEIGHT,
    links: wantLinks
  });
  const tiles = [];
  for (let y = 0, i = 0; y < info.height; y += view.h, i++) {
    await d.run(`window.scrollTo(0, ${y}); await new Promise((r) => requestAnimationFrame(() => setTimeout(r, 140)));`);
    const file = join(TMP, `t${i}.png`);
    writeFileSync(file, await d.screenshot());
    tiles.push(file);
  }
  const rel = `shots/${slug(route.pattern)}.${vp.id}.webp`;
  execFileSync('magick', [...tiles, '-append', '-crop', `${width}x${info.height}+0+0`, '+repage', '-quality', '80', '-define', 'webp:method=4', join(OUT, rel)]);
  return { ...info, width, file: rel, truncated: info.fullHeight > info.height };
}

function resolveUrl(route, linksByPattern, statics) {
  const segs = route.pattern.split('/');
  let resolved = '';
  let parentPattern = '';
  for (let i = 1; i < segs.length; i++) {
    const seg = segs[i];
    const pattern = parentPattern + '/' + seg;
    if (!isParam(seg)) {
      resolved += '/' + seg;
    } else if (cfg.PARAMS[pattern]) {
      resolved += '/' + cfg.PARAMS[pattern];
    } else {
      // first link on the parent page that points one level below it and isn't a static sibling
      const pool = linksByPattern[parentPattern || '/'] || [];
      const re = new RegExp('^' + resolved.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '/([^/?#]+)$');
      const hit = pool.map((h) => h.split('?')[0]).find((h) => re.test(h) && !statics.has(h));
      if (!hit) return { error: `no link to a ${pattern} found on ${parentPattern || '/'}` };
      resolved = hit;
    }
    parentPattern = pattern;
  }
  const q = cfg.QUERY[route.pattern]?.(linksByPattern) || '';
  return { url: (resolved || '/') + q };
}

async function setAnonymous(on) {
  await d.run(
    on
      ? `const t = localStorage.getItem(arg.k); if (t) { localStorage.setItem(arg.s, t); localStorage.removeItem(arg.k); }`
      : `const t = localStorage.getItem(arg.s); if (t) { localStorage.setItem(arg.k, t); localStorage.removeItem(arg.s); }`,
    { k: cfg.TOKEN_KEY, s: STASH_KEY }
  );
}

function listDownloads() {
  try {
    return new Set(readdirSync(DOWNLOADS));
  } catch {
    return null;
  }
}

async function savePage(route) {
  const before = listDownloads();
  if (!before) return { error: DOWNLOADS ? `downloads folder ${DOWNLOADS} not readable` : 'RFD_DOWNLOADS is not set' };
  await d.newWindow(cfg.BASE_URL + route.url);
  await d.run(SETTLE_TOP);
  execFileSync('docker', ['exec', '-i', CONTAINER, 'perl', '-', 'alt', 'a'], {
    input: readFileSync(join(HERE, 'vnc-key.pl')),
    stdio: ['pipe', 'ignore', 'ignore']
  });
  const want = cfg.BASE_URL + route.url.split('?')[0];
  const t0 = Date.now();
  while (Date.now() - t0 < SAVE_TIMEOUT) {
    await sleep(500);
    // Save Page WE asks before saving a page with a resource it couldn't fetch; the
    // panel is plain DOM in the page, so answer "Continue" for it.
    await d.run(`for (const b of document.querySelectorAll('[id^="savepage-"][id$="-continue"], [id^="savepage-"][id$="-okay"]')) b.click();`).catch(() => {});
    const now = [...listDownloads()].filter((f) => !before.has(f));
    if (now.some((f) => f.endsWith('.part'))) continue;
    for (const html of now.filter((f) => /\.html?$/.test(f))) {
      const src = join(DOWNLOADS, html);
      const a = statSync(src).size;
      await sleep(400);
      if (!a || statSync(src).size !== a) continue;
      const body = readFileSync(src);
      // Save Page WE stamps the page it saved; a slow save from an earlier route must not be filed under this one.
      const at = body.indexOf('name="savepage-url" content="');
      const stamped = at < 0 ? '' : (body.subarray(at, at + 2000).toString('utf8').match(/content="([^"]*)"/) || [])[1] || '';
      rmSync(src);
      if (stamped.split('?')[0].replace(/\/$/, '') !== want.replace(/\/$/, '')) continue;
      const rel = `pages/${slug(route.pattern)}.html`;
      writeFileSync(join(OUT, rel), body);
      return { file: rel, bytes: a };
    }
  }
  return { error: `Save Page WE produced no file within ${SAVE_TIMEOUT / 1000}s` };
}

// ── main ─────────────────────────────────────────────────────────────────────

await d.connect();
mkdirSync(SHOTS, { recursive: true });
mkdirSync(PAGES, { recursive: true });
mkdirSync(TMP, { recursive: true });

const all = discoverRoutes()
  .map((r) => ({ ...r, section: sectionFor(r.pattern), dynamic: r.pattern.includes('['), anonymous: cfg.ANONYMOUS.includes(r.pattern) }))
  .sort((a, b) => a.pattern.split('/').length - b.pattern.split('/').length || a.pattern.localeCompare(b.pattern));
const statics = new Set(all.filter((r) => !r.dynamic).map((r) => r.pattern));

// Whatever tab the driver was pointed at before us, so we can hand it back.
const previous = await d.run('return location.href').catch(() => null);

await enterHarness();
await setAnonymous(false); // recover from an interrupted earlier run
const authed = await d.run(`return !!localStorage.getItem(arg)`, cfg.TOKEN_KEY);
if (!authed) {
  console.error(`Not logged in: open ${cfg.BASE_URL}/login in the remote Firefox, sign in, and rerun.`);
  process.exit(2);
}
log(`harness viewport ${view.w}x${view.h}, ${all.length} routes`);

const prior = existsSync(join(OUT, 'manifest.json')) ? JSON.parse(readFileSync(join(OUT, 'manifest.json'), 'utf8')) : null;
const priorByPattern = Object.fromEntries((prior?.routes || []).map((r) => [r.pattern, r]));
const linksByPattern = {};
for (const r of prior?.routes || []) if (r.links) linksByPattern[r.pattern] = r.links.map((l) => l.href);

const results = [];
try {
  for (const anonPass of [false, true]) {
    const batch = all.filter((r) => r.anonymous === anonPass);
    if (anonPass && batch.length) {
      await setAnonymous(true);
      log('— logged-out pass —');
    }
    for (const route of batch) {
      const skipped = cfg.SKIPPED_SECTIONS.includes(route.section) && !include.includes(route.section);
      const filtered = only && !only.some((p) => route.pattern === p || route.pattern.startsWith(p + '/'));
      if (filtered && priorByPattern[route.pattern]) {
        results.push(priorByPattern[route.pattern]);
        continue;
      }
      if (skipped || filtered) {
        results.push({ ...route, status: 'skipped', reason: skipped ? `section "${route.section}" is not captured by default` : 'filtered out by --only' });
        continue;
      }
      const res = resolveUrl(route, linksByPattern, statics);
      if (res.error) {
        log(`skip ${route.pattern}: ${res.error}`);
        results.push({ ...route, status: 'unresolved', reason: res.error });
        continue;
      }
      route.url = res.url;
      const entry = { ...route, status: 'captured', shots: {} };
      try {
        for (const vp of cfg.VIEWPORTS) {
          const first = vp === cfg.VIEWPORTS[0];
          const shot = await shoot(route, vp, first);
          if (first) {
            const { links, external, finalPath, title, h1, headings, actions, inputs, images, words } = shot;
            Object.assign(entry, { links, external, finalPath, title, h1, headings, actions, inputs, images, words });
            linksByPattern[route.pattern] = links.map((l) => l.href);
          }
          entry.shots[vp.id] = { file: shot.file, width: shot.width, height: shot.height, fullHeight: shot.fullHeight, truncated: shot.truncated };
        }
        log(`shot ${route.pattern}  ${route.url}${entry.finalPath !== route.url ? ` -> ${entry.finalPath}` : ''}  ${entry.shots.desktop.height}px`);
      } catch (e) {
        entry.status = 'error';
        entry.reason = e.message;
        log(`FAIL ${route.pattern}: ${e.message}`);
        await enterHarness().catch(() => {});
      }
      results.push(entry);
    }
  }
} finally {
  await setAnonymous(false);
}

if (!args['no-pages']) {
  log('— Save Page WE snapshots —');
  try {
    for (const entry of results) {
      if (entry.status !== 'captured') continue;
      if (only && !only.some((p) => entry.pattern === p || entry.pattern.startsWith(p + '/'))) continue;
      if (entry.anonymous) await d.newWindow(HARNESS).then(() => setAnonymous(true));
      try {
        const saved = await savePage(entry);
        entry.saved = saved;
        log(saved.file ? `saved ${entry.pattern}  ${(saved.bytes / 1024).toFixed(0)} KB` : `no save for ${entry.pattern}: ${saved.error}`);
      } catch (e) {
        entry.saved = { error: e.message };
        log(`no save for ${entry.pattern}: ${e.message}`);
      }
      if (entry.anonymous) await d.newWindow(HARNESS).then(() => setAnonymous(false));
    }
  } finally {
    await d.newWindow(HARNESS).catch(() => {});
    await setAnonymous(false);
  }
}

let sha = '';
try {
  sha = execFileSync('git', ['-C', REPO, 'rev-parse', '--short', 'HEAD'], { encoding: 'utf8' }).trim();
} catch {}

const order = Object.fromEntries(cfg.SECTIONS.map((s, i) => [s.id, i]));
results.sort((a, b) => order[a.section] - order[b.section] || a.pattern.localeCompare(b.pattern));
writeFileSync(
  join(OUT, 'manifest.json'),
  JSON.stringify(
    {
      capturedAt: new Date().toISOString(),
      baseUrl: cfg.BASE_URL,
      commit: sha,
      viewports: cfg.VIEWPORTS,
      sections: cfg.SECTIONS.map(({ id, title }) => ({ id, title })),
      routes: results
    },
    null,
    1
  )
);
rmSync(TMP, { recursive: true, force: true });

// Park our window on the app and hand the driver's active tab back where it was.
await d.navigate(`${cfg.BASE_URL}/home`).catch(() => {});
if (previous && !previous.startsWith(cfg.BASE_URL)) await d.newWindow(previous).catch(() => {});

const n = (s) => results.filter((r) => r.status === s).length;
log(`done: ${n('captured')} captured, ${n('unresolved')} unresolved, ${n('error')} failed, ${n('skipped')} skipped -> ${join(OUT, 'manifest.json')}`);
