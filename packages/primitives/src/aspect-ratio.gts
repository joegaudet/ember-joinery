import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { As, type TagName } from './as.gts'

/**
 * Sets inline styles through the CSSOM, which a strict Content Security Policy (`style-src`
 * without `'unsafe-inline'`) allows where it blocks a `style` attribute. It adds to the
 * element's own styles, and puts back the ones it replaced when it goes.
 */
const setStyles = modifier(
  (element: HTMLElement, positional: [styles: ReadonlyArray<readonly [string, string]>]) => {
    const [styles] = positional
    const { style } = element
    const previous = styles.map(
      ([property]) =>
        [property, style.getPropertyValue(property), style.getPropertyPriority(property)] as const,
    )
    for (const [property, value] of styles) style.setProperty(property, value)
    return () => {
      for (const [property, value, priority] of previous) {
        if (value) style.setProperty(property, value, priority)
        else style.removeProperty(property)
      }
    }
  },
)

/** The ratio as a positive number: `@ratio`, or 1 (a square) without a usable one. */
function ratioOf(ratio: number | undefined): number {
  const value = Number(ratio)
  return Number.isFinite(value) && value > 0 ? value : 1
}

/**
 * The outer box's styles, as Radix's: it is the full width, and its bottom padding, a share of
 * that width, gives it the ratio's height.
 */
function wrapperStyles(ratio: number | undefined): ReadonlyArray<readonly [string, string]> {
  return [
    ['position', 'relative'],
    ['width', '100%'],
    ['padding-bottom', `${100 / ratioOf(ratio)}%`],
  ]
}

/** The inner box fills the outer one, so what's inside takes the ratio. */
const INNER_STYLES: ReadonlyArray<readonly [string, string]> = [
  ['position', 'absolute'],
  ['top', '0'],
  ['right', '0'],
  ['bottom', '0'],
  ['left', '0'],
]

export interface AspectRatioSignature {
  Args: {
    /** Width over height, as a number: `16 / 9` for widescreen, `1` for a square. Default 1. */
    ratio?: number
    /** The inner element's tag. Default `div`. */
    as?: TagName
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** What takes the ratio: an image, a video, a map. Give it `width` and `height` of 100%. */
    default: []
  }
  /** The inner element, which fills the box. */
  Element: HTMLDivElement
}

/**
 * Shows its content at a width-to-height ratio, as Radix's `AspectRatio`: an outer box as wide
 * as its container, held to the ratio by its bottom padding, and an inner box that fills it.
 * Attributes, `class` included, go on the inner box. It has no styles of its own beyond those
 * that hold the ratio, which it sets through the CSSOM.
 *
 *   const widescreen = 16 / 9
 *
 *   <div style="width: 300px">
 *     <AspectRatio @ratio={{widescreen}}>
 *       <img src="/photo.jpg" alt="A landscape" style="width: 100%; height: 100%; object-fit: cover" />
 *     </AspectRatio>
 *   </div>
 */
export const AspectRatio: TOC<AspectRatioSignature> = <template>
  <div data-jn-aspect-ratio-wrapper {{setStyles (wrapperStyles @ratio)}}>
    <As
      @as={{@as}}
      @tag="div"
      data-test-jn="aspect-ratio"
      data-test-jn-name={{@name}}
      ...attributes
      {{setStyles INNER_STYLES}}
    >{{yield}}</As>
  </div>
</template>
