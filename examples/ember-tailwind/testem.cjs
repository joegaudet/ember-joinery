'use strict'

const { existsSync } = require('node:fs')

// CI runs the suite in the runner's preinstalled Chrome. Elsewhere, the Playwright Chromium at
// /opt/pw-browsers/chromium (cloud dev containers often have one) is used when it is there, and
// CHROME_BIN names any other Chrome or Chromium.
const LOCAL_CHROMIUM = '/opt/pw-browsers/chromium'
const chrome =
  process.env.CHROME_BIN || (!process.env.CI && existsSync(LOCAL_CHROMIUM) ? LOCAL_CHROMIUM : null)

// Chrome's sandbox can't start inside a container, or as root.
const noSandbox = process.env.CI || process.getuid?.() === 0

if (typeof module !== 'undefined') {
  module.exports = {
    test_page: 'tests/index.html?hidepassed',
    cwd: 'dist',
    disable_watching: true,
    launch_in_ci: ['Chrome'],
    launch_in_dev: ['Chrome'],
    browser_start_timeout: 120,
    ...(chrome && { browser_paths: { Chrome: chrome } }),
    browser_args: {
      Chrome: {
        ci: [
          noSandbox ? '--no-sandbox' : null,
          '--headless',
          '--disable-dev-shm-usage',
          '--disable-software-rasterizer',
          '--mute-audio',
          '--remote-debugging-port=0',
          '--window-size=1440,900',
        ].filter(Boolean),
      },
    },
  }
}
