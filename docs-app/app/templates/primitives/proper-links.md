# Proper Links

`properLinks` lets an app use plain `<a href>` links: a click on a link to one of the app's
routes becomes a transition, with no `<LinkTo>`. Links the browser should keep still do what
the browser does: one with a `target`, `download` or `rel="external"`, a click with a modifier
key or another button, a link to another site or to a heading on the page. It is
ember-primitives' `properLinks`.

<Example @name="proper-links-decisions" @title="Who follows each link" />

## Usage

Decorate the app's router:

```ts
// app/router.ts
import EmberRouter from '@embroider/router'
import { properLinks } from '@ember-joinery/primitives/proper-links'
import config from 'my-app/config/environment'

@properLinks
export default class Router extends EmberRouter {
  location = config.locationType
  rootURL = config.rootURL
}
```

Paths that something other than the app serves can be left to the browser:
`@properLinks({ ignore: ['/admin'] })` (a string matches anywhere in the path; a RegExp works
too). Without decorators, call it: `properLinks(class Router extends EmberRouter {})`.

`setupProperLinks(context, options)` does the same without the router: for anything with an
owner, until it is destroyed. It is what a test uses.

## API

| Export                                       | What it does                                                        |
| -------------------------------------------- | ------------------------------------------------------------------- |
| `properLinks` / `properLinks(options)`       | Decorates the router class                                          |
| `setupProperLinks(context, options?)`        | The same for `context`'s owner, until `context` is destroyed        |
| `shouldHandle(href, anchor, event, ignore?)` | Whether the router should take a click on `anchor` from page `href` |
| `handleLink(router, anchor, event, ignore?)` | Routes the click if it should; returns whether it did               |
| `getAnchor(event)`                           | The `<a>` a click was in, through the composed path                 |

### From ember-primitives

`properLinks` and `shouldHandle` are the same (`shouldHandle` is should-handle-link's, ported).
ember-primitives' `setup` and `handle` are `setupProperLinks` (which also takes an owner) and
`handleLink`. Joinery also leaves same-origin links outside the app's `rootURL` to the browser.

## Testing

`setupRouting` from `@ember-joinery/test-support` gives a test its own routes, without
scaffolding them in the app, and `setupProperLinks(this.owner)` lets its plain links route:

```ts
import { click, currentURL, visit } from '@ember/test-helpers'
import { setupProperLinks } from '@ember-joinery/primitives/proper-links'
import { getRouter, setupRouting } from '@ember-joinery/test-support'

test('the nav routes', async function (assert) {
  setupRouting(this.owner, function () {
    this.route('settings', function () {
      this.route('profile')
    })
  })
  setupProperLinks(this.owner)
  this.owner.register('template:application', <template><a href="/settings/profile">Profile</a></template>)

  await visit('/')
  await click('a')
  assert.strictEqual(currentURL(), '/settings/profile')
  assert.strictEqual(getRouter(this.owner).currentRouteName, 'settings.profile')
})
```

`setupRouting(owner, map, { rootURL })` returns the router service; call it before `visit()`.
In a rendering test it starts the router too, so `qp` and `link` have a URL to read once you
`transitionTo()` one. ember-primitives' `setupRouting` applies `properLinks` itself; here that is
the separate `setupProperLinks` call.
