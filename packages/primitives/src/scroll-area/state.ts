import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import Modifier from 'ember-modifier'
import { getDirection, type Direction } from '../direction.gts'
import { resizeObserver, type ResizeObservers } from '../resize-observer.ts'

const waiter = buildWaiter('@ember-joinery/primitives:scroll-area')

/**
 * When the scrollbars show, as in Radix: while the pointer is over the area (`hover`, the
 * default), while it scrolls (`scroll`), whenever the content overflows (`auto`), or always
 * (`always`). Except with `always`, a scrollbar shows only when its content overflows.
 */
export type ScrollAreaType = 'hover' | 'scroll' | 'auto' | 'always'

/** Which way a scrollbar scrolls. */
export type ScrollAreaOrientation = 'vertical' | 'horizontal'

/** What a scroll area takes. Each is a function, so it reads them live. */
export interface ScrollAreaOptions {
  /** Default `hover`. */
  type?: () => ScrollAreaType | undefined
  /** How long a scrollbar stays after the pointer leaves or the scrolling stops, in ms. Default 600. */
  scrollHideDelay?: () => number | undefined
  /** The text direction, when the document's shouldn't decide. */
  dir?: () => Direction | undefined
}

/** A scrollbar's measurements, as Radix keeps them. */
export interface ScrollbarSizes {
  /** The content's length along the scrollbar (`scrollHeight` or `scrollWidth`). */
  content: number
  /** The viewport's (`offsetHeight` or `offsetWidth`). */
  viewport: number
  scrollbar: { size: number; paddingStart: number; paddingEnd: number }
}

const EMPTY: ScrollbarSizes = {
  content: 0,
  viewport: 0,
  scrollbar: { size: 0, paddingStart: 0, paddingEnd: 0 },
}

/** The `scroll` type's states, as Radix's machine has them. */
type ScrollState = 'hidden' | 'scrolling' | 'interacting' | 'idle'

function clamp(value: number, [min, max]: [number, number]): number {
  return Math.min(max, Math.max(min, value))
}

function linearScale(input: [number, number], output: [number, number]) {
  return (value: number): number => {
    if (input[0] === input[1] || output[0] === output[1]) return output[0]
    const ratio = (output[1] - output[0]) / (input[1] - input[0])
    return output[0] + ratio * (value - input[0])
  }
}

/** The thumb's share of the track: what the viewport shows of the content. */
export function thumbRatio(sizes: ScrollbarSizes): number {
  const ratio = sizes.viewport / sizes.content
  return Number.isNaN(ratio) ? 0 : ratio
}

/** The thumb's length in pixels: its share of the track, and at least 18. */
export function thumbSize(sizes: ScrollbarSizes): number {
  const padding = sizes.scrollbar.paddingStart + sizes.scrollbar.paddingEnd
  return Math.max((sizes.scrollbar.size - padding) * thumbRatio(sizes), 18)
}

/** Where to scroll for a pointer at `position` along the track, as Radix works it out. */
export function scrollFromPointer(
  position: number,
  pointerOffset: number,
  sizes: ScrollbarSizes,
  dir: Direction = 'ltr',
): number {
  const thumb = thumbSize(sizes)
  const offset = pointerOffset || thumb / 2
  const fromEnd = thumb - offset
  const min = sizes.scrollbar.paddingStart + offset
  const max = sizes.scrollbar.size - sizes.scrollbar.paddingEnd - fromEnd
  const maxScroll = sizes.content - sizes.viewport
  const range: [number, number] = dir === 'ltr' ? [0, maxScroll] : [-maxScroll, 0]
  return linearScale([min, max], range)(position)
}

/** How far along the track the thumb sits for a scroll position, as Radix works it out. */
export function thumbOffset(scroll: number, sizes: ScrollbarSizes, dir: Direction = 'ltr'): number {
  const thumb = thumbSize(sizes)
  const padding = sizes.scrollbar.paddingStart + sizes.scrollbar.paddingEnd
  const track = sizes.scrollbar.size - padding
  const maxScroll = sizes.content - sizes.viewport
  const maxThumb = track - thumb
  const range: [number, number] = dir === 'ltr' ? [0, maxScroll] : [-maxScroll, 0]
  return linearScale([0, maxScroll], [0, maxThumb])(clamp(scroll, range))
}

