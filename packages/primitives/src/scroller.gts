import Component from '@glimmer/component'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import type Owner from '@ember/owner'
import { modifier } from 'ember-modifier'
import { isRTL } from './direction.gts'
import { adoptLayoutStyles } from './-private/layout-styles.ts'
import { scrollEnd } from './-private/scroll-end.ts'

const waiter = buildWaiter('@ember-joinery/primitives:scroller')

/**
 * ember-primitives' documented default: the element scrolls. The app's CSS wins, where the
 * `joinery` layer comes before its own (see `-private/layout-styles.ts`).
 */
const STYLES = `@layer joinery {
  :where([data-jn-scroller]) { overflow: auto; }
}`

/** What `<Scroller>` yields: a function for each edge to scroll to. */
export interface ScrollerControls {
  /** Scrolls to the bottom: `{{(s.scrollToBottom)}}` in a template, or on a click. */
  scrollToBottom: () => void
  /** Scrolls to the top. */
  scrollToTop: () => void
  /** Scrolls to the left edge, whichever the text direction. */
  scrollToLeft: () => void
  /** Scrolls to the right edge, whichever the text direction. */
  scrollToRight: () => void
  /** Scrolls to where a line of text starts: the left in left-to-right text, the right in right-to-left. */
  scrollToStart: () => void
  /** Scrolls to where a line of text ends: the right in left-to-right text, the left in right-to-left. */
  scrollToEnd: () => void
}

export interface ScrollerSignature {
  Args: {
    /** Its name, for its harness (`data-test-jn-name`). */
    name?: string
  }
  Blocks: {
    /** The content to scroll, with the functions that scroll it. */
    default: [ScrollerControls]
  }
  /**
   * The element that scrolls. It has `overflow: auto` and `tabindex="0"`, so a keyboard can
   * scroll it too. Give it a height (or a width) for its content to overflow.
   */
  Element: HTMLDivElement
}

/** Where `scrollTo` should go for an edge, read when the frame comes. */
type Target = (element: HTMLElement) => { top?: number; left?: number }

/**
 * A scrollable element that yields functions to scroll it to any edge, as ember-primitives'
 * `Scroller`: for following new content (a log, a chat) or jumping to either end.
 *
 *   <Scroller class="log" as |s|>
 *     {{#each this.lines as |line|}}
 *       <p>{{line}}</p>
 *       {{(s.scrollToBottom)}}   {{! each line that renders scrolls the log down }}
 *     {{/each}}
 *   </Scroller>
 *
 * A call in a template runs as that part renders, so put it where new content renders, as
 * above. Each call scrolls in the next animation frame, once the content is in; a later call
 * in the same frame replaces it. The scroll's `behavior` is `auto`, so CSS decides
 * (`scroll-behavior: smooth`). Tests wait for it to end: `await settled()`.
 *
 * It wraps content, so it is a wrapper for the harnesses (`data-test-jn-wrapper`): a part
 * inside it still belongs to the component around it.
 */
export class Scroller extends Component<ScrollerSignature> {
  #element: HTMLDivElement | undefined
  #frame: number | undefined
  #token: unknown

  constructor(owner: Owner, args: ScrollerSignature['Args']) {
    super(owner, args)
    registerDestructor(this, () => this.#cancel())
  }

  setup = modifier((element: HTMLDivElement) => {
    this.#element = element
    const stopStyling = adoptLayoutStyles(element, 'scroller', STYLES)
    return () => {
      stopStyling()
      if (this.#element === element) this.#element = undefined
    }
  })

  #cancel(): void {
    if (this.#frame !== undefined) cancelAnimationFrame(this.#frame)
    this.#frame = undefined
    if (this.#token !== undefined) waiter.endAsync(this.#token)
    this.#token = undefined
  }

  #scroll(target: Target): void {
    this.#cancel()
    const token = (this.#token = waiter.beginAsync())
    this.#frame = requestAnimationFrame(() => {
      this.#frame = undefined
      this.#token = undefined
      const element = this.#element
      if (isDestroying(this) || isDestroyed(this) || !element) return waiter.endAsync(token)
      element.scrollTo({ ...target(element), behavior: 'auto' })
      // A smooth scroll (from the CSS) takes a while: tests wait for it to end.
      void scrollEnd(element).then(() => waiter.endAsync(token))
    })
  }

  // In right-to-left text, `scrollLeft` runs from 0 at the right edge down to a negative
  // number at the left, so the far left is "as negative as it gets" in either direction, and
  // the far right "as positive as it gets": the browser clamps both.
  #left: Target = element => ({ left: -element.scrollWidth })
  #right: Target = element => ({ left: element.scrollWidth })

  scrollToBottom = (): void => this.#scroll(element => ({ top: element.scrollHeight }))
  scrollToTop = (): void => this.#scroll(() => ({ top: 0 }))
  scrollToLeft = (): void => this.#scroll(this.#left)
  scrollToRight = (): void => this.#scroll(this.#right)
  scrollToStart = (): void =>
    this.#scroll(element => (isRTL(element) ? this.#right : this.#left)(element))
  scrollToEnd = (): void =>
    this.#scroll(element => (isRTL(element) ? this.#left : this.#right)(element))

  /** The same object on every render, so a block that reads it doesn't re-render for it. */
  readonly controls: ScrollerControls = Object.freeze({
    scrollToBottom: this.scrollToBottom,
    scrollToTop: this.scrollToTop,
    scrollToLeft: this.scrollToLeft,
    scrollToRight: this.scrollToRight,
    scrollToStart: this.scrollToStart,
    scrollToEnd: this.scrollToEnd,
  })

  <template>
    <div
      tabindex="0"
      data-jn-scroller
      data-test-jn="scroller"
      data-test-jn-wrapper
      data-test-jn-name={{@name}}
      ...attributes
      {{this.setup}}
    >
      {{yield this.controls}}
    </div>
  </template>
}
