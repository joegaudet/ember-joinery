import { assert } from '@ember/debug'
import { buildWaiter, waitForPromise } from '@ember/test-waiters'
import {
  arrow as arrowMiddleware,
  autoUpdate,
  computePosition,
  hide,
  limitShift,
  offset,
  shift,
  size,
  type Middleware,
  type MiddlewareData,
  type Placement,
  type VirtualElement,
} from '@floating-ui/dom'
import { exposeMetadata, flipTo, originFor, transformOrigin, type ArrowSize } from './middleware.ts'
import {
  anchorMode,
  isVertical,
  placementOf,
  resolve,
  sideAndAlign,
  type Align,
  type AnchorData,
  type AnchorMode,
  type AnchorOptions,
  type AnchorReference,
  type ResolvedOptions,
  type Side,
} from './options.ts'

const waiter = buildWaiter('@ember-joinery/primitives:anchor')

/** The custom properties a floating element gets, for its styles to use. */
export const ANCHOR_PROPERTIES = {
  /** The room between the anchor and the viewport's edge, across and along the side. */
  availableWidth: '--jn-anchor-available-width',
  availableHeight: '--jn-anchor-available-height',
  /** The anchor's size, to make a menu as wide as its trigger. */
  width: '--jn-anchor-width',
  height: '--jn-anchor-height',
  /** Where the element grows from: the arrow's tip, or the edge facing the anchor. */
  transformOrigin: '--jn-anchor-transform-origin',
} as const

const OPPOSITE: Record<Side, Side> = { top: 'bottom', right: 'left', bottom: 'top', left: 'right' }

/** Inline styles set on an element, with the values they replaced, to put back afterwards. */
class Styles {
  readonly element: HTMLElement | SVGElement
  readonly #saved = new Map<string, [value: string, priority: string]>()
  readonly #hadAttribute: boolean

  constructor(element: HTMLElement | SVGElement) {
    this.element = element
    this.#hadAttribute = element.hasAttribute('style')
  }