function style(element: HTMLElement, property: string, value: string | null): void {
  if (value === null) element.style.removeProperty(property)
  else if (element.style.getPropertyValue(property) !== value)
    element.style.setProperty(property, value)
}

/** A timer the tests wait for. */
function later(callback: () => void, delay: number): () => void {
  const token = waiter.beginAsync()
  const timer = setTimeout(() => {
    waiter.endAsync(token)
    callback()
  }, delay)
  return () => {
    clearTimeout(timer)
    waiter.endAsync(token)
  }
}

/** One orientation's scrollbar: how many are mounted, its elements and its state. */
export class ScrollbarState {
  readonly orientation: ScrollAreaOrientation
  readonly #area: ScrollAreaState
  /** Scrollbar components of this orientation mounted (shown or not). */
  mounted = 0
  element: HTMLElement | null = null
  thumb: HTMLElement | null = null
  /** Where in the thumb the pointer took hold of it, along the track. */
  pointerOffset = 0
  /** The track's box while the pointer drags in it. */
  rect: DOMRect | null = null

  @tracked sizes: ScrollbarSizes = EMPTY
  /** Whether the content overflows this way. */
  @tracked overflowing = false
  @tracked scrollState: ScrollState = 'hidden'

  #cancelHide: (() => void) | undefined
  #cancelScrollEnd: (() => void) | undefined

  constructor(area: ScrollAreaState, orientation: ScrollAreaOrientation) {
    this.#area = area
    this.orientation = orientation
  }

  get horizontal(): boolean {
    return this.orientation === 'horizontal'
  }

  /** Whether the thumb shows: the viewport shows some, not all, of the content. */
  get hasThumb(): boolean {
    const ratio = thumbRatio(this.sizes)
    return ratio > 0 && ratio < 1
  }

  /** Whether the scrollbar shows now, for the area's `type`. */
  get isVisible(): boolean {
    switch (this.#area.type) {
      case 'always':
        return true
      case 'auto':
        return this.overflowing
      case 'scroll':
        return this.scrollState !== 'hidden'
      case 'hover':
        return this.#area.hovered && this.overflowing
    }
  }

  /** The `scroll` type's machine: Radix's, event by event. */
  send(event: 'SCROLL' | 'SCROLL_END' | 'POINTER_ENTER' | 'POINTER_LEAVE' | 'HIDE'): void {
    const machine: Record<ScrollState, Partial<Record<typeof event, ScrollState>>> = {
      hidden: { SCROLL: 'scrolling' },
      scrolling: { SCROLL_END: 'idle', POINTER_ENTER: 'interacting' },
      interacting: { SCROLL: 'interacting', POINTER_LEAVE: 'idle' },
      idle: { HIDE: 'hidden', SCROLL: 'scrolling', POINTER_ENTER: 'interacting' },
    }
    const next = machine[this.scrollState][event]
    if (!next || next === this.scrollState) return
    this.scrollState = next
    this.#cancelHide?.()
    this.#cancelHide = undefined
    if (next === 'idle') {
      this.#cancelHide = later(() => this.send('HIDE'), this.#area.scrollHideDelay)
    }
  }

  /** The viewport scrolled this way: the machine hears it, and the end of it 100ms later. */
  scrolled(): void {
    this.send('SCROLL')
    this.#cancelScrollEnd?.()
    this.#cancelScrollEnd = later(() => {
      this.#cancelScrollEnd = undefined
      this.send('SCROLL_END')
    }, 100)
  }

  /** @internal */
  teardown(): void {
    this.#cancelHide?.()
    this.#cancelScrollEnd?.()
  }
}

/**
 * The engine of a scroll area, as Radix's `ScrollArea`: a viewport that scrolls natively with
 * its own scrollbars hidden, and scrollbars of the page's own drawing, each with a thumb that
 * tracks the scroll position and can be dragged, a track that scrolls where it is pressed, and
 * the wheel over it scrolling the viewport.
 *
 * `<ScrollArea>` makes one and gives it to its parts. Its modifiers put each part on an
 * element: `root`, `viewport`, `content` (the box inside the viewport), `scrollbar`, `thumb`
 * and `corner`.
 */
