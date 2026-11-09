import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { waitForObservers } from './observers.ts'

/**
 * Drives a `<Zoetrope>` from `@ember-joinery/primitives/zoetrope`: its items, which of them are
 * in view, and the buttons that scroll it. It is ember-primitives' `ZoetropeHelper`, as a
 * harness.
 *
 *   const releases = new ZoetropeHarness('releases')   // <Zoetrope @name="releases">
 *   assert.strictEqual(releases.visibleItemCount, 2)
 *   await releases.scrollRight()
 *   assert.false(releases.canScrollRight)
 *
 * `scrollLeft()` and `scrollRight()` click the `scroll-left` and `scroll-right` parts: the
 * default buttons, or yours in `<:controls>` when they carry `data-test-jn-part="scroll-left"`
 * and `"scroll-right"`.
 */
export class ZoetropeHarness extends Harness {
  static override component = 'zoetrope'

  /** The header block's element, or `null` without one. */
  get header(): HTMLElement | null {
    return this.queryPart('header')
  }

  /** The default buttons' element, or `null` when they aren't shown. */
  get controls(): HTMLElement | null {
    return this.queryPart('controls')
  }

  /** The track the items are in, which scrolls. */
  get scroller(): HTMLElement {
    return this.part('scroller')
  }

  /** The button that scrolls left, or `null` when there is none (nothing to scroll). */
  get leftButton(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('scroll-left')
  }

  /** The button that scrolls right, or `null` when there is none. */
  get rightButton(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('scroll-right')
  }

  /** Every item, in order. */
  get items(): HTMLElement[] {
    return [...this.scroller.children] as HTMLElement[]
  }

  /**
   * The items at least partly inside the track's box, in order: what a user sees of the row.
   */
  get visibleItems(): HTMLElement[] {
    const track = this.scroller.getBoundingClientRect()
    return this.items.filter(item => {
      const box = item.getBoundingClientRect()
      return box.right > track.left && box.left < track.right
    })
  }

  /** How many items are at least partly in view. */
  get visibleItemCount(): number {
    return this.visibleItems.length
  }

  /** How far the track is scrolled from where its items start, in pixels, in either direction. */
  get scrolled(): number {
    return Math.abs(this.scroller.scrollLeft)
  }

  /** Whether there is a left button and it can be used. */
  get canScrollLeft(): boolean {
    const button = this.leftButton
    return Boolean(button && !button.disabled)
  }

  /** Whether there is a right button and it can be used. */
  get canScrollRight(): boolean {
    const button = this.rightButton
    return Boolean(button && !button.disabled)
  }

  /** Clicks the left button, and waits for the scroll to end. */
  async scrollLeft(): Promise<void> {
    await click(this.part('scroll-left'))
    await waitForObservers()
  }

  /** Clicks the right button, and waits for the scroll to end. */
  async scrollRight(): Promise<void> {
    await click(this.part('scroll-right'))
    await waitForObservers()
  }

  /** Moves focus to an item, by its index, as a click or a script would. */
  async focusItem(index: number): Promise<void> {
    const item = this.items[index]
    if (!item) throw new Error(`Joinery harness: ${this} has no item ${index}`)
    await focus(item)
  }

  /** The index of the item that has focus, or `-1`. */
  get focusedIndex(): number {
    const active = this.element.ownerDocument.activeElement
    return this.items.findIndex(item => item === active)
  }
}
