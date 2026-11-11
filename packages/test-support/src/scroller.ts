import { focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { waitForObservers } from './observers.ts'

/** Where a scrolling element is scrolled to, in pixels from its top and its left. */
export interface ScrollPosition {
  top: number
  left: number
}

/**
 * Drives a `<Scroller>` from `@ember-joinery/primitives/scroller`: where it is scrolled to,
 * which edges it is at, and scrolling it as a user would. A Scroller wraps content, so the
 * parts inside it still belong to the component around it.
 *
 *   const log = new ScrollerHarness('log')   // <Scroller @name="log">
 *   assert.true(log.isAtBottom)
 *   await log.scrollTo({ top: 0 })
 */
export class ScrollerHarness extends Harness {
  static override component = 'scroller'

  /**
   * Where it is scrolled to. `left` is `scrollLeft`: in right-to-left text it runs from 0 at
   * the right edge down to a negative number at the left.
   */
  get position(): ScrollPosition {
    const { scrollTop, scrollLeft } = this.element
    return { top: scrollTop, left: scrollLeft }
  }

  /** How far it can scroll down and across, in pixels. */
  get range(): ScrollPosition {
    const element = this.element
    return {
      top: element.scrollHeight - element.clientHeight,
      left: element.scrollWidth - element.clientWidth,
    }
  }

  /** Whether it is scrolled to the top, to within a pixel. */
  get isAtTop(): boolean {
    return this.element.scrollTop <= 1
  }

  /** Whether it is scrolled to the bottom, to within a pixel. */
  get isAtBottom(): boolean {
    return this.element.scrollTop >= this.range.top - 1
  }

  /** Whether it is scrolled to its left edge, to within a pixel, whichever the direction. */
  get isAtLeft(): boolean {
    const { scrollLeft } = this.element
    return this.#rtl ? scrollLeft <= -this.range.left + 1 : scrollLeft <= 1
  }

  /** Whether it is scrolled to its right edge, to within a pixel, whichever the direction. */
  get isAtRight(): boolean {
    const { scrollLeft } = this.element
    return this.#rtl ? scrollLeft >= -1 : scrollLeft >= this.range.left - 1
  }

  /** Whether a keyboard can reach it (it is in the tab order), so arrow keys can scroll it. */
  get isFocusable(): boolean {
    return this.element.tabIndex >= 0
  }

  /** Scrolls it to a position at once, as a user dragging its scrollbar would. */
  async scrollTo(position: Partial<ScrollPosition>): Promise<void> {
    this.element.scrollTo({ ...position, behavior: 'instant' })
    await waitForObservers()
  }

  /** Moves focus to it, as tabbing to it would. */
  async focus(): Promise<void> {
    await focus(this.element)
  }

  get #rtl(): boolean {
    return getComputedStyle(this.element).direction === 'rtl'
  }
}