export class ScrollAreaState {
  readonly #options: ScrollAreaOptions
  readonly #observers: ResizeObservers
  root: HTMLElement | null = null
  viewport: HTMLElement | null = null
  content: HTMLElement | null = null
  corner: HTMLElement | null = null
  readonly vertical: ScrollbarState
  readonly horizontal: ScrollbarState

  /** Whether the pointer is over the area (for the `hover` type, until the hide delay is up). */
  @tracked hovered = false
  @tracked private cornerSize = { width: 0, height: 0 }
  @tracked private bothMounted = false

  #cancelHoverHide: (() => void) | undefined
  #scheduled = false
  #destroyed = false

  constructor(context: object, options: ScrollAreaOptions = {}) {
    this.#options = options
    this.#observers = resizeObserver(context)
    this.vertical = new ScrollbarState(this, 'vertical')
    this.horizontal = new ScrollbarState(this, 'horizontal')
    registerDestructor(context, () => {
      this.#destroyed = true
      this.#cancelHoverHide?.()
      this.vertical.teardown()
      this.horizontal.teardown()
    })
  }

  get type(): ScrollAreaType {
    return this.#options.type?.() ?? 'hover'
  }

  get scrollHideDelay(): number {
    return this.#options.scrollHideDelay?.() ?? 600
  }

  /** The text direction at the area. */
  get dir(): Direction {
    return getDirection(this.root, this.#options.dir?.())
  }

  scrollbar(orientation: ScrollAreaOrientation): ScrollbarState {
    return orientation === 'horizontal' ? this.horizontal : this.vertical
  }

  /** Whether the corner shows: both scrollbars are there, and the type isn't `scroll`. */
  get hasCorner(): boolean {
    return this.type !== 'scroll' && this.bothMounted
  }

  /** The corner's size: the vertical scrollbar's width and the horizontal one's height. */
  get cornerWidth(): number {
    return this.cornerSize.width
  }

  get cornerHeight(): number {
    return this.cornerSize.height
  }

  // ----- Lifecycle ---------------------------------------------------------------------------

  /** Measures and lays out again after the render: elements came or went. */
  changed(): void {
    if (this.#scheduled) return
    this.#scheduled = true
    // After the render that brought the change, and before the browser paints: the parts come
    // before the area itself, and measuring writes tracked state, which the render can't.
    const token = waiter.beginAsync()
    queueMicrotask(() => {
      waiter.endAsync(token)
      this.#flush()
    })
  }

  #flush(): void {
    this.#scheduled = false
    if (this.#destroyed) return
    this.#applyViewport()
    // Placed now, not as each part comes: the parts come before the area itself, and the
    // direction is the area's.
    for (const bar of [this.vertical, this.horizontal]) {
      if (bar.element) this.#placeScrollbar(bar, bar.element)
    }
    if (this.corner) this.#placeCorner(this.corner)
    this.#measure()
    const both = Boolean(this.vertical.element && this.horizontal.element)
    if (both !== this.bothMounted) this.bothMounted = both
  }

  /** The viewport scrolls the ways it has a scrollbar for, and its own scrollbars stay hidden. */
  #applyViewport(): void {
    const viewport = this.viewport
    if (!viewport) return
    style(viewport, 'overflow-x', this.horizontal.mounted > 0 ? 'scroll' : 'hidden')
    style(viewport, 'overflow-y', this.vertical.mounted > 0 ? 'scroll' : 'hidden')
    style(viewport, 'scrollbar-width', 'none')
  }

  /** Measures the content against the viewport, and sizes and places each thumb. */
  #measure = (): void => {
    const viewport = this.viewport
    if (!viewport) return
    for (const bar of [this.vertical, this.horizontal]) {
      const overflowing = bar.horizontal
        ? viewport.offsetWidth < viewport.scrollWidth
        : viewport.offsetHeight < viewport.scrollHeight
      if (overflowing !== bar.overflowing) bar.overflowing = overflowing
      const element = bar.element
      if (!element) continue
      const computed = getComputedStyle(element)
      const sizes: ScrollbarSizes = bar.horizontal
        ? {
            content: viewport.scrollWidth,
            viewport: viewport.offsetWidth,
            scrollbar: {
              size: element.clientWidth,
              paddingStart: parseInt(computed.paddingLeft, 10) || 0,
              paddingEnd: parseInt(computed.paddingRight, 10) || 0,
            },
          }
        : {
            content: viewport.scrollHeight,
            viewport: viewport.offsetHeight,
            scrollbar: {
              size: element.clientHeight,
              paddingStart: parseInt(computed.paddingTop, 10) || 0,
              paddingEnd: parseInt(computed.paddingBottom, 10) || 0,
            },
          }
      if (JSON.stringify(sizes) !== JSON.stringify(bar.sizes)) bar.sizes = sizes
      style(
        element,
        bar.horizontal ? '--radix-scroll-area-thumb-width' : '--radix-scroll-area-thumb-height',
        `${thumbSize(sizes)}px`,
      )
      this.#placeThumb(bar)
    }
    this.#measureCorner()
  }

