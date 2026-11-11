import type { TOC } from '@ember/component/template-only'
import { get, hash } from '@ember/helper'
import { As, type TagName } from './as.gts'
import { t } from './i18n.ts'
import { messages } from './messages.ts'

/** The ARIA a breadcrumb's separator renders. */
export interface BreadcrumbSeparatorAria {
  role: 'presentation'
  'aria-hidden': 'true'
  [attribute: string]: string
}

/**
 * What a breadcrumb's separator tells assistive technology: nothing. It is a list item that only
 * decorates (`role="presentation"`, as shadcn's, and `aria-hidden="true"`, as ember-primitives'
 * and shadcn's), so a screen reader skips it and the slash or chevron inside it.
 */
export function breadcrumbSeparatorAria(): BreadcrumbSeparatorAria {
  return { role: 'presentation', 'aria-hidden': 'true' }
}

const ARIA = breadcrumbSeparatorAria()

export interface BreadcrumbSeparatorSignature {
  Args: {
    /** The tag to render. Default `li`, a sibling of the crumbs' items. */
    as?: TagName
  }
  Blocks: {
    /** What it shows, such as `/`. */
    default: []
  }
  Element: HTMLElement
}

/**
 * A separator between a breadcrumb's crumbs, as ember-primitives' yields: an `li` that
 * assistive technology skips (`breadcrumbSeparatorAria()`), showing its block.
 */
export const BreadcrumbSeparator: TOC<BreadcrumbSeparatorSignature> = <template>
  <As
    @as={{@as}}
    @tag="li"
    role={{get ARIA "role"}}
    aria-hidden={{get ARIA "aria-hidden"}}
    data-test-jn-part="separator"
    ...attributes
  >{{yield}}</As>
</template>

/** What `<Breadcrumb>` yields. */
export interface BreadcrumbYield {
  /** A separator between two crumbs. */
  Separator: typeof BreadcrumbSeparator
}

export interface BreadcrumbSignature {
  Args: {
    /** What the navigation is called (`aria-label`). Default `Breadcrumb`, as ember-primitives'. */
    label?: string
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The crumbs, each an `li`, with a `Separator` between them. */
    default: [BreadcrumbYield]
  }
  Element: HTMLElement
}

/**
 * The path to the current page, as ember-primitives' `Breadcrumb`: a `nav` named for assistive
 * technology, around an ordered list of crumbs. Mark the current page's crumb with
 * `aria-current="page"`. It has no styles; the styled Breadcrumb has the same anatomy.
 *
 *   <Breadcrumb as |b|>
 *     <li><a href="/">Home</a></li>
 *     <b.Separator>/</b.Separator>
 *     <li><a href="/docs">Docs</a></li>
 *     <b.Separator>/</b.Separator>
 *     <li aria-current="page">Breadcrumb</li>
 *   </Breadcrumb>
 */
export const Breadcrumb: TOC<BreadcrumbSignature> = <template>
  <nav
    aria-label={{if @label @label (t messages.breadcrumbLabel)}}
    data-test-jn="breadcrumb"
    data-test-jn-name={{@name}}
    ...attributes
  >
    <ol>{{yield (hash Separator=BreadcrumbSeparator)}}</ol>
  </nav>
</template>

export default Breadcrumb
