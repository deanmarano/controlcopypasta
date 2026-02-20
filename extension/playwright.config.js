const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  retries: 0,
  workers: 1, // extensions require serial execution
  reporter: 'list',
  use: {
    headless: false, // extensions require headed mode
  },
});
