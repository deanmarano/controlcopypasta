const { createServer } = require('node:http');
const { readFile } = require('node:fs/promises');
const { join, extname } = require('node:path');

const FIXTURES_DIR = join(__dirname, 'fixtures');
const PORT = 3456;
const VALID_TOKEN = 'test-token-123';

const MIME_TYPES = {
  '.html': 'text/html',
  '.json': 'application/json',
};

// Mock recipe returned by server-side parse
const PARSED_RECIPE = {
  title: 'Server Parsed Recipe',
  description: 'Parsed by the server.',
  image_url: 'https://example.com/parsed.jpg',
  ingredients: [
    { text: '1 cup flour', group: null },
    { text: '2 eggs', group: null },
  ],
  instructions: [
    { step: 1, text: 'Mix ingredients.' },
    { step: 2, text: 'Bake at 350F.' },
  ],
  prep_time_minutes: 10,
  cook_time_minutes: 25,
  total_time_minutes: 35,
  servings: '4',
};

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

function sendJson(res, status, data) {
  const body = JSON.stringify(data);
  res.writeHead(status, { ...corsHeaders(), 'Content-Type': 'application/json' });
  res.end(body);
}

function getToken(req) {
  const auth = req.headers['authorization'] || '';
  return auth.startsWith('Bearer ') ? auth.slice(7) : null;
}

async function handleRequest(req, res) {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders());
    res.end();
    return;
  }

  // Serve fixture files
  if (req.method === 'GET' && url.pathname.startsWith('/fixtures/')) {
    const filename = url.pathname.replace('/fixtures/', '');
    try {
      const content = await readFile(join(FIXTURES_DIR, filename), 'utf-8');
      const ext = extname(filename);
      res.writeHead(200, {
        ...corsHeaders(),
        'Content-Type': MIME_TYPES[ext] || 'text/plain',
      });
      res.end(content);
    } catch {
      res.writeHead(404, corsHeaders());
      res.end('Not found');
    }
    return;
  }

  // GET /api/auth/me
  if (req.method === 'GET' && url.pathname === '/api/auth/me') {
    const token = getToken(req);
    if (token === VALID_TOKEN) {
      sendJson(res, 200, { data: { id: 1, email: 'test@example.com' } });
    } else {
      sendJson(res, 401, { error: 'unauthorized' });
    }
    return;
  }

  // POST /api/recipes/parse
  if (req.method === 'POST' && url.pathname === '/api/recipes/parse') {
    const token = getToken(req);
    if (token !== VALID_TOKEN) {
      sendJson(res, 401, { error: 'unauthorized' });
      return;
    }
    sendJson(res, 200, { data: PARSED_RECIPE });
    return;
  }

  // POST /api/recipes
  if (req.method === 'POST' && url.pathname === '/api/recipes') {
    const token = getToken(req);
    if (token !== VALID_TOKEN) {
      sendJson(res, 401, { error: 'unauthorized' });
      return;
    }
    sendJson(res, 201, { data: { id: 'test-recipe-id' } });
    return;
  }

  res.writeHead(404, corsHeaders());
  res.end('Not found');
}

let serverInstance;

function startServer() {
  return new Promise((resolve) => {
    serverInstance = createServer(handleRequest);
    serverInstance.listen(PORT, () => {
      resolve(serverInstance);
    });
  });
}

function stopServer() {
  return new Promise((resolve) => {
    if (serverInstance) {
      serverInstance.close(resolve);
    } else {
      resolve();
    }
  });
}

module.exports = { startServer, stopServer, PORT, VALID_TOKEN, PARSED_RECIPE };
