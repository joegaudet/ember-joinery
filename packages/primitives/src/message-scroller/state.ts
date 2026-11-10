// The message scroller's behaviour, ported from @shadcn/react's message-scroller
// (use-message-scroller-controller.ts, use-message-scroller-commands.ts,
// use-message-scroller-refs.ts and stores.ts, shadcn-ui/ui@8ab2771). Upstream keeps it in refs
// and mirrors the state onto the DOM so scrolling never re-renders a row; here it is one class
// with plain fields, and only the three things a template reads are tracked: which edges can be
// scrolled to, whether the opening position is pending, and (while something watches it) the
// reader's place.
import { tracked } from '@glimmer/tracking'
import { buildWaiter } from '@ember/test-waiters'
import { scrollEnd } from '../-private/scroll-end.ts'
import {
  EMPTY_SCROLLABLE,
  EMPTY_VISIBILITY,
  SCROLL_POSITION_EPSILON,
  getContentBottom,
  getElementScrollTop,
  getElementTop,
  getElementViewportTop,
  getFirstVisibleMessageItem,
  getFlexGap,
  getLastScrollAnchor,
  getMaxScrollTop,
  getMessageScrollerItems,
  getMessageScrollerScrollable,
  getMessageScrollerVisibilityState,
  getNewScrollAnchor,
  getScale,
  getTailSpacerHeight,
  getUnanchoredScrollAnchor,
  hasMultipleNewScrollAnchors,
  type MessageScrollerScrollAlign,
  type MessageScrollerScrollable,
  type MessageScrollerVisibilityState,
} from './geometry.ts'

const waiter = buildWaiter('@ember-joinery/primitives:message-scroller')

/** Distance from an edge that still counts as at it: rounding differs between engines. */
export const DEFAULT_SCROLL_EDGE_THRESHOLD = 8

/** How much of the previous row stays in view above a newly anchored turn, in pixels. */
export const DEFAULT_SCROLL_PREVIOUS_ITEM_PEEK = 64

/** The margin a command leaves on the edge it lines its target up with, in pixels. */
export const DEFAULT_SCROLL_MARGIN = 0

/** How long `data-autoscrolling` stays after a programmatic scroll to the end, in ms. */
const AUTOSCROLLING_CLEAR_DELAY = 180

/** The viewport keys that are the reader scrolling on purpose: they release following. */
export const USER_SCROLL_KEYS: ReadonlySet<string> = new Set([
  'ArrowDown',
  'ArrowUp',
  'End',
  'Home',
  'PageDown',
  'PageUp',
  ' ',
])

/** Where a saved transcript opens, once, on its first render with rows. */
export type MessageScrollerDefaultScrollPosition = 'start' | 'end' | 'last-anchor'

/** Which edge a scroll button scrolls to. */
export type MessageScrollerDirection = 'start' | 'end'

/** What `scrollToMessage`, `scrollToEnd` and `scrollToStart` take. */
export interface MessageScrollerScrollOptions {
  /** The edge (or the middle) of the viewport to line the target up with. Default `start`. */
  align?: MessageScrollerScrollAlign
  /** The native scroll behavior. Default `auto`. */
  behavior?: ScrollBehavior
  /** The margin on that edge, in pixels. Default the scroller's `@scrollMargin`. */
  scrollMargin?: number
}

/** What the scroller takes: the provider's arguments. */
export interface MessageScrollerOptions {
  /** Follow new content at the end while the reader is already there. Default `false`. */
  autoScroll?: boolean
  /** Where the transcript opens, once, on its first render with rows. Default `end`. */
  defaultScrollPosition?: MessageScrollerDefaultScrollPosition
  /** Distance from an edge that still counts as at it. Default 8. */
  scrollEdgeThreshold?: number
  /** How much of the previous row stays in view above a new turn. Default 64. */
  scrollPreviousItemPeek?: number
  /** The margin commands leave on the edge they line a row up with. Default 0. */
  scrollMargin?: number
}

/**
 * How the viewport reacts to content and resizes, from what the reader and the commands did:
 * following the end, left alone, holding a turn at the reading line while it streams, or
 * letting a programmatic jump settle.
 */
type Mode = 'following-bottom' | 'free-scrolling' | 'anchored-to-message' | 'settling-jump'

/** One frame of work, held by the test waiter until it runs or is cancelled. */
class Frame {
  #id: number | null = null
  #token: unknown = null

  get pending(): boolean {
    return this.#id !== null
  }

