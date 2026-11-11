import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { As, type TagName } from './as.gts'

/**
 * Bootstrap's visually-hidden rules, which Radix and ember-primitives use too: the element
 * takes no space and shows nothing, and screen readers still read it.
 */
const STYLES: ReadonlyArray<readonly [property: string, value: string]> = [
  ['position', 'absolute'],
  ['border', '0'],
  ['width', '1px'],
  ['height', '1px'],
  ['padding', '0'],
  ['margin', '-1px'],
  ['overflow', 'hidden'],
  ['clip', 'rect(0, 0, 0, 0)'],
  ['white-space', 'nowrap'],
  ['word-wrap', 'normal'],
]

/**
 * Hides any element visually and keeps it for assistive technology, like ember-primitives'
 * `visually-hidden` attribute, without needing a style sheet. The element's other inline
 * styles stay, and the ones it replaced come back when the modifier goes.
 *
 *   <label for="search" {{visuallyHidden}}>Search</label>
 */
export const visuallyHidden = modifier((element: HTMLElement | SVGElement) => {
  const { style } = element
  const previous = STYLES.map(
    ([property]) =>
      [property, style.getPropertyValue(property), style.getPropertyPriority(property)] as const,
  )
  for (const [property, value] of STYLES) style.setProperty(property, value)
  return () => {
    for (const [property, value, priority] of previous) {
      if (value) style.setProperty(property, value, priority)
      else style.removeProperty(property)
    }
  }
})

export interface VisuallyHiddenSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
  }
  Blocks: {
    /** What screen readers read and sighted users don't see. */
    default: []
  }
  Element: HTMLSpanElement
}

/**
 * Content that screen readers read and sighted users don't see, such as an icon button's
 * label. It renders a `span` (or `@as`) with the visually-hidden styles inline, so it needs
 * no CSS.
 *
 *   <button type="button">
 *     <XIcon />
 *     <VisuallyHidden>Close</VisuallyHidden>
 *   </button>
 *
 * It wraps content, so it isn't a component root for the harnesses: a part inside it still
 * belongs to the component around it.
 */
export const VisuallyHidden: TOC<VisuallyHiddenSignature> = <template>
  <As @as={{@as}} @tag="span" data-slot="visually-hidden" ...attributes {{visuallyHidden}}>
    {{yield}}
  </As>
</template>
