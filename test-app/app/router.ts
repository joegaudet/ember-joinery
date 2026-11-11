import EmberRouter from '@embroider/router'
import config from 'test-app/config/environment'

export default class Router extends EmberRouter {
  location = config.locationType
  rootURL = config.rootURL
}

// The live demo: the dashboard at /, and the settings dialog over it at /settings. The route
// is `preferences`, so a test's own `settings` routes don't pick up its template and controller.
Router.map(function () {
  this.route('preferences', { path: '/settings' })
})
