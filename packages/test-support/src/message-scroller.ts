import { click, focus, triggerEvent } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { waitForObservers } from './observers.ts'

/** The edges a message scroller can still scroll toward. */
export interface MessageScrollerEdges {
  start: boolean
  end: boolean
}

/** How far each scroll key moves a viewport, as Chrome scrolls one. */
function keyScroll(viewport: HTMLElement, key: string): number {
  const page = viewport.clientHeight * 0.875
  switch (key) {
    case 'Home':
      return -viewport.scrollTop
    case 'End':
      return viewport.scrollHeight
    case 'PageUp':
      return -page
    case 'PageDown':
    case ' ':
      return page
    case 'ArrowUp':
      return -40
    case 'ArrowDown':
      return 40
    default:
      return 0
  }
}

/**
 * Drives a `<MessageScroller>` (or the headless `MessageScrollerRoot`) from Joinery: where the
 * transcript is scrolled to, which rows are in view, its scroll buttons, and scrolling it as a
 * reader does, by wheel or by key, which a programmatic scroll doesn't:
 *
 *   const chat = new MessageScrollerHarness('chat') // <s.Root @name="chat">
 *   assert.true(chat.isAtEnd)
 *   await chat.scrollBy(-200)          // the reader scrolls up
 *   assert.true(chat.canScrollToEnd)
 *   await chat.clickButton()           // "jump to latest"
 *   assert.strictEqual(chat.itemTop('turn-3'), 64)
 *
 * Its actions wait for the scroller to settle: its frames, a smooth scroll's end, and the
 * observers' reports.
 */
export class MessageScrollerHarness extends Harness {
  static override component = 'message-scroller'

  /** The viewport, the part that scrolls. */
  get viewport(): HTMLElement {
    return this.part('viewport')
  }

  /** The content, around the rows. */
  get content(): HTMLElement {
    return this.part('content')
  }

  /** The viewport's accessible name: `Messages` unless it was given another. */
  get label(): string {
    return this.viewport.getAttribute('aria-label') ?? ''
  }

  /** Every row, in order. */
  get items(): HTMLElement[] {
    return this.parts('item')
  }

  /** The `@messageId` of each row that has one, in order. */
  get messageIds(): string[] {
    return this.values('item')
  }

  /** The row with this `@messageId`. Throws when there is none. */
  item(messageId: string): HTMLElement {
    return this.part('item', messageId)
  }

  /** The `@messageId` of each row marked `@scrollAnchor`, in order. */
  get anchorIds(): string[] {
    return this.items
      .filter(item => item.getAttribute('data-scroll-anchor') === 'true')
      .map(item => item.getAttribute('data-message-id'))
      .filter((id): id is string => id !== null)
  }

  /** How much the screen scales the viewport: on-screen lengths are this times CSS ones. */
  get #scale(): number {
    const viewport = this.viewport
    return viewport.offsetHeight
      ? viewport.getBoundingClientRect().height / viewport.offsetHeight
      : 1
  }

  /** How far the viewport is scrolled down, in pixels. */
  get scrollTop(): number {
    return this.viewport.scrollTop
  }

  /** How far it can scroll down, in pixels. */
  get maxScrollTop(): number {
    const viewport = this.viewport
    return Math.max(0, viewport.scrollHeight - viewport.clientHeight)
  }

  /** Whether it is scrolled to the top, to within a pixel. */
  get isAtStart(): boolean {
    return this.scrollTop <= 1
  }

  /** Whether it is scrolled to the bottom, to within a pixel. */
  get isAtEnd(): boolean {
    return this.scrollTop >= this.maxScrollTop - 1
  }

  /**
   * The edges it says it can scroll toward: its `data-scrollable`. `end` stays false while it
   * follows the end, as its button does.
   */
  get scrollable(): MessageScrollerEdges {
    const value = (this.element.getAttribute('data-scrollable') ?? '').split(/\s+/)
    return { start: value.includes('start'), end: value.includes('end') }
  }

  /** Whether it says there is more above. */
  get canScrollToStart(): boolean {
    return this.scrollable.start
  }

  /** Whether it says there is more below. */
  get canScrollToEnd(): boolean {
    return this.scrollable.end
  }

  /** Whether the opening position is still to apply, and the viewport hidden till then. */
  get isPendingScroll(): boolean {
    return this.viewport.hasAttribute('data-pending-scroll')
  }

  /** Whether it is scrolling itself to the latest row (`data-autoscrolling`). */
  get isAutoscrolling(): boolean {
    return this.element.hasAttribute('data-autoscrolling')
  }

  /**
   * Where a row starts below the viewport's top edge, in CSS pixels: 0 at the top, negative
   * above it.
   */
  itemTop(messageId: string): number {
    const delta =
      this.item(messageId).getBoundingClientRect().top - this.viewport.getBoundingClientRect().top
    return delta / this.#scale
  }

  /** Whether any of the row shows in the viewport. */
  isItemVisible(messageId: string): boolean {
    const item = this.item(messageId).getBoundingClientRect()
    const viewport = this.viewport.getBoundingClientRect()
    return item.bottom > viewport.top + 1 && item.top < viewport.bottom - 1
  }

  /** The `@messageId` of each row that shows in the viewport, in order. */
  get visibleIds(): string[] {
    return this.messageIds.filter(id => this.isItemVisible(id))
  }

  /** Its scroll button for that edge (`end` by default). Throws when there is none. */
  button(direction: 'start' | 'end' = 'end'): HTMLElement {
    return this.part('button', direction)
  }

  /**
   * Whether the button for that edge can be used: there is somewhere to go, so it is shown,
   * and neither `inert` nor out of the tab order.
   */
  isButtonActive(direction: 'start' | 'end' = 'end'): boolean {
    return this.button(direction).getAttribute('data-active') === 'true'
  }

  /** Presses the button for that edge, as a reader would, and waits for the scroll to end. */
  async clickButton(direction: 'start' | 'end' = 'end'): Promise<void> {
    await click(this.button(direction))
    await this.settle()
  }

  /**
   * Scrolls the viewport to `top`, as a reader's wheel or scrollbar does: that lets go of
   * following and of an anchored turn.
   */
  async scrollTo(top: number): Promise<void> {
    const viewport = this.viewport
    await triggerEvent(viewport, 'wheel', { deltaY: top - viewport.scrollTop })
    viewport.scrollTo({ top, behavior: 'instant' })
    await this.settle()
  }

  /** Scrolls the viewport by `delta` pixels (negative: up), as a reader's wheel does. */
  async scrollBy(delta: number): Promise<void> {
    await this.scrollTo(this.viewport.scrollTop + delta)
  }

  /**
   * Presses a key in the viewport: a scroll key (`ArrowUp`, `ArrowDown`, `PageUp`,
   * `PageDown`, `Home`, `End`, space) scrolls it as the browser would, and is the reader
   * scrolling. A test can't send the browser's own scroll keys, so this moves it the same way.
   */
  async pressKey(key: string): Promise<void> {
    const viewport = this.viewport
    await triggerEvent(viewport, 'keydown', { key })
    const delta = keyScroll(viewport, key)
    if (delta) viewport.scrollTo({ top: viewport.scrollTop + delta, behavior: 'instant' })
    await this.settle()
  }

  /** Moves focus to the viewport, as tabbing to it would. */
  async focus(): Promise<void> {
    await focus(this.viewport)
  }

  /** Waits for the scroller to settle: its frames, a smooth scroll, the observers' reports. */
  async settle(): Promise<void> {
    await waitForObservers()
    await waitForObservers()
  }
}
