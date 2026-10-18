// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 1, // WebKit cold start is occasionally slow under parallel load
  workers: process.env.CI ? 2 : 3,
  reporter: [['list'], ['html', { open: 'never' }]],
  outputDir: 'test-results',
  use: { trace: 'on-first-retry', screenshot: 'only-on-failure' },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'Pixel 5', use: { ...devices['Pixel 5'] } },
    { name: 'iPhone 12', use: { ...devices['iPhone 12'] } },
    { name: 'landscape phone', use: { ...devices['Pixel 5'], viewport: { width: 844, height: 390 }, isMobile: true } },
  ],
  webServer: [
    { command: 'npx http-server build/web -p 8180 -c-1 --silent', url: 'http://127.0.0.1:8180', reuseExistingServer: !process.env.CI, timeout: 30000 },
    { command: 'npx http-server build/web_qa_win -p 8181 -c-1 --silent', url: 'http://127.0.0.1:8181', reuseExistingServer: !process.env.CI, timeout: 30000 },
    { command: 'npx http-server build/web_qa_timeout -p 8182 -c-1 --silent', url: 'http://127.0.0.1:8182', reuseExistingServer: !process.env.CI, timeout: 30000 },
  ],
});
