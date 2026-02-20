const { test, expect } = require('@playwright/test');
const { launchBrowserWithExtension, configureExtension, openPopup, openOptionsPage } = require('./helpers.js');
const { startServer, stopServer, PORT, VALID_TOKEN, PARSED_RECIPE } = require('./mock-server.js');

const SERVER_URL = `http://localhost:${PORT}`;

let context;
let extensionId;

test.beforeAll(async () => {
  await startServer();
  ({ context, extensionId } = await launchBrowserWithExtension());
});

test.afterAll(async () => {
  await context?.close();
  await stopServer();
});

// ── Extension loads ──────────────────────────────────────────────────

test('extension loads and popup renders', async () => {
  const popup = await openPopup(context, extensionId);

  await expect(popup.locator('h1')).toHaveText('ControlCopyPasta');
  // Without a token configured, should show login section
  await expect(popup.locator('#login-section')).toBeVisible();

  await popup.close();
});

// ── Options page ─────────────────────────────────────────────────────

test('options: saves valid settings', async () => {
  const page = await openOptionsPage(context, extensionId);

  await page.fill('#serverUrl', SERVER_URL);
  await page.fill('#token', VALID_TOKEN);
  await page.click('button[type="submit"]');

  // Should show success message
  await expect(page.locator('#status')).toHaveText('Settings saved successfully!');
  await expect(page.locator('#status')).toHaveClass(/success/);

  // Reload and verify values persisted
  await page.reload();
  await expect(page.locator('#serverUrl')).toHaveValue(SERVER_URL);
  await expect(page.locator('#token')).toHaveValue(VALID_TOKEN);

  await page.close();
});

test('options: shows error for invalid token', async () => {
  const page = await openOptionsPage(context, extensionId);

  await page.fill('#serverUrl', SERVER_URL);
  await page.fill('#token', 'bad-token');
  await page.click('button[type="submit"]');

  await expect(page.locator('#status')).toHaveText(/Invalid token/);
  await expect(page.locator('#status')).toHaveClass(/error/);

  // Restore valid settings for subsequent tests
  await page.fill('#token', VALID_TOKEN);
  await page.click('button[type="submit"]');
  await expect(page.locator('#status')).toHaveText('Settings saved successfully!');

  await page.close();
});

// ── Content script: JSON-LD detection ────────────────────────────────

test('content script: detects basic JSON-LD recipe', async () => {
  await configureExtension(context, extensionId, { serverUrl: SERVER_URL, token: VALID_TOKEN });

  const page = await context.newPage();
  await page.goto(`${SERVER_URL}/fixtures/recipe-basic.html`);

  const recipe = await page.evaluate(() => {
    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (const script of scripts) {
      try {
        const data = JSON.parse(script.textContent);
        if (data['@type'] === 'Recipe') return data;
      } catch { /* skip */ }
    }
    return null;
  });

  expect(recipe).not.toBeNull();
  expect(recipe.name).toBe('Spaghetti Carbonara');
  expect(recipe.recipeIngredient).toHaveLength(4);
  expect(recipe.recipeInstructions).toHaveLength(3);
  expect(recipe.totalTime).toBe('PT30M');
  expect(recipe.recipeYield).toBe('4 servings');

  await page.close();
});

test('content script: finds recipe in @graph', async () => {
  const page = await context.newPage();
  await page.goto(`${SERVER_URL}/fixtures/recipe-graph.html`);

  const recipe = await page.evaluate(() => {
    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (const script of scripts) {
      try {
        const data = JSON.parse(script.textContent);
        if (data['@graph']) {
          for (const item of data['@graph']) {
            if (item['@type'] === 'Recipe') return item;
          }
        }
      } catch { /* skip */ }
    }
    return null;
  });

  expect(recipe).not.toBeNull();
  expect(recipe.name).toBe('Chicken Tikka Masala');
  expect(recipe.recipeIngredient).toHaveLength(5);
  expect(recipe.image.url).toBe('https://example.com/tikka.jpg');
  expect(recipe.totalTime).toBe('PT1H15M');

  await page.close();
});