  /** Runs `callback` next frame, unless one is already pending. */
  request(callback: () => void): void {
    if (this.#id !== null) return
    this.#token = waiter.beginAsync()
    this.#id = requestAnimationFrame(() => {
      this.#id = null
      const token = this.#token
      this.#token = null
      try {
        callback()
      } finally {
        waiter.endAsync(token)
      }
    })
  }

  /** Runs `callback` next frame, in place of one already pending. */
  replace(callback: () => void): void {
    this.cancel()
    this.request(callback)
  }

  cancel(): void {
    if (this.#id !== null) cancelAnimationFrame(this.#id)
    this.#id = null
    if (this.#token !== null) waiter.endAsync(this.#token)
    this.#token = null
  }
}

const sameScrollable = (a: MessageScrollerScrollable, b: MessageScrollerScrollable) =>
  a.start === b.start && a.end === b.end

const sameVisibility = (a: MessageScrollerVisibilityState, b: MessageScrollerVisibilityState) =>
  a.currentAnchorId === b.currentAnchorId &&
  a.visibleMessageIds.length === b.visibleMessageIds.length &&
  a.visibleMessageIds.every((id, index) => id === b.visibleMessageIds[index])

/**
 * One message scroller's state and behaviour: the provider makes one, and its parts register
 * their elements with it. It decides when to scroll (the opening position, following the end,
 * anchoring a new turn, keeping the reader's row in place when history is prepended), runs the
 * commands, and tracks which edges can be scrolled to and, while something watches, where the
 * reader is.
 */
export class MessageScrollerState {
  /** Which edges the viewport can scroll toward. `end` stays false while it follows the end. */
  @tracked scrollable: MessageScrollerScrollable = EMPTY_SCROLLABLE
  /** Whether the opening position is still to be applied (`end` and `last-anchor` only). */
  @tracked pendingDefaultScroll: boolean
  /** Where the reader is: up to date while a `Visibility` (or `observeVisibility()`) watches. */
  @tracked visibility: MessageScrollerVisibilityState = EMPTY_VISIBILITY

  /** Keep the first visible row in place when rows are prepended (the viewport's argument). */
  preserveScrollOnPrepend = true

  readonly #options: () => MessageScrollerOptions
  #mode: Mode
  #lastDefaultScrollPosition: MessageScrollerDefaultScrollPosition
  #lastAutoScroll: boolean
  #autoscrolling = false
  #autoscrollingTimeout: ReturnType<typeof setTimeout> | null = null
  #autoscrollingToken: unknown = null
  #defaultScrollPositionApplied = false
  #itemCount = 0
  #items: HTMLElement[] = []
  #firstItem: HTMLElement | null = null
  #lastScrollTop = 0
  #streamingTurn: HTMLElement | null = null
  #pendingScrollToMessage: { messageId: string; options?: MessageScrollerScrollOptions } | null =
    null
  #prependRestore: { element: HTMLElement; viewportTop: number } | null = null
  #spacerGap = 0
  #spacerHeight = 0
  #handledScrollAnchors = new WeakSet<HTMLElement>()
  #messageElements = new Map<string, HTMLElement>()
  #visibleMessageIds = new Set<string>()
  #visibilityObserver: IntersectionObserver | null = null
  #visibilityWatchers = 0
  #mountScheduled = false
  #contentRendered = false
  #destroyed = false

  readonly #stateFrame = new Frame()
  readonly #resizeFrame = new Frame()
  readonly #visibilityFrame = new Frame()
  readonly #pendingScrollFrame = new Frame()

  root: HTMLElement | null = null
  viewport: HTMLElement | null = null
  content: HTMLElement | null = null
  spacer: HTMLElement | null = null

  constructor(options: () => MessageScrollerOptions = () => ({})) {
    this.#options = options
    const { autoScroll = false, defaultScrollPosition = 'end' } = options()
    this.#mode = autoScroll ? 'following-bottom' : 'free-scrolling'
    this.#lastAutoScroll = autoScroll
    this.#lastDefaultScrollPosition = defaultScrollPosition
    this.pendingDefaultScroll =
      defaultScrollPosition === 'end' || defaultScrollPosition === 'last-anchor'
  }

  // ----- Options ------------------------------------------------------------------------------

  get #autoScroll(): boolean {
    return this.#options().autoScroll ?? false
  }

  get #defaultScrollPosition(): MessageScrollerDefaultScrollPosition {
    return this.#options().defaultScrollPosition ?? 'end'
  }

  get #scrollEdgeThreshold(): number {
    return this.#options().scrollEdgeThreshold ?? DEFAULT_SCROLL_EDGE_THRESHOLD
  }

  get #scrollMargin(): number {
    return this.#options().scrollMargin ?? DEFAULT_SCROLL_MARGIN
  }

  get #scrollPreviousItemPeek(): number {
    return this.#options().scrollPreviousItemPeek ?? DEFAULT_SCROLL_PREVIOUS_ITEM_PEEK
  }

  /**
   * The provider calls this on every render, with its arguments as they are. A change to
   * `autoScroll` or `defaultScrollPosition` is acted on after the render, as upstream's layout
   * effects do.
   */
  optionsChanged(): void {
    const { autoScroll = false, defaultScrollPosition = 'end' } = this.#options()
    if (defaultScrollPosition !== this.#lastDefaultScrollPosition) {
      this.#lastDefaultScrollPosition = defaultScrollPosition
      // The pending-scroll hold is for the first render only: a later change applies the new
      // opening position without hiding the viewport again.
      this.#defaultScrollPositionApplied = false
      this.#scheduleMount()
    }
    if (autoScroll !== this.#lastAutoScroll) {
      this.#lastAutoScroll = autoScroll
      this.#afterRender(() => {
        if (autoScroll && this.#mode === 'following-bottom' && this.#itemCount > 0) {
          this.scrollToEnd({ behavior: 'auto' })
        } else {
          this.#commitScrollState()
        }
      })
    }
  }

  // ----- Elements -----------------------------------------------------------------------------

  /** The root registers itself: it mirrors the scroll-state attributes. */
  setRoot = (element: HTMLElement | null): void => {
    this.root = element
    if (element) {
      this.#writeStateAttributes(this.scrollable)
      this.#scheduleMount()
    }
  }

  /** The viewport registers itself: it scrolls, and is the visibility observer's root. */
  setViewport = (element: HTMLElement | null): void => {
    this.viewport = element
    if (element) {
      this.#writeStateAttributes(this.scrollable)
      if (this.#visibilityWatchers > 0) this.#startVisibility()
      this.#scheduleMount()
    } else {
      this.#stopVisibility()
    }
  }

  /** The content registers itself: its children are the rows. */
  setContent = (element: HTMLElement | null): void => {
    this.content = element
    if (element) {
      // Its rows rendered with it, before any mutation could be observed.
      this.#contentRendered = true
      this.#scheduleMount()
    }
  }

  /** The tail spacer registers itself: it makes room below an anchored turn. */
  setSpacer = (element: HTMLElement | null): void => {
    this.spacer = element
    this.#spacerGap = getFlexGap(element?.parentElement ?? null)
  }

  /** A row with a `messageId` registers itself, and unregisters (`element` null) when it goes. */
  registerMessage = (
    messageId: string,
    element: HTMLElement | null,
    removedElement?: HTMLElement | null,
  ): void => {
    if (element) {
      this.#messageElements.set(messageId, element)
      this.#visibilityObserver?.observe(element)
      this.#scheduleVisibilitySync()
      if (this.#pendingScrollToMessage?.messageId === messageId) {
        this.#schedulePendingScrollToMessageFlush()
      }
      return
    }
    if (removedElement && this.#messageElements.get(messageId) === removedElement) {
      this.#messageElements.delete(messageId)
      this.#visibleMessageIds.delete(messageId)
      this.#visibilityObserver?.unobserve(removedElement)
      this.#scheduleVisibilitySync()
    }
  }

  // ----- Connecting the parts' elements -------------------------------------------------------

  /** The root's modifier: registers it until the returned cleanup runs. */
  connectRoot(element: HTMLElement): () => void {
    this.setRoot(element)
    return () => {
      if (this.root === element) this.setRoot(null)
    }
  }

  /**
   * The viewport's modifier: registers it, and listens for its scrolls, the reader's scroll
   * gestures (wheel, touch, scroll keys) and its resizes, until the returned cleanup runs.
   */
  connectViewport(element: HTMLElement): () => void {
    this.setViewport(element)
    const passive = { passive: true }
    element.addEventListener('scroll', this.handleScroll, passive)
    element.addEventListener('wheel', this.userScrollIntent, passive)
    element.addEventListener('touchmove', this.userScrollIntent, passive)
    element.addEventListener('keydown', this.handleKeydown)
    const resizes = this.#observeResizes(element)
    return () => {
      element.removeEventListener('scroll', this.handleScroll)
      element.removeEventListener('wheel', this.userScrollIntent)
      element.removeEventListener('touchmove', this.userScrollIntent)
      element.removeEventListener('keydown', this.handleKeydown)
      resizes()
      if (this.viewport === element) this.setViewport(null)
    }
  }

  /**
   * The content's modifier: registers it, and hears rows come and go (its children) and its
   * resizes, until the returned cleanup runs.
   */
  connectContent(element: HTMLElement): () => void {
    this.setContent(element)
    const mutations =
      typeof MutationObserver === 'undefined'
        ? undefined
        : new MutationObserver(() => this.handleContentChange())
    mutations?.observe(element, { childList: true })
    const resizes = this.#observeResizes(element)
    return () => {
      mutations?.disconnect()
      resizes()
      if (this.content === element) this.setContent(null)
    }
  }

  /** The spacer's modifier. */
  connectSpacer(element: HTMLElement): () => void {
    this.setSpacer(element)
    return () => {
      if (this.spacer === element) this.setSpacer(null)
    }
  }

  /** A row's modifier: registers it by its `messageId` (if it has one) until the cleanup runs. */
  connectItem(element: HTMLElement, messageId: string | undefined): () => void {
    if (!messageId) return () => {}
    this.registerMessage(messageId, element)
    return () => this.registerMessage(messageId, null, element)
  }

  /**
   * Resizes are handled a frame later: handling one resizes the spacer inside the observed
   * content, and resizing an observed element while its resize is delivered makes the browser
   * report a "ResizeObserver loop".
   */
  #observeResizes(element: HTMLElement): () => void {
    if (typeof ResizeObserver === 'undefined') return () => {}
    const observer = new ResizeObserver(() => this.#resizeFrame.replace(this.handleResize))
    observer.observe(element)
    return () => observer.disconnect()
  }

  // ----- Events -------------------------------------------------------------------------------

  /** The viewport scrolled, whoever scrolled it. */
  handleScroll = (): void => {
    // A spacer left behind when a stream ends before the reply drains it: a scroll to the real
    // bottom finishes the job, and following re-arms once it reaches zero.
    this.#drainReleasedSpacer()
    this.#commitScrollState()
    this.#scheduleVisibilitySync()
    this.#capturePrependAnchor()
  }

  /**
   * The reader scrolled on purpose (wheel, touch, a scroll key): that releases following, the
   * anchored turn and a jump still settling, so they never fight the reader.
   */
  userScrollIntent = (): void => {
    if (
      this.#mode === 'following-bottom' ||
      this.#mode === 'anchored-to-message' ||
      this.#mode === 'settling-jump'
    ) {
      this.#streamingTurn = null
      this.#mode = 'free-scrolling'
    }
  }

  /** A key went down in the viewport: a scroll key is the reader scrolling. */
  handleKeydown = (event: KeyboardEvent): void => {
    if (USER_SCROLL_KEYS.has(event.key)) this.userScrollIntent()
  }

  /** The rows changed: some were appended, prepended, removed or replaced. */
  handleContentChange = (): void => {
    const content = this.content
    if (!content || this.#destroyed) return
    const items = getMessageScrollerItems(content, this.spacer)
    // Glimmer moves its own markers (the text nodes around a block) among the rows, which a
    // childList observer reports though no row came or went. React's commits don't, so
    // upstream reconciles on every report; here the rows must have changed first.
    const previous = this.#items
    if (
      previous.length === items.length &&
      previous.every((item, index) => item === items[index])
    ) {
      return
    }
    this.#items = items
    const previousItemCount = this.#itemCount
    const previousFirstItem = this.#firstItem
    this.#itemCount = items.length
    this.#firstItem = items[0] ?? null
    this.#reconcileScrollPosition(items, previousItemCount, previousFirstItem)
    this.#capturePrependAnchor()
  }

  /** The viewport or the content changed size. */
  handleResize = (): void => {
    if (this.#destroyed) return
    if (this.#mode === 'following-bottom' && this.#autoScroll) {
      this.scrollToEnd({ behavior: 'auto' })
      return
    }
    // Hold the anchored turn in place as what's below it resizes (a reply streaming in), so
    // the shrinking room doesn't let the browser clamp scrollTop and drop the turn.
    const previousSpacerHeight = this.#spacerHeight
    if (this.#reanchorToAnchoredMessage()) {
      // The reply below the anchor uses up the tail spacer as it grows. Once it's gone the
      // reply fills the viewport and the reader is at the live edge, so following takes over.
      // Only on the >0 → 0 step, so a turn taller than the viewport stays held.
      if (this.#autoScroll && previousSpacerHeight > 0 && this.#spacerHeight === 0) {
        this.scrollToEnd({ behavior: 'auto' })
      }
      return
    }
    if (this.#drainReleasedSpacer()) return
    this.#scheduleStateCommit()
    this.#scheduleVisibilitySync()
  }

  // ----- Commands -----------------------------------------------------------------------------

  /** Scrolls to the top. `false` only while the viewport isn't rendered. */
  scrollToStart = ({ behavior = 'auto' }: MessageScrollerScrollOptions = {}): boolean => {
    if (!this.viewport) return false
    this.#setTailSpacerHeight(0)
    this.#streamingTurn = null
    this.#mode = 'free-scrolling'
    this.#scrollToPosition(0, { behavior })
    this.#scheduleVisibilitySync()
    return true
  }

  /**
   * Scrolls to the latest row, and with `autoScroll`, follows the end again. `false` only while
   * the viewport isn't rendered.
   */
  scrollToEnd = ({ behavior = 'auto' }: MessageScrollerScrollOptions = {}): boolean => {
    const viewport = this.viewport
    if (!viewport) return false
    this.#setTailSpacerHeight(0)
    this.#streamingTurn = null
    this.#mode = this.#autoScroll ? 'following-bottom' : 'free-scrolling'
    this.#scrollToPosition(getMaxScrollTop(viewport), { autoscrolling: true, behavior })
    this.#scheduleVisibilitySync()
    return true
  }

  /**
   * Scrolls to the row with this `messageId`. Before any row has rendered it is queued, for a
   * permalink resolved while the transcript loads; after that, a missing id gives `false`.
   * `true` means it scrolled or was queued, not that the row is in view yet.
   */
  scrollToMessage = (messageId: string, options?: MessageScrollerScrollOptions): boolean => {
    const element = this.#messageElements.get(messageId)
    if (!element) {
      if (this.#itemCount === 0) {
        this.#pendingScrollToMessage = { messageId, options }
        this.#markDefaultScrollPositionApplied()
        return true
      }
      return false
    }
    this.#markDefaultScrollPositionApplied()
    if (this.#scrollToElement(element, options)) {
      this.#pendingScrollToMessage = null
      return true
    }
    this.#pendingScrollToMessage = { messageId, options }
    return true
  }

  // ----- Visibility ---------------------------------------------------------------------------

  /**
   * Starts tracking where the reader is (`visibility`), until the function it returns is
   * called. Tracking is paid for only while something watches.
   */
  observeVisibility = (): (() => void) => {
    this.#visibilityWatchers += 1
    if (this.#visibilityWatchers === 1) this.#startVisibility()
    let stopped = false
    return () => {
      if (stopped) return
      stopped = true
      this.#visibilityWatchers -= 1
      if (this.#visibilityWatchers === 0) this.#stopVisibility()
    }
  }

  #startVisibility(): void {
    const viewport = this.viewport
    if (!viewport || this.#visibilityWatchers === 0) return
    if (typeof IntersectionObserver === 'undefined') {
      this.#scheduleVisibilitySync()
      return
    }
    if (!this.#visibilityObserver) {
      const scale = getScale(viewport)
      this.#visibilityObserver = new IntersectionObserver(
        entries => {
          for (const entry of entries) {
            const messageId = (entry.target as HTMLElement).dataset['messageId']
            if (!messageId) continue
            if (entry.isIntersecting) this.#visibleMessageIds.add(messageId)
            else this.#visibleMessageIds.delete(messageId)
          }
          this.#scheduleVisibilitySync()
        },
        {
          root: viewport,
          // The root's top edge moves down to the reading line, so a previous turn peeking in
          // the margin and peek band doesn't count as visible, in step with currentAnchorId.
          rootMargin: `${-(this.#scrollMargin + this.#scrollPreviousItemPeek) * scale}px 0px 0px 0px`,
          threshold: [0, 0.01, 0.5, 1],
        },
      )
    }
    for (const element of this.#messageElements.values()) this.#visibilityObserver.observe(element)
    this.#scheduleVisibilitySync()
  }

  #stopVisibility(): void {
    this.#visibilityFrame.cancel()
    this.#visibilityObserver?.disconnect()
    this.#visibilityObserver = null
    this.#visibleMessageIds.clear()
    this.#afterRender(() => this.#setVisibility(EMPTY_VISIBILITY))
  }

  #setVisibility(next: MessageScrollerVisibilityState): void {
    if (!sameVisibility(this.visibility, next)) this.visibility = next
  }

  #scheduleVisibilitySync(): void {
    if (this.#visibilityWatchers === 0) return
    this.#visibilityFrame.request(() => {
      // The last watcher may have gone in the meantime.
      if (this.#visibilityWatchers === 0 || this.#destroyed) return
      this.#setVisibility(
        getMessageScrollerVisibilityState({
          content: this.content,
          scrollMargin: this.#scrollMargin,
          scrollPreviousItemPeek: this.#scrollPreviousItemPeek,
          spacer: this.spacer,
          viewport: this.viewport,
          visibleMessageIds: this.#visibleMessageIds,
        }),
      )
    })
  }

  // ----- State --------------------------------------------------------------------------------

  #writeStateAttributes(state: MessageScrollerScrollable): void {
    const scrollable = [state.start && 'start', state.end && 'end'].filter(Boolean).join(' ')
    for (const element of [this.root, this.viewport]) {
      if (!element) continue
      if (scrollable) element.setAttribute('data-scrollable', scrollable)
      else element.removeAttribute('data-scrollable')
      element.toggleAttribute('data-autoscrolling', this.#autoscrolling)
    }
  }

  /**
   * The one place following the end starts and stops: it arms at the end, and lets go when the
   * reader scrolls up (a scrollbar drag included), but not during a programmatic scroll, nor
   * while a freshly anchored turn is held (the tail spacer makes it read as "at the end").
   */
  #reconcileFollowMode(scrollable: MessageScrollerScrollable): void {
    const scrollTop = this.viewport?.scrollTop ?? 0
    // Content growing past the live edge also reads as "not at the end", but only a scroll up
    // moves scrollTop up; growth must not release following.
    const scrolledUp = scrollTop < this.#lastScrollTop - SCROLL_POSITION_EPSILON
    this.#lastScrollTop = scrollTop
    if (
      this.#autoScroll &&
      !scrollable.end &&
      this.#spacerHeight === 0 &&
      this.#mode !== 'settling-jump' &&
      this.#mode !== 'anchored-to-message'
    ) {
      this.#mode = 'following-bottom'
    } else if (
      this.#mode === 'following-bottom' &&
      scrollable.end &&
      scrolledUp &&
      !this.#autoscrolling
    ) {
      this.#mode = 'free-scrolling'
    }
  }

  #commitScrollState(): void {
    if (this.#destroyed) return
    const next = getMessageScrollerScrollable({
      content: this.content,
      scrollEdgeThreshold: this.#scrollEdgeThreshold,
      spacer: this.spacer,
      viewport: this.viewport,
    })
    this.#reconcileFollowMode(next)
    // While following, the scroller is already closing any gap a streamed chunk opened, so
    // showing "more below" would flash the scroll button once per chunk.
    const published = this.#mode === 'following-bottom' ? { ...next, end: false } : next
    this.#writeStateAttributes(published)
    // A command can run while a template renders (a part's modifier calls one): the tracked
    // value changes after it.
    this.#afterRender(() => {
      if (!sameScrollable(this.scrollable, published)) this.scrollable = published
    })
  }

  #scheduleStateCommit(): void {
    this.#stateFrame.request(() => this.#commitScrollState())
  }

  #setAutoScrolling(autoscrolling: boolean): void {
    if (this.#autoscrollingTimeout !== null) {
      clearTimeout(this.#autoscrollingTimeout)
      this.#autoscrollingTimeout = null
      waiter.endAsync(this.#autoscrollingToken)
      this.#autoscrollingToken = null
    }
    if (this.#autoscrolling !== autoscrolling) {
      this.#autoscrolling = autoscrolling
      this.#commitScrollState()
    }
    if (autoscrolling) {
      this.#autoscrollingToken = waiter.beginAsync()
      this.#autoscrollingTimeout = setTimeout(() => {
        this.#autoscrollingTimeout = null
        const token = this.#autoscrollingToken
        this.#autoscrollingToken = null
        this.#autoscrolling = false
        this.#commitScrollState()
        waiter.endAsync(token)
      }, AUTOSCROLLING_CLEAR_DELAY)
    }
  }

  /**
   * Writes the tail spacer's height (hidden at zero). It moves nothing: it makes room below an
   * anchored turn, and gives it back as a reply fills it.
   */
  #setTailSpacerHeight(height: number): void {
    const spacer = this.spacer
    if (!spacer) return
    const next = Math.max(0, Math.ceil(height))
    if (this.#spacerHeight === next) return
    this.#spacerHeight = next
    spacer.hidden = next === 0
    spacer.style.height = `${next}px`
    spacer.style.marginTop = next > 0 ? `${-this.#spacerGap}px` : ''
  }

  #scrollToPosition(
    scrollTop: number,
    {
      behavior = 'auto',
      autoscrolling = false,
    }: { behavior?: ScrollBehavior; autoscrolling?: boolean } = {},
  ): void {
    const viewport = this.viewport
    if (!viewport) return
    const next = Math.max(0, scrollTop)
    if (Math.abs(viewport.scrollTop - next) <= SCROLL_POSITION_EPSILON) {
      viewport.scrollTop = next
      this.#commitScrollState()
      return
    }
    viewport.scrollTo({ top: next, behavior })
    // Upstream marks the scroll before it starts; after, an instant scroll's state is already
    // where it lands, so the button doesn't flash in for the frame before it.
    if (autoscrolling) this.#setAutoScrolling(true)
    if (behavior === 'smooth') {
      // A smooth scroll takes a while to start and to end: tests wait for both.
      const token = waiter.beginAsync()
      void scrollEnd(viewport, { top: next }).then(() => waiter.endAsync(token))
    }
    this.#scheduleStateCommit()
  }

  #scrollToElement(
    element: HTMLElement,
    {
      align = 'start',
      behavior = 'auto',
      scrollMargin = this.#scrollMargin,
    }: MessageScrollerScrollOptions = {},
    { keepPreviousPeek = false }: { keepPreviousPeek?: boolean } = {},
  ): boolean {
    const content = this.content
    const viewport = this.viewport
    if (!content || !viewport || !content.contains(element)) return false
    const scrollTop = getElementScrollTop({
      align,
      element,
      scrollMargin: keepPreviousPeek ? scrollMargin + this.#scrollPreviousItemPeek : scrollMargin,
      spacer: this.spacer,
      viewport,
    })
    this.#setTailSpacerHeight(
      getTailSpacerHeight({ content, scrollTop, spacer: this.spacer, viewport }),
    )
    // Seed the prepend anchor with the target, so a prepend that lands before this scroll
    // settles still keeps it in place; once it settles, the scroll handler re-captures the
    // first visible row.
    this.#prependRestore = { element, viewportTop: getElementViewportTop(element, viewport) }
    this.#mode = keepPreviousPeek ? 'anchored-to-message' : 'settling-jump'
    this.#streamingTurn = keepPreviousPeek ? element : null
    this.#scrollToPosition(scrollTop, { behavior })
    this.#scheduleVisibilitySync()
    return true
  }

  #reanchorToAnchoredMessage(): boolean {
    const element = this.#streamingTurn
    if (!element || !element.isConnected || this.#mode !== 'anchored-to-message') return false
    // Place it again, so the spacer fits the new content height and the turn stays put.
    return this.#scrollToElement(element, { align: 'start' }, { keepPreviousPeek: true })
  }

  #flushPendingScrollToMessage(): boolean {
    const pending = this.#pendingScrollToMessage
    if (!pending) return false
    const element = this.#messageElements.get(pending.messageId)
    if (!element) return false
    if (!this.#scrollToElement(element, pending.options)) return false
    this.#pendingScrollToMessage = null
    this.#markDefaultScrollPositionApplied()
    return true
  }

  #schedulePendingScrollToMessageFlush(): void {
    this.#pendingScrollFrame.request(() => {
      if (this.#flushPendingScrollToMessage()) this.#capturePrependAnchor()
    })
  }

  #markDefaultScrollPositionApplied(): void {
    this.#defaultScrollPositionApplied = true
    this.#clearPendingDefaultScroll()
  }

  #clearPendingDefaultScroll(): void {
    if (!this.pendingDefaultScroll) return
    // Never during the render that registered a part: a template has read it.
    this.#afterRender(() => (this.pendingDefaultScroll = false))
  }

  #applyDefaultScrollPosition(): boolean {
    const position = this.#defaultScrollPosition
    if (this.#defaultScrollPositionApplied || this.#itemCount === 0) return false
    let handled: boolean
    if (position === 'last-anchor') {
      const content = this.content
      const viewport = this.viewport
      const anchor =
        content && viewport
          ? getLastScrollAnchor(getMessageScrollerItems(content, this.spacer))
          : null
      if (!content || !viewport || !anchor) {
        handled = this.scrollToEnd({ behavior: 'auto' })
      } else {
        const anchorTop = getElementTop(anchor, viewport)
        const contentBottom = getContentBottom({ content, spacer: this.spacer, viewport })
        // A short last turn fits below its anchor, so the end shows all of it with no gap.
        const lastTurnFits = contentBottom - anchorTop <= viewport.clientHeight
        handled = lastTurnFits
          ? this.scrollToEnd({ behavior: 'auto' })
          : this.#scrollToElement(anchor, { align: 'start' }, { keepPreviousPeek: true })
      }
    } else {
      handled =
        position === 'end'
          ? this.scrollToEnd({ behavior: 'auto' })
          : this.scrollToStart({ behavior: 'auto' })
    }
    if (!handled) return false
    this.#markDefaultScrollPositionApplied()
    return true
  }

  // The order of the branches matters: first rows, prepended, appended, updated in place.
  #reconcileScrollPosition(
    items: HTMLElement[],
    previousItemCount: number,
    previousFirstItem: HTMLElement | null,
  ): void {
    if (this.#flushPendingScrollToMessage()) return

    if (previousItemCount === 0) {
      if (this.#applyDefaultScrollPosition()) return
      if (items.length > 0 && this.#autoScroll && this.scrollToEnd({ behavior: 'auto' })) return
      this.#commitScrollState()
      this.#scheduleVisibilitySync()
      return
    }

    const previousFirstItemIndex = previousFirstItem ? items.indexOf(previousFirstItem) : -1
    if (this.preserveScrollOnPrepend && previousFirstItemIndex > 0) {
      // Prepended rows are history, not new turns: keep the reader where they were. A no-op
      // where the browser's own scroll anchoring already did it.
      this.#restorePrependedAnchor()
      return
    }

    if (items.length > previousItemCount) {
      const anchor = getNewScrollAnchor(items, previousItemCount)
      if (anchor) {
        // While following the end, a batch of several anchored turns arriving at once keeps
        // following, rather than pulling back to the first of them. One new anchor moves to the
        // top as usual.
        if (
          this.#autoScroll &&
          this.#mode === 'following-bottom' &&
          hasMultipleNewScrollAnchors(items, previousItemCount)
        ) {
          this.scrollToEnd({ behavior: 'auto' })
          return
        }
        this.#scrollToElement(anchor, { align: 'start' }, { keepPreviousPeek: true })
        this.#handledScrollAnchors.add(anchor)
        return
      }
    }

    if (items.length === previousItemCount) {
      const anchor = getUnanchoredScrollAnchor(items, this.#handledScrollAnchors)
      if (anchor) {
        this.#scrollToElement(anchor, { align: 'start' }, { keepPreviousPeek: true })
        this.#handledScrollAnchors.add(anchor)
        return
      }
    }

    // Appends with no new anchor, and updates in place: keep following the end if it still
    // is, else just commit the state.
    if (this.#mode === 'following-bottom' && this.#autoScroll) {
      this.scrollToEnd({ behavior: 'auto' })
    } else {
      this.#commitScrollState()
      this.#scheduleVisibilitySync()
    }
  }

  #restorePrependedAnchor(): boolean {
    const anchor = this.#prependRestore
    const viewport = this.viewport
    if (!anchor || !viewport || !anchor.element.isConnected) return false
    // Compared within the viewport, not the content: where the browser's scroll anchoring
    // already kept the row in place, this changes nothing, and it corrects the scroll where it
    // didn't (Safari), without trusting a capability flag.
    const delta = getElementViewportTop(anchor.element, viewport) - anchor.viewportTop
    if (Math.abs(delta) <= SCROLL_POSITION_EPSILON) return false
    viewport.scrollTop += delta
    anchor.viewportTop = getElementViewportTop(anchor.element, viewport)
    this.#scheduleStateCommit()
    this.#scheduleVisibilitySync()
    return true
  }

  #capturePrependAnchor(): void {
    const content = this.content
    const viewport = this.viewport
    if (!content || !viewport) {
      this.#prependRestore = null
      return
    }
    const anchor = getFirstVisibleMessageItem({ content, spacer: this.spacer, viewport })
    this.#prependRestore = anchor
      ? { element: anchor, viewportTop: getElementViewportTop(anchor, viewport) }
      : null
  }

  /**
   * A scroll by the reader during an anchored stream lets go of the anchor and strands the
   * spacer it had reserved. Drain it: as the reply grows, or as the reader scrolls to the real
   * bottom, shrink it toward zero without moving the reader, and hand back to following once
   * it's gone. `true` when it drained to zero and following took over. It leaves the spacer
   * alone during a programmatic scroll, and while the reader is above it.
   */
  #drainReleasedSpacer(): boolean {
    if (
      !this.#autoScroll ||
      this.#spacerHeight <= 0 ||
      this.#mode === 'following-bottom' ||
      this.#mode === 'anchored-to-message' ||
      this.#mode === 'settling-jump' ||
      this.#autoscrolling
    ) {
      return false
    }
    const viewport = this.viewport
    const content = this.content
    if (!viewport || !content) return false
    const contentBottom = getContentBottom({ content, spacer: this.spacer, viewport })
    const viewportBottom = viewport.scrollTop + viewport.clientHeight
    // How far the reader has scrolled into the spacer: none while they are above it.
    if (viewportBottom - contentBottom <= 0) return false
    // From the geometry each time, so it converges instead of overshooting across a fling.
    const next = Math.max(0, contentBottom + this.#spacerHeight - viewportBottom)
    if (next === 0) {
      this.scrollToEnd({ behavior: 'auto' })
      return true
    }
    this.#setTailSpacerHeight(next)
    return false
  }

  // ----- Lifecycle ----------------------------------------------------------------------------

  /**
   * After the render that registered a part: apply the opening position (or, with no rows,
   * stop holding the viewport hidden), as upstream's provider does in a layout effect.
   */
  #scheduleMount(): void {
    if (this.#mountScheduled) return
    this.#mountScheduled = true
    this.#afterRender(() => {
      this.#mountScheduled = false
      if (!this.content || !this.viewport) return
      // The content's rows first, as upstream's content does in its own layout effect, which
      // runs before the provider's.
      if (this.#contentRendered) {
        this.#contentRendered = false
        const applied = this.#defaultScrollPositionApplied
        this.handleContentChange()
        if (!applied && this.#defaultScrollPositionApplied) return
      }
      if (this.#applyDefaultScrollPosition()) return
      if (this.#itemCount === 0) this.#clearPendingDefaultScroll()
      if (this.#autoScroll && this.#mode === 'following-bottom' && this.#itemCount > 0) {
        this.scrollToEnd({ behavior: 'auto' })
        return
      }
      this.#commitScrollState()
    })
  }

  /**
   * Runs `callback` once the current render is over (a microtask), held by the test waiter.
   * Registration happens while rendering, when a tracked value the template has read can't
   * change.
   */
  #afterRender(callback: () => void): void {
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      try {
        if (!this.#destroyed) callback()
      } finally {
        waiter.endAsync(token)
      }
    })
  }

  /** Stops everything it scheduled. The provider calls it when it goes. */
  destroy(): void {
    this.#destroyed = true
    this.#stateFrame.cancel()
    this.#visibilityFrame.cancel()
    this.#pendingScrollFrame.cancel()
    this.#resizeFrame.cancel()
    if (this.#autoscrollingTimeout !== null) {
      clearTimeout(this.#autoscrollingTimeout)
      this.#autoscrollingTimeout = null
      waiter.endAsync(this.#autoscrollingToken)
      this.#autoscrollingToken = null
    }
    this.#visibilityObserver?.disconnect()
    this.#visibilityObserver = null
  }
}
