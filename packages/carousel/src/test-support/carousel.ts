import { click, focus, settled, waitUntil } from '@ember/test-helpers'
import { Harness, pressKey } from '@ember-joinery/test-support'

const collapse = (value: string | null | undefined): string =>
  (value ?? '').replace(/\s+/g, ' ').trim()

/** What can take focus inside a carousel when none of its buttons can. */
const FOCUSABLE =
  'button:not(:disabled), [href], input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex]:not([tabindex="-1"])'

/**
 * Drives a `<Carousel>` from `@ember-joinery/carousel`. It reads the slides, which of them are
 * in view (from where they are drawn, as a user sees them), the orientation and each slide's
 * name, and moves the carousel the ways a user does: with its buttons, the arrow keys, or a
 * swipe.
 *
 *   const carousel = new CarouselHarness('gallery') // <Carousel @name="gallery">
 *   assert.deepEqual(carousel.slidesInView, [0])
 *   await carousel.scrollNext()
 *   assert.deepEqual(carousel.slidesInView, [1])
 *   assert.false(carousel.canScrollNext)
 *
 * Every action waits for the carousel to come to rest, so a test reads the slides where they
 * stop.
 */
export class CarouselHarness extends Harness {
  static override component = 'carousel'

  /** `horizontal` or `vertical`. */
  get orientation(): 'horizontal' | 'vertical' {
    return this.element.getAttribute('data-orientation') === 'vertical' ? 'vertical' : 'horizontal'
  }

  /** The text direction the slides run in: `ltr` or `rtl`. */
  get direction(): 'ltr' | 'rtl' {
    return getComputedStyle(this.content).direction === 'rtl' ? 'rtl' : 'ltr'
  }

  /** How assistive technology describes it (`aria-roledescription`): `carousel`. */
  get roleDescription(): string | null {
    return this.element.getAttribute('aria-roledescription')
  }

  /** Its accessible name: `aria-label`, or the text of what `aria-labelledby` names; `''` without. */
  get label(): string {
    const element = this.element
    const label = element.getAttribute('aria-label')
    if (label) return label.trim()
    return (element.getAttribute('aria-labelledby') ?? '')
      .split(/\s+/)
      .map(id => (id ? element.ownerDocument.getElementById(id) : null))
      .filter((found): found is HTMLElement => Boolean(found))
      .map(found => collapse(found.textContent))
      .join(' ')
  }

  /** The content: Embla's viewport, which clips the slides. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The row (or column) of slides inside the content, which Embla moves. */
  get container(): HTMLElement {
    return this.part('container')
  }

  /** The slides, in order. */
  get slides(): HTMLElement[] {
    return this.parts('item')
  }

  /** How many slides it has. */
  get slideCount(): number {
    return this.slides.length
  }

  /** Each slide's accessible name (`1 of 5` by default), in order. */
  get slideLabels(): string[] {
    return this.slides.map(slide => slide.getAttribute('aria-label') ?? '')
  }

  /** Each slide's text, whitespace collapsed, in order. */
  get slideTexts(): string[] {
    return this.slides.map(slide => collapse(slide.textContent))
  }

  /**
   * The slides in view, by index: those with at least half of their box inside the content,
   * where they are drawn now.
   */
  get slidesInView(): number[] {
    const view = this.content.getBoundingClientRect()
    const vertical = this.orientation === 'vertical'
    const [viewStart, viewEnd] = vertical ? [view.top, view.bottom] : [view.left, view.right]
    return this.slides.flatMap((slide, index) => {
      const box = slide.getBoundingClientRect()
      const [start, end, size] = vertical
        ? [box.top, box.bottom, box.height]
        : [box.left, box.right, box.width]
      const shown = Math.min(end, viewEnd) - Math.max(start, viewStart)
      return size > 0 && shown >= size / 2 ? [index] : []
    })
  }

  /** The first slide in view, by index, or `-1` when none is. */
  get currentSlide(): number {
    return this.slidesInView[0] ?? -1
  }

  /** The previous slide's button, or `null` without one. */
  get previous(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('previous')
  }

