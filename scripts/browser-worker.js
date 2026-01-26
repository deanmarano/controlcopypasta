const { chromium } = require('playwright');
const readline = require('readline');

let browser = null;

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

    case 'ping':
      return { id, status: 'pong' };

    case 'shutdown':
      await cleanup();
      process.exit(0);

    default:
      return { id, status: 'error', error: `Unknown command type: ${type}` };
  }
}

async function cleanup() {
  if (browser) {
    process.stderr.write('Shutting down browser\n');
    await browser.close();
    browser = null;
  }
}

// Signal handlers
process.on('SIGTERM', async () => {
  await cleanup();
  process.exit(0);
});

process.on('SIGINT', async () => {
  await cleanup();
  process.exit(0);
});

// Handle uncaught errors gracefully
process.on('uncaughtException', (err) => {
  process.stderr.write(`Uncaught exception: ${err.message}\n`);
});

process.on('unhandledRejection', (err) => {
  process.stderr.write(`Unhandled rejection: ${err}\n`);
});

// Main loop - read JSON lines from stdin
const rl = readline.createInterface({
  input: process.stdin,
  terminal: false
});

rl.on('line', async (line) => {
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

rl.on('close', async () => {
  await cleanup();
  process.exit(0);
});

// Signal ready
process.stderr.write('Browser worker ready\n');