  set(property: string, value: string): void {
    const style = this.element.style
    if (!this.#saved.has(property)) {
      this.#saved.set(property, [
        style.getPropertyValue(property),
        style.getPropertyPriority(property),
      ])
    }
    if (style.getPropertyValue(property) !== value) style.setProperty(property, value)
  }

  /** Puts them back, last set first, so a shorthand (`margin`) goes after its longhands. */
  restore(): void {
    const style = this.element.style
    for (const [property, [value, priority]] of [...this.#saved].reverse()) {
      if (value) style.setProperty(property, value, priority)
      else style.removeProperty(property)
    }
    this.#saved.clear()
    if (!this.#hadAttribute && !style.length) this.element.removeAttribute('style')
  }
}

/** Attributes set on an element, with their old values, to put back afterwards. */
class Attributes {
  readonly element: Element
  readonly #saved = new Map<string, string | null>()

  constructor(element: Element) {
    this.element = element
  }

  set(name: string, value: string): void {
    if (!this.#saved.has(name)) this.#saved.set(name, this.element.getAttribute(name))
    if (this.element.getAttribute(name) !== value) this.element.setAttribute(name, value)
  }

  restore(): void {
    for (const [name, value] of this.#saved) {
      if (value === null) this.element.removeAttribute(name)
      else this.element.setAttribute(name, value)
    }
    this.#saved.clear()
  }
}

function isDisplayed(element: Element): boolean {
  return element.isConnected && element.getClientRects().length > 0
}

function isRTL(element: Element): boolean {
  return getComputedStyle(element).direction === 'rtl'
}

function arrowSizeOf(arrow: HTMLElement | null): ArrowSize {
  return arrow ? { width: arrow.offsetWidth, height: arrow.offsetHeight } : { width: 0, height: 0 }
}

function lookUp(reference: AnchorReference): Element | VirtualElement {
  if (typeof reference !== 'string') return reference
  const found = document.querySelector(reference)
  assert(`Joinery: anchorTo found no element for the selector \`${reference}\``, found)
  return found
}

interface Placed {
  placement: Placement
  x: number
  y: number
  arrow?: MiddlewareData['arrow']
  referenceHidden?: boolean
  available: { width: number; height: number }
  reference: { x: number; y: number; width: number; height: number }
  floating: { width: number; height: number }
  metadata?: AnchorData
}

/** What both modes do once they know where the element went: its data, variables and arrow. */
function applyPlaced(
  floating: HTMLElement,
  resolved: ResolvedOptions,
  placed: Placed,
  mode: AnchorMode,
  styles: Styles,
  attributes: Attributes,
  arrowStyles: Styles | undefined,
  arrowSize: ArrowSize,
): void {
  const [side, align] = sideAndAlign(placed.placement)
  attributes.set('data-side', side)
  attributes.set('data-align', align)

  const origin = originFor(placed.placement, placed.floating, placed.arrow, arrowSize)
  styles.set(ANCHOR_PROPERTIES.availableWidth, `${placed.available.width}px`)
  styles.set(ANCHOR_PROPERTIES.availableHeight, `${placed.available.height}px`)
  styles.set(ANCHOR_PROPERTIES.width, `${placed.reference.width}px`)
  styles.set(ANCHOR_PROPERTIES.height, `${placed.reference.height}px`)
  styles.set(ANCHOR_PROPERTIES.transformOrigin, `${origin.x} ${origin.y}`)

  const arrow = resolved.arrow
  if (arrow && arrowStyles) {
    // As Radix's PopperArrow: on the edge facing the anchor, its bottom towards the anchor.
    const { x, y, centerOffset } = placed.arrow ?? {}
    arrowStyles.set('position', 'absolute')
    arrowStyles.set('left', x != null ? `${x}px` : '')
    arrowStyles.set('top', y != null ? `${y}px` : '')
    arrowStyles.set('right', '')
    arrowStyles.set('bottom', '')
    arrowStyles.set(OPPOSITE[side], '0')
    arrowStyles.set(
      'transform-origin',
      { top: '', right: '0 0', bottom: 'center 0', left: '100% 0' }[side],
    )
    arrowStyles.set(
      'transform',
      {
        top: 'translateY(100%)',
        right: 'translateY(50%) rotate(90deg) translateX(-50%)',
        bottom: 'rotate(180deg)',
        left: 'translateY(50%) rotate(-90deg) translateX(50%)',
      }[side],
    )
    arrowStyles.set('visibility', centerOffset !== 0 ? 'hidden' : '')
  }

  if (resolved.setData) {
    resolved.setData(
      placed.metadata ?? {
        mode,
        x: placed.x,
        y: placed.y,
        placement: placed.placement,
        initialPlacement: placementOf(resolved.side, resolved.align),
        strategy: resolved.strategy,
        middlewareData: {
          ...(placed.arrow ? { arrow: placed.arrow } : {}),
          transformOrigin: origin,
          ...(placed.referenceHidden !== undefined
            ? { hide: { referenceHidden: placed.referenceHidden } }
            : {}),
        },
        rects: {
          reference: placed.reference,
          floating: { x: 0, y: 0, ...placed.floating },
        },
      },
    )
  }
}

/** `position-area` for a side and alignment, in physical terms. */
function positionArea(side: Side, align: Align, rtl: boolean): string {
  if (align === 'center') return side
  if (isVertical(side)) {
    const left = (align === 'start') !== rtl
    return `${side} ${left ? 'span-right' : 'span-left'}`
  }
  return `${side} ${align === 'start' ? 'span-bottom' : 'span-top'}`
}

/** The fallbacks Floating UI's flip tries, in its order, as `position-try-fallbacks`. */
function tryFallbacks(resolved: ResolvedOptions): string {
  if (!resolved.avoidCollisions) return 'none'
  const { mainAxis = true, crossAxis = true, flipAlignment = true } = resolved.flipOptions
  const vertical = isVertical(resolved.side)
  const flipSide = vertical ? 'flip-block' : 'flip-inline'
  const flipAlign = vertical ? 'flip-inline' : 'flip-block'
  const tries: string[] = []
  const aligned = resolved.align !== 'center' && flipAlignment && crossAxis !== false
  if (aligned) tries.push(flipAlign)
  if (mainAxis !== false) tries.push(flipSide)
  if (aligned && mainAxis !== false) tries.push(`${flipSide} ${flipAlign}`)
  return tries.length ? tries.join(', ') : 'none'
}

let anchorNames = 0

/** Adds a name to the reference's `anchor-name` list (it may already anchor other elements). */
function addAnchorName(reference: HTMLElement | SVGElement, name: string): () => void {
  const style = reference.style
  const names = (style.getPropertyValue('anchor-name') || '')
    .split(',')
    .map(each => each.trim())
    .filter(each => each && each !== 'none')
  style.setProperty('anchor-name', [...names, name].join(', '))
  return () => {
    const rest = (style.getPropertyValue('anchor-name') || '')
      .split(',')
      .map(each => each.trim())
      .filter(each => each && each !== name && each !== 'none')
    if (rest.length) style.setProperty('anchor-name', rest.join(', '))
    else style.removeProperty('anchor-name')
  }
}

function viewport(): { width: number; height: number } {
  const root = document.documentElement
  return { width: root.clientWidth, height: root.clientHeight }
}

function paddingOf(padding: ResolvedOptions['padding']) {
  if (typeof padding === 'number') {
    return { top: padding, right: padding, bottom: padding, left: padding }
  }
  return { top: 0, right: 0, bottom: 0, left: 0, ...padding }
}

/**
 * Where CSS anchor positioning put the element: the side its centre is on (after any
 * `position-try` fallback), and the edge it lines up with.
 */
function measurePlacement(
  resolved: ResolvedOptions,
  reference: DOMRect,
  floating: DOMRect,
  rtl: boolean,
): Placement {
  const vertical = isVertical(resolved.side)
  let side: Side
  if (vertical) {
    side =
      floating.top + floating.height / 2 >= reference.top + reference.height / 2 ? 'bottom' : 'top'
  } else {
    side =
      floating.left + floating.width / 2 >= reference.left + reference.width / 2 ? 'right' : 'left'
  }
  let align: Align = resolved.align
  if (align !== 'center') {
    // The edge it lines up with: a fallback may have flipped the alignment.
    const nearStart = vertical
      ? Math.abs(floating.left - reference.left)
      : Math.abs(floating.top - reference.top)
    const nearEnd = vertical
      ? Math.abs(floating.right - reference.right)
      : Math.abs(floating.bottom - reference.bottom)
    if (nearStart !== nearEnd) {
      // For top and bottom, the physical start (left) is the logical end in RTL.
      const physicalStart = nearStart < nearEnd
      align = (vertical && rtl ? !physicalStart : physicalStart) ? 'start' : 'end'
    }
  }
  return placementOf(side, align)
}

/** The arrow's offset along the edge, centred on the anchor and kept off the corners. */
function measureArrow(
  side: Side,
  reference: DOMRect,
  floating: DOMRect,
  arrowSize: ArrowSize,
  padding: number,
): NonNullable<MiddlewareData['arrow']> {
  const vertical = isVertical(side)
  const length = vertical ? arrowSize.width : arrowSize.height
  const extent = vertical ? floating.width : floating.height
  const ideal = vertical
    ? reference.left + reference.width / 2 - floating.left - length / 2
    : reference.top + reference.height / 2 - floating.top - length / 2
  const min = padding
  const max = extent - length - padding
  const clamped = Math.min(Math.max(ideal, min), Math.max(min, max))
  const centerOffset = Math.round(ideal - clamped)
  return vertical ? { x: clamped, centerOffset } : { y: clamped, centerOffset }
}

/**
 * Positions `floating` against `reference` until the returned function is called: with CSS
 * anchor positioning where the browser has it (an `anchor-name` on the reference, and
 * `position-anchor`, `position-area` and `position-try-fallbacks` on the floating element), and
 * with Floating UI's `computePosition` (offset, flip, shift, size, arrow and hide) where it
 * hasn't, where the fallback is forced, or where an option needs Floating UI (see `anchorMode`).
 *
 * Either way the floating element gets `data-side` and `data-align` (where it ended up, after
 * any flip), the `--jn-anchor-*` custom properties (`ANCHOR_PROPERTIES`), and the arrow its
 * place, and `setData` hears where it went. It follows the anchor as the page scrolls and
 * resizes. Everything it set is put back when it stops.
 *
 *   const stop = anchor(menu, trigger, { side: 'bottom', align: 'start', sideOffset: 4 })
 *
 * Tests wait for it: `settled()` resolves once the element is in place.
 */
export function anchor(
  floating: HTMLElement,
  referenceOrSelector: AnchorReference,
  options: AnchorOptions = {},
): () => void {
  const reference = lookUp(referenceOrSelector)
  assert('Joinery: an element can’t be anchored to itself', floating !== reference)
  const resolved = resolve(options)
  const mode = anchorMode(reference, options)
  const styles = new Styles(floating)
  const attributes = new Attributes(floating)
  const arrowStyles = resolved.arrow ? new Styles(resolved.arrow) : undefined

  let stopped = false
  let token: unknown = waiter.beginAsync()
  const ready = () => {
    if (token === undefined) return
    waiter.endAsync(token)
    token = undefined
  }
  // Until the element has a box (a popover is shown once the render is over), keep tests
  // waiting, for a few frames at most.
  let frames = 0
  let frame = 0
  const waitForBox = () => {
    frame = requestAnimationFrame(() => {
      if (stopped || token === undefined) return
      update()
      if (++frames >= 10) ready()
      else if (token !== undefined) waitForBox()
    })
  }

  let update: () => void
  let teardown: () => void

  if (mode === 'css' && reference instanceof Element) {
    const name = `--jn-anchor-${(anchorNames += 1)}`
    const removeName = addAnchorName(reference as HTMLElement, name)
    const rtl = isRTL(floating)
    const { side, align, mainAxis, crossAxis } = resolved

    styles.set('position', resolved.strategy)
    styles.set('inset', 'auto')
    styles.set('margin', '0')
    styles.set('position-anchor', name)
    styles.set('position-area', positionArea(side, align, rtl))
    styles.set('position-try-fallbacks', tryFallbacks(resolved))
    styles.set('position-visibility', resolved.hide ? 'anchors-visible' : 'always')

    update = () => {
      if (stopped || !isDisplayed(floating)) return
      const arrowSize = arrowSizeOf(resolved.arrow)
      // Away from the anchor: the margin on the side facing it. The try fallbacks flip margins
      // with the position, as Floating UI's flip recomputes its offset.
      styles.set(`margin-${OPPOSITE[side]}`, `${mainAxis + arrowSize.height}px`)
      if (crossAxis !== 0) {
        const shift = isVertical(side) ? (rtl ? -crossAxis : crossAxis) : crossAxis
        const startEdge = positionArea(side, align, rtl).includes(
          isVertical(side) ? 'span-right' : 'span-bottom',
        )
        const property = isVertical(side)
          ? startEdge
            ? 'margin-left'
            : 'margin-right'
          : startEdge
            ? 'margin-top'
            : 'margin-bottom'
        styles.set(property, `${startEdge ? shift : -shift}px`)
      }

      const referenceRect = reference.getBoundingClientRect()
      const floatingRect = floating.getBoundingClientRect()
      const placement = measurePlacement(resolved, referenceRect, floatingRect, rtl)
      const [placedSide] = sideAndAlign(placement)
      const room = viewport()
      const padding = paddingOf(resolved.padding)
      const offsetAway = mainAxis + arrowSize.height
      const available = isVertical(placedSide)
        ? {
            width: room.width - padding.left - padding.right,
            height:
              placedSide === 'bottom'
                ? room.height - referenceRect.bottom - offsetAway - padding.bottom
                : referenceRect.top - offsetAway - padding.top,
          }
        : {
            width:
              placedSide === 'right'
                ? room.width - referenceRect.right - offsetAway - padding.right
                : referenceRect.left - offsetAway - padding.left,
            height: room.height - padding.top - padding.bottom,
          }
      applyPlaced(
        floating,
        resolved,
        {
          placement,
          x: floatingRect.left,
          y: floatingRect.top,
          arrow: resolved.arrow
            ? measureArrow(
                placedSide,
                referenceRect,
                floatingRect,
                arrowSize,
                resolved.arrowPadding,
              )
            : undefined,
          available: { width: Math.max(0, available.width), height: Math.max(0, available.height) },
          reference: {
            x: referenceRect.x,
            y: referenceRect.y,
            width: referenceRect.width,
            height: referenceRect.height,
          },
          floating: { width: floatingRect.width, height: floatingRect.height },
        },
        mode,
        styles,
        attributes,
        arrowStyles,
        arrowSize,
      )
      ready()
    }
    const stopUpdates = autoUpdate(reference, floating, update)
    teardown = () => {
      stopUpdates()
      removeName()
    }
  } else {
    styles.set('position', resolved.strategy)
    styles.set('inset', 'auto')
    styles.set('margin', '0')
    styles.set('top', '0')
    styles.set('left', '0')

    let latest = 0
    update = () => {
      if (stopped) return
      const run = (latest += 1)
      const arrowSize = arrowSizeOf(resolved.arrow)
      const padding = resolved.padding
      // size() hands over the room it measured, for the custom properties.
      let available = { width: 0, height: 0 }
      const middleware: Array<Middleware | false> = [
        offset(
          resolved.offset ?? {
            ...resolved.offsetAxes,
            mainAxis: resolved.offsetAxes.mainAxis + arrowSize.height,
          },
        ),
        resolved.avoidCollisions && flipTo({ padding, ...resolved.flipOptions }),
        resolved.avoidCollisions &&
          shift({
            padding,
            limiter: resolved.sticky === 'partial' ? limitShift() : undefined,
            ...resolved.shiftOptions,
          }),
        size({
          padding,
          apply: ({ availableWidth, availableHeight }) => {
            available = { width: availableWidth, height: availableHeight }
          },
        }),
        ...resolved.middleware,
        resolved.arrow !== null &&
          arrowMiddleware({ element: resolved.arrow, padding: resolved.arrowPadding }),
        transformOrigin(arrowSize),
        resolved.hide && hide({ strategy: 'referenceHidden', padding, ...resolved.hideOptions }),
        exposeMetadata(),
      ]

      const done = computePosition(reference, floating, {
        placement: placementOf(resolved.side, resolved.align),
        strategy: resolved.strategy,
        middleware: middleware.filter((each): each is Middleware => each !== false),
      }).then(({ x, y, placement, middlewareData }) => {
        if (stopped || run !== latest) return
        const metadata = middlewareData['metadata'] as AnchorData | undefined
        const rects = metadata?.rects ?? {
          reference: { x: 0, y: 0, width: 0, height: 0 },
          floating: { x: 0, y: 0, width: floating.offsetWidth, height: floating.offsetHeight },
        }
        styles.set('left', `${x}px`)
        styles.set('top', `${y}px`)
        const referenceHidden = middlewareData.hide?.referenceHidden
        if (resolved.hide) styles.set('visibility', referenceHidden ? 'hidden' : '')
        applyPlaced(
          floating,
          resolved,
          {
            placement,
            x,
            y,
            arrow: middlewareData.arrow,
            referenceHidden,
            available,
            reference: rects.reference,
            floating: rects.floating,
            metadata: metadata && {
              ...metadata,
              x,
              y,
              placement,
              middlewareData,
              mode,
            },
          },
          mode,
          styles,
          attributes,
          arrowStyles,
          arrowSize,
        )
        if (isDisplayed(floating)) ready()
      })
      void waitForPromise(done)
    }
    teardown = autoUpdate(reference, floating, update)
  }

  if (token !== undefined) waitForBox()

  return () => {
    if (stopped) return
    stopped = true
    cancelAnimationFrame(frame)
    teardown()
    ready()
    styles.restore()
    attributes.restore()
    arrowStyles?.restore()
  }
}
