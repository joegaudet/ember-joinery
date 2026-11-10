// What Popover, Tooltip and HoverCard share, as Radix's share its Popper: an element kept for
// a part, the options their content is anchored with, its custom properties, its arrow, the
// delays that open and close them, and the pointer's grace area. popover.gts, tooltip.gts and
// hover-card.gts are the public modules; this file is bundled into them.
import { tracked } from '@glimmer/tracking'
import { isDestroyed, isDestroying, registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import type { TOC } from '@ember/component/template-only'
import { modifier } from 'ember-modifier'
import {
  anchor,
  type AnchorData,
  type AnchorFlipOptions,
  type AnchorOptions,
  type Align,
  type Middleware,
  type OffsetOptions,
  type Padding,
  type Placement,
  type ShiftOptions,
  type Side,
  type Strategy,
} from '../anchor/index.ts'

// ----- Elements ------------------------------------------------------------------------------

/**
 * An element a part renders, for the others to use. `current` is set as soon as the element is
 * installed, for event handlers. `value` is the same element, tracked, and set once the render
 * that installed it is over: Ember forbids changing tracked state the same render has read, and
 * the content's anchoring reads it.
 */
export class ElementRef<E extends Element = HTMLElement> {
  current: E | null = null
  @tracked value: E | null = null

  set(element: E | null): void {
    this.current = element
    queueMicrotask(() => {
      if (this.current === element && this.value !== element) this.value = element
    })
  }

  /** Forgets the element, unless another has replaced it. */
  release(element: E): void {
    if (this.current === element) this.set(null)
  }
}

/** A button of the caller's own, without a `type`, becomes `type="button"`, as Radix's parts are. */
export function buttonType(element: Element): () => void {
  if (!(element instanceof HTMLButtonElement) || element.hasAttribute('type')) return () => {}
  element.type = 'button'
  return () => element.removeAttribute('type')
}

/**
 * Gives an element an id when it has none of its own, so another part can name it in
 * `aria-labelledby`. Returns the id it has, and the cleanup.
 */
export function ensureId(element: Element, id: string): () => void {
  if (element.id) return () => {}
  element.id = id
  return () => {
    if (element.id === id) element.removeAttribute('id')
  }
}

/** `display: contents` through the CSSOM, which a strict Content Security Policy allows. */
export const displayContents = modifier((element: HTMLElement) => {
  element.style.setProperty('display', 'contents')
})

// ----- Anchoring -----------------------------------------------------------------------------

/** How a floating part is placed: Radix's Popper arguments, and ember-primitives' Floating UI ones. */
export interface PopperContentArgs {
  /** The side of the trigger to place it on. Flips to the other side when there is no room. */
  side?: Side
  /** Where along that side: `start`, `center` or `end` (the inline start, in the text direction). */
  align?: Align
  /** The distance from the trigger, in pixels. */
  sideOffset?: number
  /** The shift from the `start` or `end` alignment, in pixels. Default 0. */
  alignOffset?: number
  /** Flip, and shift along the side, to stay in view. Default `true`. */
  avoidCollisions?: boolean
  /** How far from the viewport's edges to stay, in pixels. Default 0. */
  collisionPadding?: Padding
  /** How close the arrow may come to the content's corners, in pixels. Default 0. */
  arrowPadding?: number
  /** `partial` (the default) keeps it from shifting off its trigger; `always` doesn't. */
  sticky?: 'partial' | 'always'
  /** Hide it while its trigger is scrolled out of view. Default `false`. */
  hideWhenDetached?: boolean
  /** ember-primitives' and Floating UI's placement, such as `bottom-start`. `@side` and `@align` win. */
  placement?: Placement
  /** Floating UI's offset: a distance, `{ mainAxis, crossAxis, alignmentAxis }`, or a function. */
  offsetOptions?: OffsetOptions
  /**
   * Floating UI's flip options. `elementContext: 'both'`, ember-primitives' default, also flips
   * when a scroll container clips the trigger (Floating UI positions it then).
   */
  flipOptions?: AnchorFlipOptions
  /** Floating UI's shift options. */
  shiftOptions?: ShiftOptions
  /** More Floating UI middleware, run after Joinery's. */
  middleware?: Middleware[]
  /** The CSS `position`: `fixed` (the default) or `absolute`. */
  strategy?: Strategy
}

/** The arguments a part that floats takes, for its anchoring. */
export const POPPER_ARGS = [
  'side',
  'align',
  'sideOffset',
  'alignOffset',
  'avoidCollisions',
  'collisionPadding',
  'arrowPadding',
  'sticky',
  'hideWhenDetached',
  'placement',
  'offsetOptions',
  'flipOptions',
  'shiftOptions',
  'middleware',
  'strategy',
] as const satisfies ReadonlyArray<keyof PopperContentArgs>

/**
 * The anchor options for a floating part: its own arguments, then `inherited` ones (a
 * Popover's, which takes ember-primitives' arguments at its root), then `defaults`, with
 * Radix's Popper defaults (`sticky: 'partial'`, `hideWhenDetached: false`) last.
 */
export function popperOptions(
  own: PopperContentArgs,
  inherited: PopperContentArgs,
  defaults: PopperContentArgs,
  extra: Pick<AnchorOptions, 'arrow' | 'setData'>,
): AnchorOptions {
  const options: AnchorOptions = { sticky: 'partial', hideWhenDetached: false }
  for (const source of [defaults, inherited, own]) {
    for (const name of POPPER_ARGS) {
      const value = source[name]
      if (value !== undefined) (options as Record<string, unknown>)[name] = value
    }
  }
  // A placement given after a default side or alignment still decides them.
  const placement = own.placement ?? inherited.placement
  if (placement !== undefined) {
    if (own.side === undefined && inherited.side === undefined) delete options.side
    if (own.align === undefined && inherited.align === undefined) delete options.align
  }
  return { ...options, ...extra }
}

interface AnchorContentSignature {
  Element: HTMLElement
  Args: { Positional: [reference: Element | null | undefined, options: AnchorOptions] }
}

/** Anchors the content to its reference, again from scratch whenever either changes. */
export const anchorContent = modifier<AnchorContentSignature>((element, [reference, options]) => {
  if (!reference || reference === element) return
  return anchor(element, reference, options)
})

/**
 * Radix's re-namespaced custom properties on a floating part, mapped to the ones `anchor` sets,
 * so upstream's classes work unchanged: `--radix-popover-content-transform-origin`,
 * `--radix-popover-content-available-width` and `-height`, and `--radix-popover-trigger-width`
 * and `-height` (with `tooltip` or `hover-card` in place of `popover`). Radix's Popper's own
 * (`--radix-popper-anchor-width`, which upstream's sidebar examples size a menu by, and the
 * rest), which every floating part's content sees, are set too.
 */
export function exposeProperties(element: HTMLElement, name: string): () => void {
  const properties: Array<[string, string]> = [
    ['--radix-popper-transform-origin', 'var(--jn-anchor-transform-origin)'],
    ['--radix-popper-available-width', 'var(--jn-anchor-available-width)'],
    ['--radix-popper-available-height', 'var(--jn-anchor-available-height)'],
    ['--radix-popper-anchor-width', 'var(--jn-anchor-width)'],
    ['--radix-popper-anchor-height', 'var(--jn-anchor-height)'],
    [`--radix-${name}-content-transform-origin`, 'var(--jn-anchor-transform-origin)'],
    [`--radix-${name}-content-available-width`, 'var(--jn-anchor-available-width)'],
    [`--radix-${name}-content-available-height`, 'var(--jn-anchor-available-height)'],
    [`--radix-${name}-trigger-width`, 'var(--jn-anchor-width)'],
    [`--radix-${name}-trigger-height`, 'var(--jn-anchor-height)'],
  ]
  const style = element.style
  for (const [property, value] of properties) style.setProperty(property, value)
  return () => {
    for (const [property] of properties) style.removeProperty(property)
  }
}

/** Where a floating part went, for components that yield it (ember-primitives' `data`). */
export class PlacedData {
  @tracked data: AnchorData | undefined

  set = (data: AnchorData): void => {
    // Anchoring can report during a render; the next frame is soon enough for the caller.
    queueMicrotask(() => (this.data = data))
  }
}

// ----- The arrow -----------------------------------------------------------------------------

/** Keeps an element's own inline `display` aside and sets `block`, through the CSSOM. */
const displayBlock = modifier((element: SVGElement) => {
  const previous = element.style.getPropertyValue('display')
  element.style.setProperty('display', 'block')
  return () => {
    if (previous) element.style.setProperty('display', previous)
    else element.style.removeProperty('display')
  }
})

export interface PopperArrowSignature {
  Args: {
    /** Bound by the component: keeps the element `anchor` places. */
    arrow: ElementRef
    /** Its width, in pixels. Default 10. */
    width?: number
    /** Its height, in pixels. Default 5. */
    height?: number
  }
  /** A shape of your own instead of the triangle, inside the `<svg>`. */
  Blocks: { default: [] }
  /** The `<svg>`: classes and attributes go on it, as on Radix's. */
  Element: SVGSVGElement
}

/**
 * Hands the arrow's `<span>` to the content, absolutely positioned from the start, as Radix's
 * is: `anchor` measures it to offset the content, before it places it.
 */
const keepArrow = modifier((element: HTMLElement, [arrow]: [ElementRef]) => {
  element.style.setProperty('position', 'absolute')
  arrow.set(element)
  return () => {
    arrow.release(element)
    element.style.removeProperty('position')
  }
})

/**
 * Radix's `Arrow`: a `<span>` that `anchor` places on the edge facing the trigger, pointing at
 * it, around an `<svg>` triangle (10 by 5) that takes the classes and attributes. It is hidden
 * from assistive technology: it only draws.
 */
export const PopperArrow: TOC<PopperArrowSignature> = <template>
  <span data-test-jn-part="arrow" {{keepArrow @arrow}}>
    <svg
      width={{if @width @width 10}}
      height={{if @height @height 5}}
      viewBox="0 0 30 10"
      preserveAspectRatio="none"
      aria-hidden="true"
      ...attributes
      {{displayBlock}}
    >
      {{#if (has-block)}}{{yield}}{{else}}<polygon points="0,0 30,0 15,10" />{{/if}}
    </svg>
  </span>
</template>

// ----- Delays --------------------------------------------------------------------------------

const waiter = buildWaiter('@ember-joinery/primitives:delay')

/**
 * One pending delay at a time, as Radix's open and close timers: starting it again replaces
 * the one waiting. Tests' `settled()` waits for it, since what it does changes the page.
 */
export class Delay {
  readonly #owner: object
  #timer: ReturnType<typeof setTimeout> | undefined
  #token: unknown

  /** @param owner what the delay belongs to: it is cancelled when that is destroyed. */
  constructor(owner: object) {
    this.#owner = owner
    registerDestructor(owner, () => this.cancel())
  }

  get isPending(): boolean {
    return this.#timer !== undefined
  }

  start(ms: number, callback: () => void): void {
    this.cancel()
    const token = (this.#token = waiter.beginAsync())
    this.#timer = setTimeout(() => {
      this.#timer = undefined
      this.#token = undefined
      try {
        if (!isDestroying(this.#owner) && !isDestroyed(this.#owner)) callback()
      } finally {
        waiter.endAsync(token)
      }
    }, ms)
  }

  cancel(): void {
    if (this.#timer === undefined) return
    clearTimeout(this.#timer)
    this.#timer = undefined
    waiter.endAsync(this.#token)
    this.#token = undefined
  }
}

// ----- The pointer's grace area, as Radix's Tooltip works it out ----------------------------

export interface Point {
  x: number
  y: number
}

/** The side of `rect` that `point` left it through. */
export function exitSide(point: Point, rect: DOMRect): Side {
  const top = Math.abs(rect.top - point.y)
  const bottom = Math.abs(rect.bottom - point.y)
  const right = Math.abs(rect.right - point.x)
  const left = Math.abs(rect.left - point.x)
  switch (Math.min(top, bottom, right, left)) {
    case left:
      return 'left'
    case right:
      return 'right'
    case top:
      return 'top'
    default:
      return 'bottom'
  }
}

/** Two points either side of the exit point, a little back inside the element it left. */
export function paddedExitPoints(exit: Point, side: Side, padding = 5): Point[] {
  switch (side) {
    case 'top':
      return [
        { x: exit.x - padding, y: exit.y + padding },
        { x: exit.x + padding, y: exit.y + padding },
      ]
    case 'bottom':
      return [
        { x: exit.x - padding, y: exit.y - padding },
        { x: exit.x + padding, y: exit.y - padding },
      ]
    case 'left':
      return [
        { x: exit.x + padding, y: exit.y - padding },
        { x: exit.x + padding, y: exit.y + padding },
      ]
    case 'right':
      return [
        { x: exit.x - padding, y: exit.y - padding },
        { x: exit.x - padding, y: exit.y + padding },
      ]
  }
}

export function rectPoints(rect: DOMRect): Point[] {
  const { top, right, bottom, left } = rect
  return [
    { x: left, y: top },
    { x: right, y: top },
    { x: right, y: bottom },
    { x: left, y: bottom },
  ]
}

/** Whether `point` is inside `polygon` (ray casting). */
export function isPointInPolygon(point: Point, polygon: Point[]): boolean {
  const { x, y } = point
  let inside = false
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[i]!
    const b = polygon[j]!
    const intersects = a.y > y !== b.y > y && x < ((b.x - a.x) * (y - a.y)) / (b.y - a.y) + a.x
    if (intersects) inside = !inside
  }
  return inside
}

/** Whether `p` turns the chain `r`, `q` the way a hull's chain must not, as Radix's test. */
function turnsBack(r: Point, q: Point, p: Point): boolean {
  return (q.x - r.x) * (p.y - r.y) >= (q.y - r.y) * (p.x - r.x)
}

/** The convex hull of the points (Andrew's monotone chain), as Radix's `getHull`. */
export function convexHull(points: Point[]): Point[] {
  const sorted = [...points].sort((a, b) => a.x - b.x || a.y - b.y)
  if (sorted.length <= 1) return sorted
  const upper: Point[] = []
  for (const p of sorted) {
    while (upper.length >= 2 && turnsBack(upper.at(-2)!, upper.at(-1)!, p)) upper.pop()
    upper.push(p)
  }
  upper.pop()
  const lower: Point[] = []
  for (const p of [...sorted].reverse()) {
    while (lower.length >= 2 && turnsBack(lower.at(-2)!, lower.at(-1)!, p)) lower.pop()
    lower.push(p)
  }
  lower.pop()
  const [onlyUpper] = upper
  const [onlyLower] = lower
  if (upper.length === 1 && lower.length === 1 && onlyUpper!.x === onlyLower!.x) {
    if (onlyUpper!.y === onlyLower!.y) return upper
  }
  return [...upper, ...lower]
}

/**
 * The area the pointer may cross between two elements without closing what it is on its way
 * to: from where it left `from` to all of `to`.
 */
export function graceArea(event: PointerEvent, from: Element, to: Element): Point[] {
  const exit = { x: event.clientX, y: event.clientY }
  const side = exitSide(exit, from.getBoundingClientRect())
  return convexHull([...paddedExitPoints(exit, side), ...rectPoints(to.getBoundingClientRect())])
}
