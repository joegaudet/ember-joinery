import { settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { sendPointer } from './send-pointer.ts'

/** Which scrollbar: `vertical` (the default) or `horizontal`. */
export type ScrollbarOrientation = 'vertical' | 'horizontal'

/**
 * Screen pixels per CSS pixel at an element: other than 1 under a transform, such as the test
 * container's scale.
 */
function scaleOf(element: HTMLElement): number {
  const width = element.offsetWidth
  return width ? element.getBoundingClientRect().width / width : 1
}

/** One animation frame, and the app settled after it: when a scroll's `scroll` event has come. */
async function frame(): Promise<void> {
  await new Promise<void>(resolve => requestAnimationFrame(() => resolve()))
  await settled()
}

/**
 * Drives a scroll area: `<ScrollArea>` from `@ember-joinery/primitives/scroll-area`, or from
 * `@ember-joinery/ember`. Its viewport scrolls natively; its scrollbars are parts that show for
 * its `@type` (by default while the pointer is over it, so `hover()` first).
 *
 *   const tags = new ScrollAreaHarness('tags')
 *   await tags.hover()
 *   assert.true(tags.isScrollbarVisible())
 *   await tags.scrollTo({ top: 200 })
 *   await tags.dragThumb('vertical', 40)
 */
export class ScrollAreaHarness extends Harness {
  static override component = 'scroll-area'

  /** The element that scrolls. */
  get viewport(): HTMLElement {
    return this.part('viewport')
  }

  /** A scrollbar's element, or `null` while it isn't shown. */
  scrollbar(orientation: ScrollbarOrientation = 'vertical'): HTMLElement | null {
    return this.queryPart('scrollbar', orientation)
  }

  /** A scrollbar's thumb, or `null` while it isn't shown. */
  thumb(orientation: ScrollbarOrientation = 'vertical'): HTMLElement | null {
    return this.queryPart('thumb', orientation)
  }

  /** The corner between the scrollbars, or `null`. */
  get corner(): HTMLElement | null {
    return this.queryPart('corner')
  }

  /** Whether a scrollbar is shown now (rendered, with `data-state="visible"`). */
  isScrollbarVisible(orientation: ScrollbarOrientation = 'vertical'): boolean {
    return this.scrollbar(orientation)?.getAttribute('data-state') === 'visible'
  }

  /** How far the viewport is scrolled down, in pixels. */
  get scrollTop(): number {
    return this.viewport.scrollTop
  }

  /** How far it is scrolled across, in pixels: negative right to left, as browsers give it. */
  get scrollLeft(): number {
    return this.viewport.scrollLeft
  }

  /** How far down it can scroll. */
  get maxScrollTop(): number {
    return this.viewport.scrollHeight - this.viewport.clientHeight
  }

  /** How far across it can scroll. */
  get maxScrollLeft(): number {
    return this.viewport.scrollWidth - this.viewport.clientWidth
  }

  /**
   * How far the thumb is along its track, in CSS pixels, from the track's start: the top, or
   * the left (also right to left, where scrolling starts at the right).
   */
  thumbOffset(orientation: ScrollbarOrientation = 'vertical'): number {
    const thumb = this.thumb(orientation)
    const bar = this.scrollbar(orientation)
    if (!thumb || !bar) return 0
    const t = thumb.getBoundingClientRect()
    const b = bar.getBoundingClientRect()
    const padding = getComputedStyle(bar)
    const scale = scaleOf(bar)
    return orientation === 'vertical'
      ? (t.top - b.top) / scale - parseFloat(padding.paddingTop)
      : (t.left - b.left) / scale - parseFloat(padding.paddingLeft)
  }

  /** The thumb's length along its track, in CSS pixels. */
  thumbLength(orientation: ScrollbarOrientation = 'vertical'): number {
    const thumb = this.thumb(orientation)
    if (!thumb) return 0
    return orientation === 'vertical' ? thumb.offsetHeight : thumb.offsetWidth
  }

  /** Puts the pointer over the area, as a user about to scroll does. */
  async hover(): Promise<void> {
    await sendPointer(this.element, 'pointerenter')
  }

  /** Takes the pointer away; a `hover` scrollbar goes once the hide delay is up. */
  async unhover(): Promise<void> {
    await sendPointer(this.element, 'pointerleave')
  }

  /** Scrolls the viewport, as the wheel or the keyboard would, and waits for its `scroll` event. */
  async scrollTo({ top, left }: { top?: number; left?: number }): Promise<void> {
    const viewport = this.viewport
    if (top !== undefined) viewport.scrollTop = top
    if (left !== undefined) viewport.scrollLeft = left
    await frame()
  }

  /** Drags a scrollbar's thumb `distance` CSS pixels along its track (down or right). */
  async dragThumb(orientation: ScrollbarOrientation, distance: number): Promise<void> {
    const thumb = this.thumb(orientation)
    if (!thumb) throw new Error(`no ${orientation} thumb shown in ${this}`)
    const box = thumb.getBoundingClientRect()
    const x = box.left + box.width / 2
    const y = box.top + box.height / 2
    const scale = scaleOf(thumb)
    const at = (d: number) =>
      orientation === 'vertical'
        ? { clientX: x, clientY: y + d * scale }
        : { clientX: x + d * scale, clientY: y }
    await sendPointer(thumb, 'pointerdown', at(0))
    await sendPointer(thumb, 'pointermove', at(distance / 2))
    await sendPointer(thumb, 'pointermove', at(distance))
    await sendPointer(thumb, 'pointerup', { ...at(distance), buttons: 0 })
    await frame()
  }

  /** Presses a scrollbar's track at `fraction` of its length (0 the start, 1 the end). */
  async pressTrack(orientation: ScrollbarOrientation, fraction: number): Promise<void> {
    const bar = this.scrollbar(orientation)
    if (!bar) throw new Error(`no ${orientation} scrollbar shown in ${this}`)
    const box = bar.getBoundingClientRect()
    const at =
      orientation === 'vertical'
        ? { clientX: box.left + box.width / 2, clientY: box.top + box.height * fraction }
        : { clientX: box.left + box.width * fraction, clientY: box.top + box.height / 2 }
    await sendPointer(bar, 'pointerdown', at)
    await sendPointer(bar, 'pointerup', { ...at, buttons: 0 })
    await frame()
  }

  /** Turns the wheel over a scrollbar by `delta` pixels, which scrolls the viewport. */
  async wheel(orientation: ScrollbarOrientation, delta: number): Promise<boolean> {
    const bar = this.scrollbar(orientation)
    if (!bar) throw new Error(`no ${orientation} scrollbar shown in ${this}`)
    const event = new WheelEvent('wheel', {
      bubbles: true,
      cancelable: true,
      deltaX: orientation === 'horizontal' ? delta : 0,
      deltaY: orientation === 'vertical' ? delta : 0,
    })
    bar.dispatchEvent(event)
    await frame()
    return event.defaultPrevented
  }
}
