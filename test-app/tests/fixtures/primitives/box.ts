import { Harness, scrollIntoView, waitForObservers } from '@ember-joinery/test-support'

/**
 * An element the observer tests size, scroll or watch: `data-test-jn="box"`, named with
 * `data-test-jn-name` when there are several.
 *
 *   <div data-test-jn="box" style="width: 100px; height: 50px;" {{onResize this.record}}></div>
 */
export class BoxHarness extends Harness {
  static override component = 'box'

  /** Gives the box a new size, as dragging its corner would, then waits for the observers. */
  async resizeTo(width: number, height?: number): Promise<void> {
    this.element.style.width = `${width}px`
    if (height !== undefined) this.element.style.height = `${height}px`
    await waitForObservers()
  }

  /** Scrolls the box into view, as a user would, then waits for the observers. */
  async scrollIntoView(): Promise<void> {
    await scrollIntoView(this.element)
  }

  /** Scrolls the box's own content to `top` pixels down, then waits for the observers. */
  async scrollTo(top: number): Promise<void> {
    this.element.scrollTop = top
    await waitForObservers()
  }
}