  /** The next slide's button, or `null` without one. */
  get next(): HTMLButtonElement | null {
    return this.queryPart<HTMLButtonElement>('next')
  }

  /** Whether the previous button can be used (it is disabled at the first slide). */
  get canScrollPrev(): boolean {
    return isEnabled(this.previous)
  }

  /** Whether the next button can be used (it is disabled at the last slide). */
  get canScrollNext(): boolean {
    return isEnabled(this.next)
  }

  /** Clicks the previous button, and waits for the carousel to come to rest. */
  async scrollPrev(): Promise<void> {
    await click(this.#button('previous'))
  }

  /** Clicks the next button, and waits for the carousel to come to rest. */
  async scrollNext(): Promise<void> {
    await click(this.#button('next'))
  }

  /**
   * Presses a key inside the carousel, as a keyboard user does once they have tabbed into it:
   * when focus is outside, it first moves to a button (or anything else) inside that can take
   * it. Returns whether the carousel called `preventDefault()`.
   */
  async press(key: string): Promise<boolean> {
    const root = this.element
    if (!root.contains(root.ownerDocument.activeElement)) {
      const target =
        [this.next, this.previous].find(isEnabled) ?? root.querySelector<HTMLElement>(FOCUSABLE)
      if (target) await focus(target)
    }
    return pressKey(key)
  }

  /**
   * Drags the slides with a mouse, `distance` pixels along the carousel's axis (negative is
   * left, or up), and lets go, then waits for the carousel to come to rest.
   */
  async drag(distance: number): Promise<void> {
    const content = this.content
    const target = this.slides[this.currentSlide] ?? content
    const box = content.getBoundingClientRect()
    const x = box.left + box.width / 2
    const y = box.top + box.height / 2
    const vertical = this.orientation === 'vertical'
    const at = (moved: number) =>
      vertical ? { clientX: x, clientY: y + moved } : { clientX: x + moved, clientY: y }
    const document = content.ownerDocument
    const mouse = (node: EventTarget, type: string, moved: number, buttons: number) =>
      node.dispatchEvent(
        new MouseEvent(type, {
          bubbles: true,
          cancelable: true,
          view: document.defaultView,
          button: 0,
          buttons,
          ...at(moved),
        }),
      )
    // One gesture, sent at once: settled() would wait for the drag to end between events.
    mouse(target, 'mousedown', 0, 1)
    for (const share of [0.25, 0.5, 0.75, 1]) mouse(document, 'mousemove', distance * share, 1)
    mouse(document, 'mouseup', distance, 0)
    await settled()
  }

  /**
   * Swipes to the next or previous slide: drags the slides most of the content's length, the
   * way that brings that slide in (to the left for the next, or up; to the right right to
   * left), and waits for them to come to rest.
   */
  async swipe(to: 'next' | 'previous'): Promise<void> {
    const content = this.content
    const vertical = this.orientation === 'vertical'
    // Embla moves the slides by the pointer's pixels, so the length is the layout's own.
    const length = (vertical ? content.offsetHeight : content.offsetWidth) * 0.6
    const forward = vertical || this.direction === 'ltr' ? -1 : 1
    await this.drag(length * (to === 'next' ? forward : -forward))
  }

  /**
   * Waits until the slide at `index` is in view, as when a plugin (autoplay) moves the
   * carousel on its own. Fails after `timeout` milliseconds (default 5000).
   */
  async waitForSlide(index: number, { timeout = 5000 }: { timeout?: number } = {}): Promise<void> {
    await waitUntil(() => this.slidesInView.includes(index), {
      timeout,
      timeoutMessage: `slide ${index} of ${this} didn't come into view`,
    })
    await settled()
  }

  #button(step: 'previous' | 'next'): HTMLButtonElement {
    return this.part<HTMLButtonElement>(step)
  }
}

function isEnabled(button: HTMLButtonElement | null | undefined): button is HTMLButtonElement {
  return Boolean(button) && !button!.disabled && button!.getAttribute('aria-disabled') !== 'true'
}
