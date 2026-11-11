import { registerDestructor } from '@ember/destroyable'
import type RouterService from '@ember/routing/router-service'
import { findOwner } from './store.ts'

/** Paths a plain link leaves to the browser: a string or a RegExp, matched against the path. */
export type IgnoredPath = string | RegExp

export interface ProperLinksOptions {
  /**
   * Paths the router should not take, because something other than the app serves them (a
   * server-rendered page under the same origin). A string is matched as a pattern anywhere in
   * the path (`'/admin'` matches `/admin/users`), as `String.prototype.match` would.
   */
  ignore?: IgnoredPath[]
}

/**
 * The `<a>` a click was in, if any: the clicked element may be a `<span>` or an `<svg>` inside
 * the link. Reads the event's composed path, so it finds the link even when the click removed
 * it (a menu item that closes its menu) or it sits in a shadow root.
 */
export function getAnchor(event: Event): HTMLAnchorElement | undefined {
  for (const target of event.composedPath()) {
    const name = (target as Partial<Node>).nodeName
    if (!name) return undefined
    if (name.toUpperCase() === 'A') return target as HTMLAnchorElement
  }
  return undefined
}

/**
 * Whether the app's router should take a click on `anchor` (`true`), or leave it to the browser
 * (`false`). The browser keeps a link with a `target`, `rel="external"` or `download`; a click
 * that isn't a plain left click (a middle click, or with Cmd, Ctrl, Shift or Alt); a click
 * another handler has already handled; a link to another origin; a link to a heading on the
 * current page; and a path in `ignore`.
 *
 * It is should-handle-link's `shouldHandle`, which ember-primitives' `properLinks` uses.
 *
 * @param href the page's URL now (`location.href`)
 */
export function shouldHandle(
  href: string,
  anchor: HTMLAnchorElement | undefined | null,
  event: MouseEvent,
  ignore: IgnoredPath[] = [],
): boolean {
  if (!anchor?.href) return false
  if (anchor.target) return false
  if (anchor.rel === 'external') return false
  if (anchor.hasAttribute('download')) return false
  if (event.button !== 0) return false
  if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return false
  if (event.defaultPrevented) return false

  const url = new URL(anchor.href)
  const here = new URL(href)
  if (url.origin !== here.origin) return false

  // A jump to a heading on this page is the browser's; going from /page#part to /page is not,
  // since the browser would reload the page for it.
  const [path, hash] = url.href.split('#')
  if (hash !== undefined && path === here.href.split('#')[0]) return false

  if (ignore.some(pattern => url.pathname.match(pattern))) return false
  return true
}

/**
 * Turns a click on `anchor` into a router transition when the router should take it (see
 * `shouldHandle`) and the URL is one of the app's routes, under its `rootURL`. Returns whether
 * it did; when it did, the click's default (a page load) is prevented.
 */
export function handleLink(
  router: RouterService,
  anchor: HTMLAnchorElement,
  event: MouseEvent,
  ignore: IgnoredPath[] = [],
): boolean {
  if (!shouldHandle(location.href, anchor, event, ignore)) return false

  const url = new URL(anchor.href)
  const fullPath = `${url.pathname}${url.search}${url.hash}`
  const rootURL = router.rootURL ?? '/'
  const root = rootURL.endsWith('/') ? rootURL : `${rootURL}/`
  // A path outside the app (served from the same origin by something else) is the browser's.
  if (fullPath !== root.slice(0, -1) && !fullPath.startsWith(root)) return false
  const appPath = fullPath.slice(root.length)

  let routed: unknown
  try {
    routed = router.recognize(`${root}${appPath}`)
  } catch (error) {
    if (error instanceof Error && error.name === 'UnrecognizedURLError') return false
    throw error
  }
  if (!routed) return false

  event.preventDefault()
  void router.transitionTo(`/${appPath}`)
  return true
}

/**
 * Makes plain `<a href>` links in the app transitions instead of page loads, until `context`
 * is destroyed: a click on a link to one of the app's routes goes through the router. Links
 * the browser should keep (see `shouldHandle`) still do what the browser does.
 *
 * For the whole app, decorate the router with `properLinks`. This is the same without a
 * decorator, for anything with an owner (the application route, or a test's owner):
 *
 *   setupProperLinks(this.owner)
 *
 * @param context anything with an owner, or the owner; its destruction removes the listener
 */
export function setupProperLinks(context: object, options: ProperLinksOptions = {}): void {
  const ignore = options.ignore ?? []
  const handler = (event: MouseEvent) => {
    const anchor = getAnchor(event)
    if (!anchor) return
    const owner = findOwner(context)
    if (!owner) throw new Error('Joinery: setupProperLinks() found no owner to route with')
    handleLink(owner.lookup('service:router'), anchor, event, ignore)
  }
  document.body.addEventListener('click', handler)
  registerDestructor(context, () => document.body.removeEventListener('click', handler))
}

type Constructor = new (...args: any[]) => object

function withProperLinks<Router extends Constructor>(
  Base: Router,
  options: ProperLinksOptions,
): Router {
  class RouterWithProperLinks extends Base {
    constructor(...args: any[]) {
      super(...args)
      setupProperLinks(this, options)
    }
  }
  return RouterWithProperLinks
}

/**
 * Lets the app use plain `<a href>` links: decorate the router with it, and a click on a link
 * to one of the app's routes becomes a transition, with no `<LinkTo>` needed.
 *
 *   import EmberRouter from '@embroider/router'
 *   import { properLinks } from '@ember-joinery/primitives/proper-links'
 *
 *   @properLinks
 *   export default class Router extends EmberRouter { … }
 *
 *   // or, with paths the router should leave to the server:
 *   @properLinks({ ignore: ['/legacy'] })
 *
 * Without decorators, call it: `export default properLinks(class Router extends EmberRouter {…})`.
 * It is ember-primitives' `properLinks`.
 */
export function properLinks<Router extends Constructor>(Base: Router): Router
export function properLinks(
  options: ProperLinksOptions,
): <Router extends Constructor>(Base: Router) => Router
export function properLinks<Router extends Constructor>(
  baseOrOptions: Router | ProperLinksOptions,
): Router | (<R extends Constructor>(Base: R) => R) {
  if (typeof baseOrOptions === 'function') return withProperLinks(baseOrOptions, {})
  return <R extends Constructor>(Base: R) => withProperLinks(Base, baseOrOptions)
}
