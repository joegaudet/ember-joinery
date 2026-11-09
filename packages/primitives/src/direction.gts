import type { TOC } from '@ember/component/template-only'

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

export interface DirectionProviderSignature {
  Args: {
    /** The direction of everything inside: `ltr` or `rtl`. Default `ltr`. */
    dir?: Direction
    /** The same as `@dir`, by the name shadcn's `DirectionProvider` uses. It wins over `@dir`. */
    direction?: Direction
  }
  Blocks: {
    /** The content, given the direction. */
    default: [dir: Direction]
  }
  Element: HTMLDivElement
}

/**
 * Sets the text direction for everything inside it, as Radix's `DirectionProvider` does. It
 * renders a `<div dir>` with `display: contents`, so it adds no box to the layout, and every
 * Joinery component inside reads the direction from the document (`getDirection`), so their
 * arrow keys, sides and alignment follow it. Set `dir` on `<html>` too for a whole RTL app.
 *
 *   <DirectionProvider @dir="rtl">
 *     <Tabs …/>
 *   </DirectionProvider>
 */
export const DirectionProvider: TOC<DirectionProviderSignature> = <template>
  {{#let (resolve @direction @dir) as |dir|}}
    <div dir={{dir}} data-slot="direction-provider" style="display: contents" ...attributes>
      {{yield dir}}
    </div>
  {{/let}}
</template>
