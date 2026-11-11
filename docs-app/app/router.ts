import EmberRouter from '@embroider/router'
import { addRoutes } from 'kolay'
import config from 'docs-app/config/environment'

export default class Router extends EmberRouter {
  location = config.locationType
  rootURL = config.rootURL
}

Router.map(function () {
  // One example on its own, with no frame or guide chrome: what the parity check screenshots.
  // Mapped before Kolay's catch-all, which would claim the path otherwise.
  this.route('parity', { path: '/parity/:name' })
  addRoutes(this)
})
