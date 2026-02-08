const { chromium } = require('playwright');
const readline = require('readline');

let browser = null;
let shuttingDown = false;

async function initBrowser() {
  if (!browser) {
    browser = await chromium.launch({
      headless: true,
      args: ['--disable-dev-shm-usage', '--no-sandbox']
    });
    process.stderr.write('Browser initialized\n');
  }
  return browser;
}

async function fetchHtml(url, timeout = 30000) {
  const b = await initBrowser();
  const context = await b.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });
  const page = await context.newPage();

  try {
    // Use domcontentloaded instead of networkidle - many recipe sites have
    // endless ad/analytics requests that prevent networkidle from completing
    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout
    });
    // Wait a bit for JS to render recipe content (JSON-LD is usually in initial HTML)
    await page.waitForTimeout(2000);
    return await page.content();
  } finally {
    await context.close();
  }
}

async function captureScreenshot(url, timeout = 30000) {
  const b = await initBrowser();
  const context = await b.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  try {
    await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout
    });
    // Wait for page to render
    await page.waitForTimeout(3000);
    // Take screenshot as base64
    const buffer = await page.screenshot({ type: 'jpeg', quality: 80 });
    return buffer.toString('base64');
  } finally {
    await context.close();
  }
}

async function handleCommand(command) {
  const { type, id, url, timeout } = command;

  switch (type) {
    case 'fetch':
      try {
        const html = await fetchHtml(url, timeout || 30000);
        return { id, status: 'ok', html };
      } catch (e) {
        return { id, status: 'error', error: e.message };
      }

    case 'screenshot':
      try {
        const screenshot = await captureScreenshot(url, timeout || 30000);
        return { id, status: 'ok', screenshot };
      } catch (e) {
        return { id, status: 'error', error: e.message };
      }

    case 'ping':
      return { id, status: 'pong' };

    case 'shutdown':
      shutdown('shutdown command');
      return { id, status: 'ok' };

    default:
      return { id, status: 'error', error: `Unknown command type: ${type}` };
  }
}

// Shut down gracefully with a hard timeout to guarantee exit.
// If browser.close() hangs (e.g. Chromium is stuck), we force-exit after 5 seconds.
function shutdown(reason) {
  if (shuttingDown) return;
  shuttingDown = true;
  process.stderr.write(`Shutting down: ${reason}\n`);

  const forceExitTimer = setTimeout(() => {
    process.stderr.write('Force exit: cleanup timed out\n');
    process.exit(1);
  }, 5000);
  forceExitTimer.unref();

  const closeBrowser = browser ? browser.close().catch(() => {}) : Promise.resolve();
  closeBrowser.then(() => process.exit(0));
}

// Signal handlers
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// If parent dies, stdin closes or errors — exit immediately
process.stdin.on('end', () => shutdown('stdin end'));
process.stdin.on('error', () => shutdown('stdin error'));

// Uncaught errors should be fatal — lingering is worse than crashing
process.on('uncaughtException', (err) => {
  process.stderr.write(`Uncaught exception: ${err.message}\n`);
  shutdown('uncaughtException');
});

process.on('unhandledRejection', (err) => {
  process.stderr.write(`Unhandled rejection: ${err}\n`);
  shutdown('unhandledRejection');
});

// Main loop - read JSON lines from stdin
const rl = readline.createInterface({
  input: process.stdin,
  terminal: false
});

rl.on('line', async (line) => {
  if (shuttingDown) return;
  try {
    const command = JSON.parse(line);
    const response = await handleCommand(command);
    if (response) {
      console.log(JSON.stringify(response));
    }
  } catch (e) {
    process.stderr.write(`Parse error: ${e.message}\n`);
    // Try to extract id from malformed JSON for error response
    const idMatch = line.match(/"id"\s*:\s*"([^"]+)"/);
    if (idMatch) {
      console.log(JSON.stringify({ id: idMatch[1], status: 'error', error: e.message }));
    }
  }
});

rl.on('close', () => shutdown('stdin closed'));

// Signal ready
process.stderr.write('Browser worker ready\n');
