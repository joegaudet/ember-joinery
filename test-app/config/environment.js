'use strict'

module.exports = function (environment) {
  const ENV = {
    modulePrefix: 'test-app',
    environment,
    rootURL: process.env.JOINERY_DEMO ? '/ember-joinery/demo/' : '/',
    // Pages has no SPA fallback, so the demo uses hash URLs.
    locationType: process.env.JOINERY_DEMO ? 'hash' : 'history',
    EmberENV: {
      EXTEND_PROTOTYPES: false,
      FEATURES: {},
    },

    APP: {},
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.locationType = 'none'

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false
    ENV.APP.LOG_VIEW_LOOKUPS = false

    ENV.APP.rootElement = '#ember-testing'
    ENV.APP.autoboot = false
  }

  return ENV
}
