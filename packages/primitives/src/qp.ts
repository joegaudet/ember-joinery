import Helper from '@ember/component/helper'
import { service } from '@ember/service'
import type RouterService from '@ember/routing/router-service'

export interface QpSignature {
  Args: { Positional: [name: string] }
  Return: string | undefined
}

export interface WithQpSignature {
  Args: { Positional: [name: string, value: string | number | boolean | null | undefined] }
  Return: string
}

/**
 * The current route's query param `name`, as a string, or `undefined` when the URL doesn't
 * have it. Reactive: it updates when the URL does.
 *
 *   {{#if (eq (qp "view") "grid")}}…{{/if}}
 *
 * It reads the router service, so a template needs no controller or class to see the URL. It
 * is ember-primitives' `qp`.
 */
class QueryParam extends Helper<QpSignature> {
  @service declare router: RouterService

  compute([name]: [string]): string | undefined {
    if (!name) throw new Error('Joinery: (qp) needs the name of a query param')
    const value = this.router.currentRoute?.queryParams?.[name]
    return value === undefined || value === null ? undefined : String(value)
  }
}

export const qp = QueryParam

/** The app's current URL, with the rootURL it is served under, as a full URL. */
function currentLocation(router: RouterService): URL {
  const current = router.currentURL
  if (!current) {
    throw new Error(
      'Joinery: (withQP) has no current URL to add a query param to. It needs the router to ' +
        'have started: in a test, visit() a URL first.',
    )
  }
  const root = (router.rootURL ?? '/').replace(/\/$/, '')
  return new URL(`${root}${current}`, location.origin)
}

/**
 * An `href` for the current URL with the query param `name` set to `value` (or removed, for
 * `null` or `undefined`), for links that change the page's state:
 *
 *   <a href={{withQP "view" "grid"}}>Grid</a>
 *
 * The URL includes the app's `rootURL`. Pair it with `properLinks` (or a router that handles
 * plain links) so following the link is a transition rather than a page load. It is
 * ember-primitives' `withQP`, which can also remove a param.
 */
class WithQueryParam extends Helper<WithQpSignature> {
  @service declare router: RouterService

  compute([name, value]: [string, string | number | boolean | null | undefined]): string {
    if (!name) throw new Error('Joinery: (withQP) needs the name of a query param')
    const url = currentLocation(this.router)
    if (value === null || value === undefined) url.searchParams.delete(name)
    else url.searchParams.set(name, String(value))
    return url.href
  }
}

export const withQP = WithQueryParam

const FALSE_VALUES = new Set(['0', 'false', 'f', 'null', 'off', 'undefined', 'no'])

/**
 * A query param's string as a boolean. `undefined`, `''`, `'0'`, `'false'`, `'f'`, `'off'`,
 * `'no'`, `'null'` and `'undefined'` are false; anything else is true.
 *
 *   {{#if (castToBoolean (qp "debug"))}}…{{/if}}
 *
 * It is ember-primitives' `castToBoolean`, except that the words match in any case (`FALSE`
 * too).
 */
export function castToBoolean(value: string | undefined | null): boolean {
  if (!value) return false
  return !FALSE_VALUES.has(value.toLowerCase())
}