  #measureCorner(): void {
    const width = this.vertical.element?.offsetWidth ?? 0
    const height = this.horizontal.element?.offsetHeight ?? 0
    const corner = this.hasCornerNow ? { width, height } : { width: 0, height: 0 }
    if (corner.width !== this.cornerSize.width || corner.height !== this.cornerSize.height)
      this.cornerSize = corner
    if (this.root) {
      style(this.root, '--radix-scroll-area-corner-width', `${corner.width}px`)
      style(this.root, '--radix-scroll-area-corner-height', `${corner.height}px`)
    }
    const element = this.corner
    if (element) {
      style(element, 'width', `${width}px`)
      style(element, 'height', `${height}px`)
    }
  }

  get hasCornerNow(): boolean {
    return this.type !== 'scroll' && Boolean(this.vertical.element && this.horizontal.element)
  }

  #placeThumb(bar: ScrollbarState): void {
    const viewport = this.viewport
    const thumb = bar.thumb
    if (!viewport || !thumb) return
    if (bar.horizontal) {
      const offset = thumbOffset(viewport.scrollLeft, bar.sizes, this.dir)
      style(thumb, 'transform', `translate3d(${offset}px, 0, 0)`)
    } else {
      const offset = thumbOffset(viewport.scrollTop, bar.sizes)
      style(thumb, 'transform', `translate3d(0, ${offset}px, 0)`)
    }
  }

  // ----- Events ------------------------------------------------------------------------------

  #lastScroll = { left: 0, top: 0 }

  #onScroll = (): void => {
    const viewport = this.viewport
    if (!viewport) return
    const { scrollLeft: left, scrollTop: top } = viewport
    if (left !== this.#lastScroll.left) this.horizontal.scrolled()
    if (top !== this.#lastScroll.top) this.vertical.scrolled()
    this.#lastScroll = { left, top }
    this.#placeThumb(this.vertical)
    this.#placeThumb(this.horizontal)
  }

  #onPointerEnter = (): void => {
    this.#cancelHoverHide?.()
    this.#cancelHoverHide = undefined
    if (!this.hovered) this.hovered = true
  }

  #onPointerLeave = (): void => {
    this.#cancelHoverHide?.()
    this.#cancelHoverHide = later(() => {
      this.#cancelHoverHide = undefined
      this.hovered = false
    }, this.scrollHideDelay)
  }

  /** A drag in the track (or of the thumb): scroll to where the pointer is. */
  #dragScroll(bar: ScrollbarState, event: PointerEvent): void {
    const viewport = this.viewport
    const rect = bar.rect
    const element = bar.element
    if (!viewport || !rect || !element) return
    // The pointer's pixels are the screen's; the sizes are CSS pixels, which a transform on the
    // page (a zoom, a scale) makes differ.
    if (bar.horizontal) {
      const scale = rect.width ? element.offsetWidth / rect.width : 1
      viewport.scrollLeft = scrollFromPointer(
        (event.clientX - rect.left) * scale,
        bar.pointerOffset,
        bar.sizes,
        this.dir,
      )
    } else {
      const scale = rect.height ? element.offsetHeight / rect.height : 1
      viewport.scrollTop = scrollFromPointer(
        (event.clientY - rect.top) * scale,
        bar.pointerOffset,
        bar.sizes,
      )
    }
  }

  // ----- Parts -------------------------------------------------------------------------------

  /** @internal The area's element. */
  attachRoot(element: HTMLElement): () => void {
    this.root = element
    element.style.setProperty('position', 'relative')
    element.addEventListener('pointerenter', this.#onPointerEnter)
    element.addEventListener('pointerleave', this.#onPointerLeave)
    this.changed()
    return () => {
      element.removeEventListener('pointerenter', this.#onPointerEnter)
      element.removeEventListener('pointerleave', this.#onPointerLeave)
      this.root = null
    }
  }

  /** @internal */
  attachViewport(element: HTMLElement): () => void {
    this.viewport = element
    this.#lastScroll = { left: element.scrollLeft, top: element.scrollTop }
    element.addEventListener('scroll', this.#onScroll, { passive: true })
    this.#observers.observe(element, this.#measure)
    this.changed()
    return () => {
      element.removeEventListener('scroll', this.#onScroll)
      this.#observers.unobserve(element, this.#measure)
      if (this.viewport === element) this.viewport = null
    }
  }

  /** @internal */
  attachContent(element: HTMLElement): () => void {
    this.content = element
    element.style.setProperty('min-width', '100%')
    element.style.setProperty('display', 'table')
    this.#observers.observe(element, this.#measure)
    this.changed()
    return () => {
      this.#observers.unobserve(element, this.#measure)
      if (this.content === element) this.content = null
    }
  }

  /** @internal A scrollbar component of this orientation came (shown or not). */
  mountScrollbar(orientation: ScrollAreaOrientation): () => void {
    const bar = this.scrollbar(orientation)
    bar.mounted += 1
    this.changed()
    return () => {
      bar.mounted -= 1
      this.changed()
    }
  }

  /** @internal The scrollbar's element, while it shows. */
  attachScrollbar(bar: ScrollbarState, element: HTMLElement): () => void {
    bar.element = element
    const document = element.ownerDocument
    this.#placeScrollbar(bar, element)
    let previousUserSelect = ''

    const onPointerDown = (event: PointerEvent) => {
      if (event.button !== 0) return
      const target = event.target as Element
      try {
        target.setPointerCapture(event.pointerId)
      } catch {
        // An event a test made has no pointer to capture.
      }
      bar.rect = element.getBoundingClientRect()
      previousUserSelect = document.body.style.webkitUserSelect
      document.body.style.webkitUserSelect = 'none'
      if (this.viewport) this.viewport.style.scrollBehavior = 'auto'
      this.#dragScroll(bar, event)
    }
    const onPointerMove = (event: PointerEvent) => this.#dragScroll(bar, event)
    const onPointerUp = (event: PointerEvent) => {
      const target = event.target as Element
      try {
        if (target.hasPointerCapture(event.pointerId)) target.releasePointerCapture(event.pointerId)
      } catch {
        // As above.
      }
      document.body.style.webkitUserSelect = previousUserSelect
      if (this.viewport) this.viewport.style.scrollBehavior = ''
      bar.rect = null
    }
    const onPointerEnter = () => bar.send('POINTER_ENTER')
    const onPointerLeave = () => bar.send('POINTER_LEAVE')
    // The wheel over the scrollbar scrolls the viewport; the page doesn't scroll while the
    // viewport still can.
    const onWheel = (event: WheelEvent) => {
      const viewport = this.viewport
      if (!viewport || !element.contains(event.target as Node)) return
      const max = bar.sizes.content - bar.sizes.viewport
      const position = bar.horizontal
        ? viewport.scrollLeft + event.deltaX
        : viewport.scrollTop + event.deltaY
      if (bar.horizontal) viewport.scrollLeft = position
      else viewport.scrollTop = position
      if (position > 0 && position < max) event.preventDefault()
    }

    element.addEventListener('pointerdown', onPointerDown)
    element.addEventListener('pointermove', onPointerMove)
    element.addEventListener('pointerup', onPointerUp)
    element.addEventListener('pointerenter', onPointerEnter)
    element.addEventListener('pointerleave', onPointerLeave)
    document.addEventListener('wheel', onWheel, { passive: false })
    this.#observers.observe(element, this.#measure)
    this.changed()
    return () => {
      element.removeEventListener('pointerdown', onPointerDown)
      element.removeEventListener('pointermove', onPointerMove)
      element.removeEventListener('pointerup', onPointerUp)
      element.removeEventListener('pointerenter', onPointerEnter)
      element.removeEventListener('pointerleave', onPointerLeave)
      document.removeEventListener('wheel', onWheel)
      this.#observers.unobserve(element, this.#measure)
      if (bar.element === element) bar.element = null
      this.changed()
    }
  }

  /** @internal Puts a scrollbar along its edge, past the corner, on the side the text ends. */
  updateScrollbar(bar: ScrollbarState): void {
    if (bar.element) this.#placeScrollbar(bar, bar.element)
  }

  #placeScrollbar(bar: ScrollbarState, element: HTMLElement): void {
    const rtl = this.dir === 'rtl'
    style(element, 'position', 'absolute')
    if (bar.horizontal) {
      style(element, 'bottom', '0px')
      style(element, 'left', rtl ? 'var(--radix-scroll-area-corner-width)' : '0px')
      style(element, 'right', rtl ? '0px' : 'var(--radix-scroll-area-corner-width)')
    } else {
      style(element, 'top', '0px')
      style(element, 'right', rtl ? null : '0px')
      style(element, 'left', rtl ? '0px' : null)
      style(element, 'bottom', 'var(--radix-scroll-area-corner-height)')
    }
  }

  #placeCorner(element: HTMLElement): void {
    const rtl = this.dir === 'rtl'
    style(element, 'position', 'absolute')
    style(element, 'bottom', '0px')
    style(element, 'right', rtl ? null : '0px')
    style(element, 'left', rtl ? '0px' : null)
  }

  /** @internal */
  attachThumb(bar: ScrollbarState, element: HTMLElement): () => void {
    bar.thumb = element
    style(element, 'width', 'var(--radix-scroll-area-thumb-width)')
    style(element, 'height', 'var(--radix-scroll-area-thumb-height)')
    const onPointerDown = (event: PointerEvent) => {
      const box = element.getBoundingClientRect()
      bar.pointerOffset = bar.horizontal
        ? (event.clientX - box.left) * (box.width ? element.offsetWidth / box.width : 1)
        : (event.clientY - box.top) * (box.height ? element.offsetHeight / box.height : 1)
    }
    const onPointerUp = () => (bar.pointerOffset = 0)
    element.addEventListener('pointerdown', onPointerDown, { capture: true })
    element.addEventListener('pointerup', onPointerUp)
    this.#placeThumb(bar)
    return () => {
      element.removeEventListener('pointerdown', onPointerDown, { capture: true })
      element.removeEventListener('pointerup', onPointerUp)
      if (bar.thumb === element) bar.thumb = null
    }
  }

  /** @internal */
  attachCorner(element: HTMLElement): () => void {
    this.corner = element
    this.#placeCorner(element)
    this.#measureCorner()
    this.changed()
    return () => {
      if (this.corner === element) this.corner = null
    }
  }

  // ----- Modifiers ---------------------------------------------------------------------------

  /** The area's element. */
  rootPart: ScrollAreaPartModifier = attach(element => this.attachRoot(element))
  /** The viewport: the element that scrolls. */
  viewportPart: ScrollAreaPartModifier = attach(element => this.attachViewport(element))
  /** The box inside the viewport around the content. */
  contentPart: ScrollAreaPartModifier = attach(element => this.attachContent(element))
  /** The corner between the two scrollbars. */
  cornerPart: ScrollAreaPartModifier = attach(element => this.attachCorner(element))
}

/** A modifier with no arguments that makes its element one of the area's parts. */
export type ScrollAreaPartModifier = typeof Modifier<{ Element: HTMLElement }>

/** A modifier that runs `install` once for its element, and its cleanup when it goes. */
function attach(install: (element: HTMLElement) => () => void): ScrollAreaPartModifier {
  return class AttachModifier extends Modifier<{ Element: HTMLElement }> {
    #installed = false

    override modify(element: HTMLElement): void {
      if (this.#installed) return
      this.#installed = true
      registerDestructor(this, install(element))
    }
  }
}

/** A modifier for a scrollbar's element, or its thumb's. */
export class ScrollbarPart extends Modifier<{
  Element: HTMLElement
  Args: { Positional: [area: ScrollAreaState, bar: ScrollbarState, part: 'scrollbar' | 'thumb'] }
}> {
  #installed = false

  override modify(
    element: HTMLElement,
    [area, bar, part]: [ScrollAreaState, ScrollbarState, 'scrollbar' | 'thumb'],
  ): void {
    if (this.#installed) return
    this.#installed = true
    registerDestructor(
      this,
      part === 'scrollbar' ? area.attachScrollbar(bar, element) : area.attachThumb(bar, element),
    )
  }
}
