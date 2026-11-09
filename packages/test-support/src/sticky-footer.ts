import { Harness } from './harness.ts'
import { waitForObservers } from './observers.ts'

/**
 * Drives a `<StickyFooter>` from `@ember-joinery/primitives/sticky-footer`: its content and
 * footer, whether the content overflows, and where the footer is. A StickyFooter wraps content,
 * so the parts inside it still belong to the component around it; its own elements are found by
 * their `data-jn-sticky-footer-*` attributes.
 *
 *   const layout = new StickyFooterHarness()
 *   assert.true(layout.isFooterAtBottom)   // little content: the footer is at the bottom
 *   await layout.scrollToEnd()             // a lot of content: the footer is below it
 */
export class StickyFooterHarness extends Harness {
  static override component = 'sticky-footer'

  #slot(name: string): HTMLElement {
    const element = this.element.querySelector<HTMLElement>(
      `:scope > [data-jn-sticky-footer-container] > [data-jn-${name}]`,
    )
    if (!element) throw new Error(`Joinery harness: no ${name} in ${this}`)
    return element
  }

  /** The element the `<:content>` block renders in. */
  get content(): HTMLElement {
    return this.#slot('sticky-footer-content')
  }

  /** The element the `<:footer>` block renders in. */
  get footer(): HTMLElement {
    return this.#slot('sticky-footer-footer')
  }

  /** Whether the content and footer are taller than the wrapper, so it scrolls. */
  get overflows(): boolean {
    const { scrollHeight, clientHeight } = this.element
    return scrollHeight > clientHeight + 1
  }

  /**
   * Whether the footer's bottom is at the bottom of the wrapper's view, to within a pixel: true
   * while the content is short, and once scrolled to the end when it isn't.
   */
  get isFooterAtBottom(): boolean {
    const footer = this.footer.getBoundingClientRect()
    const wrapper = this.element
    const view = wrapper.getBoundingClientRect()
    // The boxes the browser reports are scaled with the page (a test's container is scaled
    // down); the wrapper's own sizes aren't.
    const scale = wrapper.offsetHeight > 0 ? view.height / wrapper.offsetHeight : 1
    const bottom = view.top + (wrapper.clientTop + wrapper.clientHeight) * scale
    return Math.abs(footer.bottom - bottom) <= scale
  }

  /** Whether any of the footer is in the wrapper's view. */
  get isFooterVisible(): boolean {
    const footer = this.footer.getBoundingClientRect()
    const view = this.element.getBoundingClientRect()
    return footer.bottom > view.top && footer.top < view.bottom
  }

  /** Scrolls the wrapper to the end, as a user would, to the footer. */
  async scrollToEnd(): Promise<void> {
    const wrapper = this.element
    wrapper.scrollTo({ top: wrapper.scrollHeight, behavior: 'instant' })
    await waitForObservers()
  }

  /** Scrolls the wrapper back to the top. */
  async scrollToTop(): Promise<void> {
    this.element.scrollTo({ top: 0, behavior: 'instant' })
    await waitForObservers()
  }
}
