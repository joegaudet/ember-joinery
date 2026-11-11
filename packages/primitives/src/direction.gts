import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import { As, type TagName } from './as.gts'

/** A text direction: left to right, or right to left. */
export type Direction = 'ltr' | 'rtl'

function isDirection(value: unknown): value is Direction {
  return value === 'ltr' || value === 'rtl'
}

/**
 * The text direction at an element: `explicit` when it is `ltr` or `rtl` (a component's `@dir`),
 * and otherwise whatever the document says there, from the nearest `dir` attribute (including
 * `dir="auto"`, resolved from the text) up to `<html>`. Components call it when they need the
 * direction, for example to decide which way the arrow keys move, so it is always current.
 *
 *   getDirection(this.element)            // 'rtl' inside <DirectionProvider @dir="rtl">
 *   getDirection(this.element, this.args.dir)
 *
 * Without an element, it reads `<html>`.
 */
export function getDirection(element?: Element | null, explicit?: string | null): Direction {
  if (isDirection(explicit)) return explicit
  const target = element ?? document.documentElement
  try {
    return target.matches(':dir(rtl)') ? 'rtl' : 'ltr'
  } catch {
    // A browser without :dir(). The nearest dir attribute, with `auto` left to the layout.
    const value = target.closest('[dir]')?.getAttribute('dir')?.toLowerCase()
    if (isDirection(value)) return value
    return getComputedStyle(target).direction === 'rtl' ? 'rtl' : 'ltr'
  }
}

/** Whether the text direction at an element is right to left. See `getDirection`. */
export function isRTL(element?: Element | null, explicit?: string | null): boolean {
  return getDirection(element, explicit) === 'rtl'
}

/** `@direction` wins over `@dir`, as in shadcn's provider; left to right without either. */
function resolve(direction: Direction | undefined, dir: Direction | undefined): Direction {
  return direction ?? dir ?? 'ltr'
}

/**
 * `display: contents`, set through the CSSOM: a strict Content Security Policy (`style-src`
 * without `'unsafe-inline'`) blocks a `style` attribute, but not this.
 */
const displayContents = modifier((element: HTMLElement) => {
  element.style.setProperty('display', 'contents')
})

export interface DirectionProviderSignature {
  Args: {
    /** The direction of everything inside: `ltr` or `rtl`. Default `ltr`. */
    dir?: Direction
    /** The same as `@dir`, by the name shadcn's `DirectionProvider` uses. It wins over `@dir`. */
    direction?: Direction
    /**
     * The tag to render. Default `div`; use `span` inside phrasing content, such as a `<p>` or
     * a `<button>`, where a `<div>` isn't allowed.
     */
    as?: TagName
  }
  Blocks: {
    /** The content, given the direction. */
    default: [dir: Direction]
  }
  Element: HTMLElement
}

/**
 * Sets the text direction for everything inside it, as Radix's `DirectionProvider` does. It
 * renders a `<div dir>` (or `@as`) with `display: contents`, so it adds no box to the layout,
 * and every Joinery component inside reads the direction from the document (`getDirection`),
 * so their arrow keys, sides and alignment follow it. Set `dir` on `<html>` too for a whole
 * RTL app.
 *
 *   <DirectionProvider @dir="rtl">
 *     <Tabs …/>
 *   </DirectionProvider>
 *
 * Radix's provider renders nothing; this one needs an element to carry `dir`, because Joinery's
 * components read the direction from the DOM rather than from a context. It wraps content, so
 * it isn't a component root for the harnesses (no `data-test-jn`): a part inside it still
 * belongs to the component around it. Tests read the direction where it matters, from the
 * component inside (`getDirection(element)`).
 */
export const DirectionProvider: TOC<DirectionProviderSignature> = <template>
  {{#let (resolve @direction @dir) as |dir|}}
    <As
      @as={{@as}}
      @tag="div"
      dir={{dir}}
      data-slot="direction-provider"
      ...attributes
      {{displayContents}}
    >
      {{yield dir}}
    </As>
  {{/let}}
</template>
