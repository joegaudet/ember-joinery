import { registerDestructor } from '@ember/destroyable'
import type RouterService from '@ember/routing/router-service'

/**
 * The app-relative path a link to `href` goes to, when the router should take it: same origin,
 * under the guide's rootURL, and not just a jump to a heading on the current page. Anything
 * else (the project site the guide is served under, other sites) is left to the browser.
 */
export function routablePath(href: string, here: string, rootURL: string): string | undefined {
  const url = new URL(href, here)
  const current = new URL(here)
  if (url.origin !== current.origin) return undefined
  if (url.pathname === current.pathname && url.search === current.search && url.hash) {
    return undefined
  }
  const root = rootURL.endsWith('/') ? rootURL : `${rootURL}/`
  if (url.pathname !== root.slice(0, -1) && !url.pathname.startsWith(root)) return undefined
  return `/${url.pathname.slice(root.length)}${url.search}${url.hash}`
}

/**
 * Plain `<a href>` links (the ones in markdown and in Kolay's sidebar) become router transitions
 * instead of full page loads, until `owner` is destroyed.
 */
export function routeLinks(owner: object, router: RouterService): void {
  const handler = (event: MouseEvent) => {
    if (event.defaultPrevented || event.button !== 0) return
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    const anchor = (event.target as Element | null)?.closest?.('a[href]')
    if (!(anchor instanceof HTMLAnchorElement)) return
    if ((anchor.target && anchor.target !== '_self') || anchor.hasAttribute('download')) return
    const path = routablePath(anchor.href, window.location.href, router.rootURL)
    if (path === undefined) return
    event.preventDefault()
    void router.transitionTo(path)
  }
  document.body.addEventListener('click', handler)
  registerDestructor(owner, () => document.body.removeEventListener('click', handler))
}
