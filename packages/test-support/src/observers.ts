import { find, settled } from '@ember/test-helpers'

const frame = () => new Promise<void>(resolve => requestAnimationFrame(() => resolve()))

/**
 * Waits until `IntersectionObserver` and `ResizeObserver` have reported what changed: two
 * frames, then `settled()`. `settled()` alone waits for an element's first report (Joinery's
 * `viewport` and `onResize` register it), but not for the reports a scroll or a resize causes
 * later, which the browser delivers in the next frame.
 *
 *   box.style.width = '300px'
 *   await waitForObservers()
 *   assert.dom('output').hasText('300 × 120')
 */
export async function waitForObservers(): Promise<void> {
  await settled()
  await frame()
  await frame()
  await settled()
}

/**
 * Scrolls `target` (an element, or a selector in the test's root) to the middle of its
 * scrolling boxes and the window, as a user scrolling to it would, then waits for the observers
 * to report it: what an `InViewport` holds renders.
 *
 *   await scrollIntoView('[data-test-comments]')
 *   assert.dom('[data-test-comment]').exists({ count: 3 })
 */
export async function scrollIntoView(target: Element | string): Promise<void> {
  const element = typeof target === 'string' ? find(target) : target
  if (!element) throw new Error(`Joinery: scrollIntoView found nothing for ${String(target)}`)
  element.scrollIntoView({ block: 'center', inline: 'center' })
  await waitForObservers()
}
