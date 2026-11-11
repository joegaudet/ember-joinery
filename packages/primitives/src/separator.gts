import type { TOC } from '@ember/component/template-only'
import { get } from '@ember/helper'
import { As, type TagName } from './as.gts'

/** Which way a separator runs. */
export type SeparatorOrientation = 'horizontal' | 'vertical'

/** What a separator's ARIA depends on. */
export interface SeparatorAriaOptions {
  /** Default `horizontal`. */
  orientation?: SeparatorOrientation
  /** Whether it only decorates, and assistive technology skips it. Default `false`. */
  decorative?: boolean
  /**
   * The element's tag, when it is known: an `<hr>` is a separator already, so it needs no
   * `role`. Default `div`.
   */
  tag?: string
}

/** The ARIA and data attributes a separator renders. An attribute left `undefined` is left off. */
export interface SeparatorAria {
  role: 'separator' | 'none' | undefined
  'aria-orientation': 'vertical' | undefined
  'aria-hidden': 'true' | undefined
  'data-orientation': SeparatorOrientation
  [attribute: string]: string | undefined
}

function isHr(tag: string | undefined): boolean {
  return (tag ?? '').trim().toLowerCase() === 'hr'
}

/**
 * What a separator tells assistive technology, as Radix's and ember-primitives' `Separator` do:
 *
 * - a semantic separator has the `separator` role (an `<hr>` has it already), and
 *   `aria-orientation="vertical"` when it is vertical (horizontal is the role's default);
 * - a decorative one has `role="none"` (Radix's) and `aria-hidden="true"`
 *   (ember-primitives'), so neither it nor anything inside it is read;
 * - both carry `data-orientation`, for CSS.
 */
export function separatorAria({
  orientation = 'horizontal',
  decorative = false,
  tag = 'div',
}: SeparatorAriaOptions = {}): SeparatorAria {
  const vertical = orientation === 'vertical'
  const direction: SeparatorOrientation = vertical ? 'vertical' : 'horizontal'
  if (decorative) {
    return {
      role: 'none',
      'aria-orientation': undefined,
      'aria-hidden': 'true',
      'data-orientation': direction,
    }
  }
  return {
    role: isHr(tag) ? undefined : 'separator',
    'aria-orientation': vertical ? 'vertical' : undefined,
    'aria-hidden': undefined,
    'data-orientation': direction,
  }
}

function tagOf(as: string | undefined): string {
  return as || 'hr'
}

function ariaOf(
  as: string | undefined,
  orientation: SeparatorOrientation | undefined,
  decorative: boolean | undefined,
): SeparatorAria {
  return separatorAria({ orientation, decorative, tag: tagOf(as) })
}

/** `<hr>` is a void element, and a semantic separator's content isn't read: only a decorative one yields. */
function yields(as: string | undefined, decorative: boolean | undefined): boolean {
  return Boolean(decorative) && !isHr(tagOf(as))
}

export interface SeparatorSignature {
  Args: {
    /**
     * The tag to render. Default `hr`, which is a separator already. Use another where an
     * `<hr>` can't go, such as `li` between a list's items or `span` inside a line of text.
     */
    as?: TagName
    /**
     * Whether it only decorates (a breadcrumb's slash, a line between items that need no
     * announcing): assistive technology skips it and anything inside it. Default `false`.
     */
    decorative?: boolean
    /** Which way it runs: `horizontal` (the default) or `vertical`. */
    orientation?: SeparatorOrientation
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What a decorative separator shows, such as `/`. A semantic one shows nothing. */
    default: []
  }
  Element: HTMLElement
}

/**
 * Separates content, as ember-primitives' and Radix's `Separator`: an `<hr>` by default, or any
 * tag with `@as`, with the ARIA that `separatorAria()` describes. It has no styles.
 *
 *   <Separator />
 *   <Separator @as="div" @orientation="vertical" />
 *   <ol>
 *     <li><a href="/">Home</a></li>
 *     <Separator @as="li" @decorative={{true}}>/</Separator>
 *     <li>Docs</li>
 *   </ol>
 */
export const Separator: TOC<SeparatorSignature> = <template>
  {{#let (ariaOf @as @orientation @decorative) as |aria|}}
    <As
      @as={{@as}}
      @tag="hr"
      role={{get aria "role"}}
      aria-orientation={{get aria "aria-orientation"}}
      aria-hidden={{get aria "aria-hidden"}}
      data-orientation={{get aria "data-orientation"}}
      data-test-jn="separator"
      data-test-jn-name={{@name}}
      ...attributes
    >{{#if (yields @as @decorative)}}{{yield}}{{/if}}</As>
  {{/let}}
</template>
