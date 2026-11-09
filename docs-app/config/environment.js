'use strict'

module.exports = function (environment) {
  const ENV = {
    modulePrefix: 'docs-app',
    environment,
    // The guide is served from joegaudet.com/ember-joinery/guide/.
    rootURL: process.env.JOINERY_GUIDE ? '/ember-joinery/guide/' : '/',
    // Real URLs: pages link to each other relatively. On GitHub Pages, deep links are served by
    // the 404.html fallback the build writes.
    locationType: 'history',
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
