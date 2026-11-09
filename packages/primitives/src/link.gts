import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { ExternalLink } from './external-link.gts'
import { link } from './link-helper.ts'

/** What `<Link>` yields: whether its `@href` leaves the app, and whether it is the current page. */
export interface LinkStatus {
  /**
   * Whether `@href` is on another origin, so the link leaves the app (it then opens in a new
   * tab). For telling the user, with an icon or a word.
   */
  isExternal: boolean
  /**
   * Whether `@href` is the current route (see `@includeActiveQueryParams` and
   * `@activeOnSubPaths`), for styling the link's content. Never for an external link.
   */
  isActive: boolean
}

export interface LinkComponentSignature {
  Args: {
    /** Where the link goes: a path with the app's `rootURL` (`/settings`), or a URL. */
    href: string
    /**
     * Whether the query params count towards the active state: `true` for all of them (the
     * link is active only when the current URL's query params match its own), or the names of
     * the ones that count. Without it, the path alone decides.
     */
    includeActiveQueryParams?: true | string[]
    /**
     * Whether the link is also active on the routes below its own: `/forum/1` on
     * `/forum/1/posts`. Without it, only on its own route.
     */
    activeOnSubPaths?: true
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The link's content, given whether it leaves the app and whether it is the current page. */
    default: [LinkStatus]
  }
  /** The `<a>`. */
  Element: HTMLAnchorElement
}

/**
 * An `<a>` that knows where the user is, as ember-primitives' `Link`: on the current route it
 * has `aria-current` and `data-active="true"`, a click on it is a transition (so it works in an
 * app without `properLinks`), and an `@href` on another origin makes it an
 * [`ExternalLink`](./external-link.gts), which opens in a new tab.
 *
 *   <nav aria-label="Main">
 *     <Link @href="/">Home</Link>
 *     <Link @href="/forum" @activeOnSubPaths={{true}}>Forum</Link>
 *     <Link @href="https://developer.mozilla.org" as |a|>
 *       MDN {{#if a.isExternal}}<span aria-hidden="true">↗</span>{{/if}}
 *     </Link>
 *   </nav>
 *
 * `aria-current` is `page` on the current route itself, and `true` on a link that is active on
 * the routes below it (`@activeOnSubPaths`), as it isn't the page itself then. It needs the
 * app's router, so it renders inside an app (or a test with `setupRouting`).
 */
export const Link: TOC<LinkComponentSignature> = <template>
  {{#let
    (link
      @href includeActiveQueryParams=@includeActiveQueryParams activeOnSubPaths=@activeOnSubPaths
    )
    as |l|
  }}
    {{#if l.isExternal}}
      <ExternalLink href={{@href}} data-test-jn="link" data-test-jn-name={{@name}} ...attributes>
        {{yield (hash isExternal=true isActive=false)}}
      </ExternalLink>
    {{else}}
      <a
        href={{if @href @href "##missing##"}}
        data-active={{if l.isActive "true"}}
        aria-current={{if l.isActive (if @activeOnSubPaths "true" "page")}}
        data-test-jn="link"
        data-test-jn-name={{@name}}
        {{on "click" l.handleClick}}
        ...attributes
      >
        {{yield (hash isExternal=false isActive=l.isActive)}}
      </a>
    {{/if}}
  {{/let}}
</template>
