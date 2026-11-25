// Thin client for remote-firefox-driver (REST -> extension -> the long-running Firefox).
//
// Config comes from the environment so nothing secret lives in the repo:
//   RFD_URL       driver base URL            (default http://localhost:3000)
//   RFD_API_KEY   bearer key                 (or RFD_API_KEY_FILE pointing at a file holding it;
//                                             falls back to `dokku config:get remote-firefox-driver API_KEY`)
//   RFD_SESSION   session id                 (default: the first extension session)
import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// Machine-specific settings live in an untracked tools/sitemap/.env (see .env.example).
const envFile = join(dirname(fileURLToPath(import.meta.url)), '.env');
if (existsSync(envFile)) {
  for (const line of readFileSync(envFile, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && !(m[1] in process.env)) process.env[m[1]] = m[2].replace(/^(['"])(.*)\1$/, '$2');
  }
}

const BASE = (process.env.RFD_URL || 'http://localhost:3000').replace(/\/$/, '');

function loadKey() {
  if (process.env.RFD_API_KEY) return process.env.RFD_API_KEY.trim();
  if (process.env.RFD_API_KEY_FILE) return readFileSync(process.env.RFD_API_KEY_FILE, 'utf8').trim();
  try {
    return execFileSync('dokku', ['config:get', 'remote-firefox-driver', 'API_KEY'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    }).trim();
  } catch {
    throw new Error('No driver API key: set RFD_API_KEY or RFD_API_KEY_FILE');
  }
}

export class Driver {
  constructor() {
    this.key = loadKey();
    this.session = process.env.RFD_SESSION || null;
  }

  async raw(method, path, body) {
    const res = await fetch(`${BASE}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${this.key}`,
        ...(body ? { 'content-type': 'application/json' } : {})
      },
      body: body ? JSON.stringify(body) : undefined
    });
    const text = await res.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      json = { raw: text };
    }
    if (!res.ok) throw new Error(`${method} ${path} -> ${res.status}: ${json.error || text.slice(0, 200)}`);
    return json;
  }

  async connect() {
    if (!this.session) {
      const { sessions } = await this.raw('GET', '/sessions');
      const ext = sessions.find((s) => s.type === 'extension');
      if (!ext) throw new Error('No extension session: is the remote Firefox connected to the driver?');
      this.session = ext.id;
    }
    return this.session;
  }

  s(method, path, body) {
    return this.raw(method, `/sessions/${this.session}${path}`, body);
  }

  newWindow(url) {
    return this.s('POST', '/new-window', { url });
  }

  navigate(url) {
    return this.s('POST', '/navigate', { url });
  }

  /** Run JS in the controlled tab (content-script context). Returns the last expression's value. */
  async evaluate(expression) {
    return (await this.s('POST', '/evaluate', { expression })).result;
  }

  /**
   * Run an async function body in the tab and get its JSON-serialisable result.
   * executeScript resolves promises, so we hand it one.
   */
  async run(fnBody, arg) {
    const expr = `(async (arg) => { ${fnBody} })(${JSON.stringify(arg ?? null)}).then(v => JSON.stringify({ok: v === undefined ? null : v}), e => JSON.stringify({err: String(e && e.message || e)}))`;
    const out = JSON.parse(await this.evaluate(expr));
    if (out.err) throw new Error(`in-page: ${out.err}`);
    return out.ok;
  }

  /** PNG of the visible viewport of the focused window. */
  async screenshot() {
    const { screenshot } = await this.s('GET', '/screenshot?format=base64');
    return Buffer.from(screenshot, 'base64');
  }

  downloads() {
    return this.s('GET', '/downloads');
  }
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// `node driver.mjs eval '<js>'` / `node driver.mjs shot out.png` for poking at the browser by hand.
if (import.meta.url === `file://${process.argv[1]}`) {
  const [cmd, arg] = process.argv.slice(2);
  const d = new Driver();
  await d.connect();
  if (cmd === 'eval') console.log(await d.evaluate(arg));
  else if (cmd === 'run') console.log(JSON.stringify(await d.run(arg), null, 1));
  else if (cmd === 'nav') console.log(await d.navigate(arg));
  else if (cmd === 'win') console.log(await d.newWindow(arg));
  else if (cmd === 'downloads') console.log(JSON.stringify(await d.downloads(), null, 1));
  else if (cmd === 'shot') {
    const { writeFileSync } = await import('node:fs');
    writeFileSync(arg, await d.screenshot());
    console.log('wrote', arg);
  } else console.log('usage: driver.mjs eval|run|nav|win|shot|downloads <arg>');
}