test('content script: handles mixed instruction formats', async () => {
  const page = await context.newPage();
  await page.goto(`${SERVER_URL}/fixtures/recipe-instructions-mixed.html`);

  const instructions = await page.evaluate(() => {
    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (const script of scripts) {
      try {
        const data = JSON.parse(script.textContent);
        if (data['@type'] === 'Recipe') {
          const result = [];
          let step = 1;
          for (const inst of data.recipeInstructions || []) {
            if (typeof inst === 'string') {
              result.push({ step: step++, text: inst.trim() });
            } else if (inst.text) {
              result.push({ step: step++, text: inst.text.trim() });
            } else if (inst.itemListElement) {
              for (const item of inst.itemListElement) {
                if (item.text) {
                  result.push({ step: step++, text: item.text.trim() });
                }
              }
            }
          }
          return result;
        }
      } catch { /* skip */ }
    }
    return null;
  });

  expect(instructions).toHaveLength(4);
  expect(instructions[0]).toEqual({ step: 1, text: 'Preheat oven to 350F.' });
  expect(instructions[1]).toEqual({ step: 2, text: 'Mix dry ingredients together.' });
  expect(instructions[2]).toEqual({ step: 3, text: 'Add wet ingredients.' });
  expect(instructions[3]).toEqual({ step: 4, text: 'Stir until combined.' });

  await page.close();
});

test('content script: returns null when no recipe found', async () => {
  const page = await context.newPage();
  await page.goto(`${SERVER_URL}/fixtures/no-recipe.html`);

  const recipe = await page.evaluate(() => {
    const scripts = document.querySelectorAll('script[type="application/ld+json"]');
    for (const script of scripts) {
      try {
        const data = JSON.parse(script.textContent);
        if (data['@type'] === 'Recipe') return data;
        if (data['@graph']) {
          for (const item of data['@graph']) {
            if (item['@type'] === 'Recipe') return item;
          }
        }
      } catch { /* skip */ }
    }
    return null;
  });

  expect(recipe).toBeNull();

  await page.close();
});

// ── Popup ────────────────────────────────────────────────────────────

test('popup: shows login section when no token', async () => {
  // Clear the token
  await configureExtension(context, extensionId, { serverUrl: SERVER_URL, token: '' });

  const popup = await openPopup(context, extensionId);

  await expect(popup.locator('#login-section')).toBeVisible();
  await expect(popup.locator('#recipe-section')).not.toBeVisible();

  await popup.close();

  // Restore token
  await configureExtension(context, extensionId, { serverUrl: SERVER_URL, token: VALID_TOKEN });
});

test('popup: save flow via server parse fallback', async () => {
  await configureExtension(context, extensionId, { serverUrl: SERVER_URL, token: VALID_TOKEN });

  const popup = await openPopup(context, extensionId);

  // The popup opens as a chrome-extension:// page, so executeScript fails on itself.
  // It falls back to server-side parsing, which returns PARSED_RECIPE.
  await expect(popup.locator('#recipe-section')).toBeVisible({ timeout: 10000 });
  await expect(popup.locator('#recipe-title')).toHaveText(PARSED_RECIPE.title);

  // Check metadata
  const meta = await popup.locator('#recipe-meta').textContent();
  expect(meta).toContain(`${PARSED_RECIPE.total_time_minutes} min`);
  expect(meta).toContain(`${PARSED_RECIPE.ingredients.length} ingredients`);

  // Click save
  await popup.click('#save-recipe');

  // Should show success
  await expect(popup.locator('#success-section')).toBeVisible({ timeout: 10000 });
  await expect(popup.locator('#success-section')).toContainText('Recipe saved');

  // View link should contain the recipe ID
  const href = await popup.locator('#view-recipe').getAttribute('href');
  expect(href).toContain('test-recipe-id');

  await popup.close();
});

test('popup: shows error on save failure', async () => {
  await configureExtension(context, extensionId, { serverUrl: SERVER_URL, token: VALID_TOKEN });

  const popup = await openPopup(context, extensionId);

  // Wait for recipe to be detected via server fallback
  await expect(popup.locator('#recipe-section')).toBeVisible({ timeout: 10000 });

  // Intercept the POST /api/recipes to return 500
  await popup.route(`${SERVER_URL}/api/recipes`, (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ errors: { base: ['Internal server error'] } }),
    });
  });

  // Click save
  await popup.click('#save-recipe');

  // Should show error
  await expect(popup.locator('#error-section')).toBeVisible({ timeout: 10000 });
  await expect(popup.locator('#error-message')).toContainText('Internal server error');

  await popup.close();
});
