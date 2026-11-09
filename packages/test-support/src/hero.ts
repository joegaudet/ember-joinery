import { Harness } from './harness.ts'

/** An element's size on the page, in CSS pixels. */
export interface ElementSize {
  width: number
  height: number
}

function sizeOf(element: Element): ElementSize {
  const { width, height } = element.getBoundingClientRect()
  return { width, height }
}

/**
 * Drives a `<Hero>` from `@ember-joinery/primitives/hero`. A Hero wraps content, so the parts
 * inside it still belong to the component around it.
 *
 *   const hero = new HeroHarness()
 *   assert.deepEqual(hero.size, { width: innerWidth, height: innerHeight })
 */
export class HeroHarness extends Harness {
  static override component = 'hero'

  /** Its size on the page: the viewport's, unless the app's CSS changed it. */
  get size(): ElementSize {
    return sizeOf(this.element)
  }

  /** Whether it is as wide and as tall as the window, to within a pixel. */
  get fillsViewport(): boolean {
    const { width, height } = this.size
    const view = this.element.ownerDocument.documentElement
    const window = this.element.ownerDocument.defaultView
    const viewWidth = window?.innerWidth ?? view.clientWidth
    const viewHeight = window?.innerHeight ?? view.clientHeight
    return Math.abs(width - viewWidth) <= 1 && Math.abs(height - viewHeight) <= 1
  }
}
