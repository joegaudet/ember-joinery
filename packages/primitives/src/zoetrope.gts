import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { isDestroyed, isDestroying } from '@ember/destroyable'
import { buildWaiter, waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import { isRTL } from './direction.gts'
import { adoptLayoutStyles } from './-private/layout-styles.ts'
import { scrollEnd } from './-private/scroll-end.ts'

const waiter = buildWaiter('@ember-joinery/primitives:zoetrope')

const DEFAULT_GAP = 8
const DEFAULT_OFFSET = 0

/**
 * ember-primitives' zoetrope rules, with logical sides so they serve right-to-left text too:
 * a header and the controls on one line, and under them the track, which scrolls sideways,
 * snaps to each item's start and hides its scrollbar. Any CSS of the app's wins.
 */
const STYLES = `@layer joinery {
  :where([data-jn-zoetrope]) { display: flex; flex-wrap: wrap; position: relative; width: 100%; }
  :where([data-jn-zoetrope-header]) {
    align-items: center;
    display: flex;
    flex: 1;
    justify-content: space-between;
    padding-inline-start: var(--zoetrope-offset, 0);
  }
  :where([data-jn-zoetrope-controls]) {
    align-items: center;
    display: flex;
    padding-inline-end: var(--zoetrope-offset, 0);
    gap: 4px;
  }
  :where([data-jn-zoetrope-scroller]) {
    display: flex;
    flex-flow: row nowrap;
    gap: var(--zoetrope-gap, 8px);
    overflow: scroll visible;
    padding: 8px var(--zoetrope-offset, 0);
    scroll-padding-inline-start: var(--zoetrope-offset, 0);
    scroll-snap-type: x mandatory;
    scrollbar-color: transparent transparent;
    scrollbar-width: none;
    width: 100%;
  }
  :where([data-jn-zoetrope-scroller] > *) { flex-shrink: 0; scroll-snap-align: start; }
  @media (prefers-reduced-motion: no-preference) {
    :where([data-jn-zoetrope-scroller]) { scroll-behavior: smooth; }
  }
}`

/** How a scroll the zoetrope starts moves: as the DOM's `scrollBy` takes it. */
export type ZoetropeScrollBehavior = 'auto' | 'smooth' | 'instant'

/** What the `<:controls>` block is given, to make buttons of your own. */
export interface ZoetropeControls {
  /** Whether the items overflow, so there is anywhere to scroll. */
  canScroll: boolean
  /** Whether there is nothing more to the left: disable a "left" button with it. */
  cannotScrollLeft: boolean
  /** Whether there is nothing more to the right. */
  cannotScrollRight: boolean
  /** Scrolls a page of items to the left: the items before, in left-to-right text. */
  scrollLeft: () => void
  /** Scrolls a page of items to the right: the next items, in left-to-right text. */
  scrollRight: () => void
}

export interface ZoetropeSignature {
  Args: {
    /** The space between items, in pixels (`--zoetrope-gap`). Default 8. */
    gap?: number
    /**
     * The space between the edges and the first and last items, in pixels
     * (`--zoetrope-offset`), so the items can show past the edges of the content around it.
     * Default 0.
     */
    offset?: number
    /**
     * How the buttons and Tab scroll: `smooth` (the default), `instant` or `auto` (the CSS's
     * `scroll-behavior`). When the system asks for reduced motion, they are always instant.
     */
    scrollBehavior?: ZoetropeScrollBehavior
    /** The default left button's text. Default `Left`. */
    scrollLeftLabel?: string
    /** The default right button's text. Default `Right`. */
    scrollRightLabel?: string
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** A heading for the items, on the line above them, beside the controls. */
    header: []
    /** The items, side by side in the track: links, cards, images. */
    content: []
    /**
     * Your own buttons instead of the default ones, given what they need. To place them where
     * the default ones go, put them in an element with `data-jn-zoetrope-controls`.
     */
    controls: [ZoetropeControls]
  }
  /**
   * The `<section>`. Give it an `aria-label` (or `aria-labelledby` the header's heading), so
   * screen readers list it as a region.
   */
  Element: HTMLElement
}

/** A box's place along the track, in pixels from the start of its content box. */
interface Span {
  start: number
  end: number
  width: number
}

/**
 * Where `child` is inside `parent`'s content box (inside its border and padding), measured
 * from the side lines of text start on: the left, or the right in right-to-left text. In CSS
 * pixels, as `scrollBy` takes them, even inside a scaled element (a `transform: scale()`, as
 * a test's container has), where the boxes the browser reports are scaled too.
 */
function spanIn(child: Element, parent: HTMLElement, rtl: boolean): Span {
  const box = child.getBoundingClientRect()
  const outer = parent.getBoundingClientRect()
  const scale = parent.offsetWidth > 0 ? outer.width / parent.offsetWidth || 1 : 1
  const style = getComputedStyle(parent)
  const edge = rtl
    ? (outer.right - box.right) / scale -
      parseFloat(style.borderRightWidth) -
      parseFloat(style.paddingRight)
    : (box.left - outer.left) / scale -
      parseFloat(style.borderLeftWidth) -
      parseFloat(style.paddingLeft)
  const width = box.width / scale
  return { start: edge, end: edge + width, width }
}

/**
 * A row of items that scrolls sideways a page at a time, on the browser's own scrolling, as
 * ember-primitives' `Zoetrope` (the carousels of a streaming service's home page): a header,
 * left and right buttons, and a track that snaps to each item.
 *
 *   <Zoetrope @gap={{8}} @offset={{40}} aria-label="New releases">
 *     <:header><h2>New releases</h2></:header>
 *     <:content>
 *       {{#each this.films as |film|}}<a href={{film.url}} class="card">{{film.title}}</a>{{/each}}
 *     </:content>
 *   </Zoetrope>
 *
 * It finds the page size itself: a button scrolls by as many items as fit. The buttons show
 * only when the items overflow, and each is disabled at its end. Tab from one item to the next
 * scrolls that item to the start; when the next item can't take focus, Tab is left to the
 * browser, so it never traps the keyboard. In right-to-left text the track starts on the right,
 * and "left" and "right" still mean the sides they name.
 *
 * It renders a `<section>`, which needs an `aria-label` to be a region. A scroll waits for its
 * end in tests, so `await click()` (or `ZoetropeHarness`) leaves it where it stopped.
 */
export class Zoetrope extends Component<ZoetropeSignature> {
  @tracked scrolled = 0
  @tracked scrollWidth = 0
  @tracked offsetWidth = 0
  @tracked rtl = false

  #scroller: HTMLElement | undefined

  get gap(): number {
    return this.args.gap ?? DEFAULT_GAP
  }

  get offset(): number {
    return this.args.offset ?? DEFAULT_OFFSET
  }

  get scrollLeftLabel(): string {
    return this.args.scrollLeftLabel ?? 'Left'
  }

  get scrollRightLabel(): string {
    return this.args.scrollRightLabel ?? 'Right'
  }

  get canScroll(): boolean {
    return this.scrollWidth > this.offsetWidth + this.offset
  }

  /** Nothing more before the first item: within `@offset` of the start, as ember-primitives has it. */
  get atStart(): boolean {
    return this.scrolled <= this.offset
  }

  /** Nothing more after the last item, to within a pixel (scroll positions can be fractional). */
  get atEnd(): boolean {
    return this.scrolled + 1 >= this.scrollWidth - this.offsetWidth - this.offset
  }

  get cannotScrollLeft(): boolean {
    return this.rtl ? this.atEnd : this.atStart
  }

  get cannotScrollRight(): boolean {
    return this.rtl ? this.atStart : this.atEnd
  }

  /** How a scroll moves now: always instant when the system asks for reduced motion. */
  get scrollBehavior(): ZoetropeScrollBehavior {
    if (window.matchMedia?.('(prefers-reduced-motion: reduce)').matches) return 'instant'
    return this.args.scrollBehavior ?? 'smooth'
  }

  setStyles = modifier((element: HTMLElement, [gap, offset]: [number, number]) => {
    adoptLayoutStyles(element, 'zoetrope', STYLES)
    element.style.setProperty('--zoetrope-gap', `${gap}px`)
    element.style.setProperty('--zoetrope-offset', `${offset}px`)
  })

  setupScroller = modifier((element: HTMLElement) => {
    this.#scroller = element
    // The first measurement comes with the observer's first report; tests wait for it.
    let token: unknown = waiter.beginAsync()
    const measure = () => {
      if (isDestroying(this) || isDestroyed(this)) return
      this.scrollWidth = element.scrollWidth
      this.offsetWidth = element.offsetWidth
      this.rtl = isRTL(element)
      this.scrolled = Math.abs(element.scrollLeft)
      if (token !== undefined) waiter.endAsync(token)
      token = undefined
    }
    // The track's size, and its items' (an image that loads changes how far it scrolls).
    const resizes = new ResizeObserver(measure)
    const watch = () => {
      resizes.disconnect()
      resizes.observe(element)
      for (const child of element.children) resizes.observe(child)
    }
    const changes = new MutationObserver(() => {
      watch()
      measure()
    })
    watch()
    changes.observe(element, { childList: true })
    const onScroll = () => {
      this.scrolled = Math.abs(element.scrollLeft)
    }
    element.addEventListener('scroll', onScroll, { passive: true })
    element.addEventListener('keydown', this.onKeydown)
    return () => {
      if (token !== undefined) waiter.endAsync(token)
      resizes.disconnect()
      changes.disconnect()
      element.removeEventListener('scroll', onScroll)
      element.removeEventListener('keydown', this.onKeydown)
      if (this.#scroller === element) this.#scroller = undefined
    }
  })

  /**
   * Tab from an item to the next one (Shift+Tab, the one before) brings it to the start of the
   * track. When that item can't take focus, the key is left alone and the browser moves focus
   * on as usual: cancelling it then would trap the keyboard.
   */
  onKeydown = (event: KeyboardEvent): void => {
    const scroller = this.#scroller
    const target = event.target
    if (event.key !== 'Tab' || !scroller || !(target instanceof HTMLElement)) return
    // Only an item itself: an element inside one has siblings of its own.
    if (target.parentElement !== scroller) return

    const next = event.shiftKey ? target.previousElementSibling : target.nextElementSibling
    if (!(next instanceof HTMLElement)) return
    next.focus({ preventScroll: true })
    const root = target.getRootNode() as Document | ShadowRoot
    if (root.activeElement !== next) return

    event.preventDefault()
    this.#scrollBy(scroller, spanIn(next, scroller, isRTL(scroller)).start)
  }

  /** Scrolls the track by `distance` along it: towards its end, or back when negative. */
  #scrollBy(scroller: HTMLElement, distance: number): void {
    const rtl = isRTL(scroller)
    scroller.scrollBy({ left: rtl ? -distance : distance, behavior: this.scrollBehavior })
    this.scrolled = Math.abs(scroller.scrollLeft)
    void waitForPromise(scrollEnd(scroller))
  }

  /**
   * The items at the edges of the view: the first one at least partly in it (`first`), the
   * first one that starts past `@offset` (`active`), and the first one that runs past the end
   * (`last`), or the last item when none does.
   */
  #edges(scroller: HTMLElement, rtl: boolean) {
    const edges: { first?: Element; active?: Element; last?: Element } = {}
    const parent = scroller.parentElement
    if (!parent) return edges
    const container = spanIn(scroller, parent, rtl)
    const children = [...scroller.children]
    for (const child of children) {
      const span = spanIn(child, scroller, rtl)
      if (!edges.first && span.end + this.gap >= container.start) edges.first = child
      if (!edges.active && span.start >= this.offset) edges.active = child
      if (span.end >= container.width) {
        edges.last = child
        break
      }
    }
    edges.first ??= children[0]
    edges.last ??= children[children.length - 1]
    return edges
  }

  /** Back a page: the item a page before the first in view comes to the start. */
  #backward(scroller: HTMLElement): void {
    const rtl = isRTL(scroller)
    const { first } = this.#edges(scroller, rtl)
    if (!first) return
    const children = [...scroller.children]
    let target = first
    let width = 0
    for (let i = children.indexOf(first); i >= 0; i--) {
      const child = children[i]
      if (!(child instanceof HTMLElement)) continue
      width += child.offsetWidth + this.gap
      if (width >= this.offsetWidth) break
      target = child
    }
    this.#scrollBy(scroller, spanIn(target, scroller, rtl).start)
  }

  /** On a page: the first item that runs past the end comes to the start. */
  #forward(scroller: HTMLElement): void {
    const rtl = isRTL(scroller)
    const { active, last } = this.#edges(scroller, rtl)
    if (!last) return
    let span = spanIn(last, scroller, rtl)
    // An item wider than the view that is already at the start: on to the one after it.
    if (span.width > this.offsetWidth && active === last) {
      const after = last.nextElementSibling
      if (!after) return
      span = spanIn(after, scroller, rtl)
    }
    this.#scrollBy(scroller, span.start)
  }

  scrollLeft = (): void => {
    const scroller = this.#scroller
    if (!scroller) return
    if (isRTL(scroller)) this.#forward(scroller)
    else this.#backward(scroller)
  }

  scrollRight = (): void => {
    const scroller = this.#scroller
    if (!scroller) return
    if (isRTL(scroller)) this.#backward(scroller)
    else this.#forward(scroller)
  }

  get controls(): ZoetropeControls {
    return {
      canScroll: this.canScroll,
      cannotScrollLeft: this.cannotScrollLeft,
      cannotScrollRight: this.cannotScrollRight,
      scrollLeft: this.scrollLeft,
      scrollRight: this.scrollRight,
    }
  }

  <template>
    <section
      data-jn-zoetrope
      data-test-jn="zoetrope"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.setStyles this.gap this.offset}}
    >
      {{#if (has-block "header")}}
        <div data-jn-zoetrope-header data-test-jn-part="header">
          {{yield to="header"}}
        </div>
      {{/if}}

      {{#if (has-block "controls")}}
        {{yield this.controls to="controls"}}
      {{else if this.canScroll}}
        <div data-jn-zoetrope-controls data-test-jn-part="controls">
          <button
            type="button"
            data-test-jn-part="scroll-left"
            disabled={{this.cannotScrollLeft}}
            {{on "click" this.scrollLeft}}
          >{{this.scrollLeftLabel}}</button>
          <button
            type="button"
            data-test-jn-part="scroll-right"
            disabled={{this.cannotScrollRight}}
            {{on "click" this.scrollRight}}
          >{{this.scrollRightLabel}}</button>
        </div>
      {{/if}}

      {{#if (has-block "content")}}
        <div data-jn-zoetrope-scroller data-test-jn-part="scroller" {{this.setupScroller}}>
          {{yield to="content"}}
        </div>
      {{/if}}
    </section>
  </template>
}
