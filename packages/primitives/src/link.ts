import Helper from '@ember/component/helper'
import { service } from '@ember/service'
import type RouterService from '@ember/routing/router-service'
import { handleLink } from './proper-links.ts'

export interface LinkOptions {
  /**
   * Whether the query params count towards `isActive`: `true` for all of them (the link is
   * active only when the current URL's query params match the link's), or the names of the
   * ones that count. Default `false`: the path alone decides.
   */
  includeActiveQueryParams?: boolean | string[]
  /**
   * Whether the link is active on the routes below it too: `/forum/1` on `/forum/1/posts`.
   * Default `false`: only the route itself.
   */
  activeOnSubPaths?: boolean
}

export interface LinkState {
  /** Whether `href` goes to another origin, so following it leaves the app. */
  readonly isExternal: boolean
  /** Whether `href` is the current route (see the options). Reactive. Never for an external link. */
  readonly isActive: boolean
  /**
   * A click handler for the `<a>`, for an app without `properLinks`: it makes a click on a link
   * to one of the app's routes a transition. `{{on "click" l.handleClick}}`.
   */
  handleClick: (event: MouseEvent) => void
}

export interface LinkSignature {
  Args: {
    Positional: [href: string]
    Named: LinkOptions
  }
  Return: LinkState
}

/**
 * Whether `href` goes to another origin than the page's. A path (`/about`), a hash (`#top`) or
 * a query (`?tab=2`) never does.
 */
export function isExternal(href: string): boolean {
  if (!href) return false
  if (href.startsWith('#') || href.startsWith('/') || href.startsWith('?')) return false
  try {
    return new URL(href, location.href).origin !== location.origin
  } catch {
    return false
  }
}

/** The app-relative path of `path` (which includes the rootURL), or `undefined` outside the app. */
function withoutRoot(path: string, rootURL: string): string | undefined {
  const root = rootURL.endsWith('/') ? rootURL : `${rootURL}/`
  if (path === root.slice(0, -1)) return '/'
  if (!path.startsWith(root)) return undefined
  return `/${path.slice(root.length)}`
}

type RouteInfo = NonNullable<ReturnType<RouterService['recognize']>>

/** The values of a route's dynamic segments, outermost route first, for `router.isActive`. */
export function dynamicSegments(info: RouteInfo | null): unknown[] {
  const params: Record<string, unknown>[] = []
  let current: RouteInfo | null = info
  while (current?.parent) {
    if (current.params) params.unshift(current.params)
    current = current.parent
  }
  return params.flatMap(segment => Object.values(segment))
}

/**
 * Whether `href` is the current route. By default the path decides, query params aside:
 * `/forum/1` is active on `/forum/1` and `/forum/1?sort=new`. `includeQueryParams` makes query
 * params count (`true` for all, or the names of the ones that count), and `activeOnSubPaths`
 * makes the routes below count too. A link to another origin, or outside the app's `rootURL`,
 * is never active.
 */
export function isActive(
  router: RouterService,
  href: string,
  includeQueryParams: boolean | string[] = false,
  activeOnSubPaths = false,
): boolean {
  if (!href || isExternal(href)) return false
  const url = new URL(href, location.href)
  const rootURL = router.rootURL ?? '/'
  const path = withoutRoot(url.pathname, rootURL)
  if (path === undefined) return false

  if (!includeQueryParams) {
    const root = rootURL.endsWith('/') ? rootURL : `${rootURL}/`
    let info: RouteInfo | null
    try {
      info = router.recognize(`${root}${path.slice(1)}`)
    } catch {
      return false
    }
    if (!info) return false
    const name = activeOnSubPaths ? info.name.replace(/\.index$/, '') : info.name
    return router.isActive(name, ...(dynamicSegments(info) as []))
  }

  const currentPath = router.currentURL?.split('?')[0]?.split('#')[0]
  if (!currentPath) return false
  const onPath = activeOnSubPaths
    ? currentPath === path || currentPath.startsWith(path.endsWith('/') ? path : `${path}/`)
    : currentPath === path
  if (!onPath) return false

  const current = router.currentRoute?.queryParams ?? {}
  const linked = url.searchParams
  const names =
    includeQueryParams === true
      ? new Set([...Object.keys(current), ...linked.keys()])
      : new Set(includeQueryParams)
  for (const name of names) {
    const value = current[name]
    const now = value === undefined || value === null ? null : String(value)
    if (linked.get(name) !== now) return false
  }
  return true
}

/**
 * What an app needs to know about a link to render it: whether it leaves the app
 * (`isExternal`), whether it is the current route (`isActive`, for an active style or
 * `aria-current`), and a click handler that routes it (`handleClick`).
 *
 *   {{#let (link "/settings" activeOnSubPaths=true) as |l|}}
 *     <a href="/settings" aria-current={{if l.isActive "page"}} {{on "click" l.handleClick}}>
 *       Settings
 *     </a>
 *   {{/let}}
 *
 * It is ember-primitives' `link` helper, which its `Link` component renders with.
 */
class Link extends Helper<LinkSignature> {
  @service declare router: RouterService

  compute(
    [href]: [string],
    { includeActiveQueryParams = false, activeOnSubPaths = false }: LinkOptions,
  ): LinkState {
    if (typeof href !== 'string') throw new Error('Joinery: (link) needs the href')
    const router = this.router
    return {
      isExternal: isExternal(href),
      get isActive() {
        return isActive(router, href, includeActiveQueryParams, activeOnSubPaths)
      },
      handleClick: (event: MouseEvent) => {
        const anchor = event.currentTarget
        if (anchor instanceof HTMLAnchorElement) handleLink(router, anchor, event)
      },
    }
  }
}

export const link = Link
