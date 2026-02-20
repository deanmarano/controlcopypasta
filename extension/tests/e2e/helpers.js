const { chromium } = require('@playwright/test');
const { join } = require('node:path');

const EXTENSION_PATH = join(__dirname, '..', '..');

/**
 * Launch Chromium with the extension loaded.
 * Returns { context, extensionId }.
 */
async function launchBrowserWithExtension() {
  const context = await chromium.launchPersistentContext('', {
    headless: false,
    args: [
      `--disable-extensions-except=${EXTENSION_PATH}`,
      `--load-extension=${EXTENSION_PATH}`,
      '--no-first-run',
      '--disable-gpu',
    ],
  });

  // Wait for the service worker to register and get the extension ID
  let serviceWorker;
  if (context.serviceWorkers().length > 0) {
    serviceWorker = context.serviceWorkers()[0];
  } else {
    serviceWorker = await context.waitForEvent('serviceworker');
  }

  const extensionId = serviceWorker.url().split('/')[2];

  return { context, extensionId };
}

/**
 * Configure the extension with server URL and token via chrome.storage.
 */
async function configureExtension(context, extensionId, { serverUrl, token }) {
  const optionsPage = await context.newPage();
  await optionsPage.goto(`chrome-extension://${extensionId}/popup/options.html`);

  // Use chrome.storage.sync.set directly to avoid form validation against the mock server
  await optionsPage.evaluate(({ serverUrl, token }) => {
    return new Promise((resolve) => {
      chrome.storage.sync.set({ serverUrl, token }, resolve);
    });
  }, { serverUrl, token });

  await optionsPage.close();
}

/**
 * Open the popup as a regular page.
 */
async function openPopup(context, extensionId) {
  const popup = await context.newPage();
  await popup.goto(`chrome-extension://${extensionId}/popup/popup.html`);
  return popup;
}

/**
 * Open the options page.
 */
async function openOptionsPage(context, extensionId) {
  const page = await context.newPage();
  await page.goto(`chrome-extension://${extensionId}/popup/options.html`);
  return page;
}

module.exports = { launchBrowserWithExtension, configureExtension, openPopup, openOptionsPage };
