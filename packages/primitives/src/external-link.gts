import type { TOC } from '@ember/component/template-only'

export interface ExternalLinkSignature {
  Args: {
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The link's content. */
    default: []
  }
  /** The `<a>`: give it `href`, the native attribute. */
  Element: HTMLAnchorElement
}

/**
 * A link that always leaves the app, as ember-primitives' `ExternalLink`: an `<a>` that opens a
 * new tab (`target="_blank"`) and tells the page it opens nothing about this one
 * (`rel="noreferrer noopener"`). It takes the native `href`; until it has one, its `href` is
 * `##missing##`, so a link that lost its address shows it.
 *
 *   <ExternalLink href="https://developer.mozilla.org">MDN</ExternalLink>
 *
 * A new tab surprises some users: say so in the link's text or with an icon that has a label.
 * [`Link`](./link.gts) renders one for an `@href` on another origin.
 */
export const ExternalLink: TOC<ExternalLinkSignature> = <template>
  <a
    target="_blank"
    rel="noreferrer noopener"
    href="##missing##"
    data-test-jn="external-link"
    data-test-jn-name={{@name}}
    ...attributes
  >{{yield}}</a>
</template>
