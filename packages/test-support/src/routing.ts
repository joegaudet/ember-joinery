import EmberRouter from '@ember/routing/router'
import type Owner from '@ember/owner'
import type RouterService from '@ember/routing/router-service'
import type { DSLCallback } from '@ember/routing/lib/dsl'

/** The routes a test needs: the same callback `Router.map` takes. */
export type RouteMap = DSLCallback

export interface SetupRoutingOptions {
  /** The rootURL the app is served under, as the router's own. Default `/`. */
  rootURL?: string
}

/**
 * Gives the test its own routes, without scaffolding them in the app: a router with `map`'s
 * routes (and `rootURL`), started so links, `qp` and `link` have a router to read. Call it at
 * the start of the test, before `visit()` or `render()`:
 *
 *   test('the tabs follow the URL', async function (assert) {
 *     setupRouting(this.owner, function () {
 *       this.route('settings', function () {
 *         this.route('profile')
 *       })
 *     })
 *     await visit('/settings/profile')
 *   })
 *
 * Routes need no files: Ember makes a default route for each. Register a template for the
 * ones that render something, as `this.owner.register('template:application', …)`. For plain
 * `<a href>` links to transition, as an app with `properLinks` does, also call
 * `setupProperLinks(this.owner)` from `@ember-joinery/primitives/proper-links`.
 *
 * It is ember-primitives' `setupRouting`, which applies `properLinks` itself.
 *
 * @returns the router service
 */
export function setupRouting(
  owner: Owner,
  map: RouteMap,
  options: SetupRoutingOptions = {},
): RouterService {
  const rootURL = options.rootURL ?? '/'
  if (!rootURL.startsWith('/')) {
    throw new Error(`Joinery: setupRouting's rootURL must start with "/", not "${rootURL}"`)
  }

  class TestRouter extends EmberRouter {
    override rootURL = rootURL
    override location = 'none'
  }
  TestRouter.map(map)

  // The app's own router is registered already; this test's replaces it. (An app instance has
  // `unregister`, from its registry, though the Owner type leaves it out.)
  const registry = owner as Owner & { unregister?: (fullName: string) => void }
  registry.unregister?.('router:main')
  owner.register('router:main', TestRouter)

  // There is no public API to start a router outside an app's boot; this is the one
  // `visit()` and Ember's own tests use.
  // eslint-disable-next-line ember/no-private-routing-service
  const router = owner.lookup('router:main') as unknown as { setupRouter(): void }
  router.setupRouter()
  return getRouter(owner)
}

/** The router service, typed: `getRouter(this.owner).currentURL`. */
export function getRouter(owner: Owner): RouterService {
  return owner.lookup('service:router')
}
