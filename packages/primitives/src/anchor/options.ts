import type {
  HideOptions,
  Middleware,
  MiddlewareState,
  OffsetOptions,
  Padding,
  Placement,
  ShiftOptions,
  Strategy,
  VirtualElement,
} from '@floating-ui/dom'
import type { AnchorFlipOptions } from './middleware.ts'

/** A side of the anchor, as Radix's `side`. */
export type Side = 'top' | 'right' | 'bottom' | 'left'

/** Where along that side, as Radix's `align`: `start` is the inline start (left, in LTR). */
export type Align = 'start' | 'center' | 'end'

/** What a floating element is anchored to: an element, a selector for one, or a virtual element. */
export type AnchorReference = Element | VirtualElement | string

/** How a floating element was positioned: by the browser, or by Floating UI. */
export type AnchorMode = 'css' | 'floating-ui'

/**
 * Where the floating element ended up, as Floating UI's middleware state has it, plus the mode
 * that put it there. With CSS anchor positioning it is measured from the page.
 */
export type AnchorData = Pick<
  MiddlewareState,
  'x' | 'y' | 'placement' | 'initialPlacement' | 'strategy' | 'middlewareData' | 'rects'
> & { mode: AnchorMode }

/**
 * How to place a floating element against its anchor. It takes Radix's Popper arguments
 * (`side`, `align`, `sideOffset`…), which Joinery's components use, and ember-primitives'
 * floating-ui ones (`placement`, `offsetOptions`, `flipOptions`…); where both name the same
 * thing, Radix's win.
 */
export interface AnchorOptions {
  /** Floating UI's placement, such as `bottom-start`. Default `bottom`. */
  placement?: Placement
  /** The side of the anchor to place it on. Overrides `placement`'s side. */
  side?: Side
  /** Where along that side. Overrides `placement`'s alignment. */
  align?: Align
  /** The distance from the anchor, in pixels. Default 0. */
  sideOffset?: number
  /** The shift along the side from the `start` or `end` alignment, in pixels. Default 0. */
  alignOffset?: number
  /** Floating UI's offset: a distance, `{ mainAxis, crossAxis, alignmentAxis }`, or a function. */
  offsetOptions?: OffsetOptions
  /** The CSS `position`: `fixed` (the default) or `absolute`. */
  strategy?: Strategy
  /** Flip to the other side, and shift along it, to stay in view. Default `true`. */
  avoidCollisions?: boolean
  /** How far from the viewport's edges to stay, in pixels. Default 0. */
  collisionPadding?: Padding
  /** Floating UI's flip options. `elementContext: 'both'` also flips when the anchor is clipped. */
  flipOptions?: AnchorFlipOptions
  /** Floating UI's shift options. */
  shiftOptions?: ShiftOptions
  /** `partial` keeps it from shifting past its anchor (Radix's default); `always` doesn't. */
  sticky?: 'partial' | 'always'
  /** Hide the floating element while its anchor is scrolled out of view. Default `true`. */
  hideWhenDetached?: boolean
  /** Floating UI's hide options. */
  hideOptions?: HideOptions
  /** An arrow inside the floating element, to point at the anchor, as Radix's `PopperArrow`. */
  arrow?: HTMLElement | null
  /** How close the arrow may come to the floating element's corners, in pixels. Default 0. */
  arrowPadding?: number
  /** More Floating UI middleware, run after offset, flip, shift and size. Needs Floating UI. */
  middleware?: Middleware[]
  /** Called with where the floating element ended up, every time it moves. */
  setData?: (data: AnchorData) => void
}

/** The options with every default filled in. */
export interface ResolvedOptions {
  side: Side
  align: Align
  /** Away from the anchor. */
  mainAxis: number
  /** Floating UI's cross-axis offset, with `alignmentAxis` applied for `start` and `end`. */
  crossAxis: number
  /** The offset as Floating UI's `offset()` takes it, before `alignmentAxis` is applied. */
  offsetAxes: { mainAxis: number; crossAxis: number; alignmentAxis: number | null }
  strategy: Strategy
  avoidCollisions: boolean
  padding: Padding
  flipOptions: AnchorFlipOptions
  shiftOptions: ShiftOptions
  sticky: 'partial' | 'always'
  hide: boolean
  hideOptions: HideOptions
  arrow: HTMLElement | null
  arrowPadding: number
  middleware: Middleware[]
  offset: OffsetOptions | undefined
  setData: ((data: AnchorData) => void) | undefined
}

const SIDES: readonly string[] = ['top', 'right', 'bottom', 'left']

export function sideAndAlign(placement: string): [Side, Align] {
  const [side, align] = placement.split('-')
  return [
    (SIDES.includes(side!) ? side : 'bottom') as Side,
    align === 'start' || align === 'end' ? align : 'center',
  ]
}

export function placementOf(side: Side, align: Align): Placement {
  return (align === 'center' ? side : `${side}-${align}`) as Placement
}

export function isVertical(side: Side): boolean {
  return side === 'top' || side === 'bottom'
}

export function resolve(options: AnchorOptions): ResolvedOptions {
  const [placedSide, placedAlign] = sideAndAlign(options.placement ?? 'bottom')
  const side = options.side ?? placedSide
  const align = options.align ?? placedAlign

  let mainAxis = options.sideOffset ?? 0
  let rawCrossAxis = 0
  let alignmentAxis: number | null = options.alignOffset ?? null
  const given = options.offsetOptions
  if (typeof given === 'number') {
    mainAxis = given
  } else if (given && typeof given === 'object') {
    mainAxis = given.mainAxis ?? mainAxis
    rawCrossAxis = given.crossAxis ?? 0
    alignmentAxis = given.alignmentAxis ?? alignmentAxis
  }
  // Floating UI's rule: for start and end, alignmentAxis replaces crossAxis, and counts from
  // the aligned edge, so it is negated for end.
  const crossAxis =
    align !== 'center' && typeof alignmentAxis === 'number'
      ? align === 'end'
        ? -alignmentAxis
        : alignmentAxis
      : rawCrossAxis

  return {
    side,
    align,
    mainAxis,
    crossAxis,
    offsetAxes: { mainAxis, crossAxis: rawCrossAxis, alignmentAxis },
    strategy: options.strategy ?? 'fixed',
    avoidCollisions: options.avoidCollisions ?? true,
    padding: options.collisionPadding ?? 0,
    flipOptions: options.flipOptions ?? {},
    shiftOptions: options.shiftOptions ?? {},
    sticky: options.sticky ?? 'always',
    hide: options.hideWhenDetached ?? true,
    hideOptions: options.hideOptions ?? {},
    arrow: options.arrow ?? null,
    arrowPadding: options.arrowPadding ?? 0,
    middleware: options.middleware ?? [],
    offset: typeof given === 'function' ? given : undefined,
    setData: options.setData,
  }
}

function hasPadding(padding: Padding | undefined): boolean {
  if (padding === undefined) return false
  if (typeof padding === 'number') return padding !== 0
  return Object.values(padding).some(value => typeof value === 'number' && value !== 0)
}

/** The Floating UI settings CSS anchor positioning has no equivalent for. */
function needsFloatingUI(reference: Element | VirtualElement, resolved: ResolvedOptions): boolean {
  if (!(reference instanceof Element)) return true
  if (resolved.middleware.length || resolved.offset) return true
  // CSS centres the margin box, so a cross-axis shift of a centred element can't be a margin.
  if (resolved.align === 'center' && resolved.crossAxis !== 0) return true
  if (hasPadding(resolved.padding)) return true
  const {
    padding: flipPadding,
    mainAxis,
    crossAxis,
    flipAlignment,
    ...flipRest
  } = resolved.flipOptions
  void mainAxis
  void crossAxis
  void flipAlignment
  if (hasPadding(flipPadding as Padding | undefined) || Object.keys(flipRest).length) return true
  const { padding: shiftPadding, ...shiftRest } = resolved.shiftOptions
  if (hasPadding(shiftPadding as Padding | undefined) || Object.keys(shiftRest).length) return true
  if (Object.keys(resolved.hideOptions).length) return true
  return false
}

declare global {
  /** The flag CI's fallback run sets on the page before any module runs. */
  var JOINERY_ANCHOR_FALLBACK: boolean | undefined
}

/** Whether the browser has CSS anchor positioning, with the fallbacks Joinery uses. */
export function supportsAnchorPositioning(): boolean {
  try {
    return (
      typeof CSS !== 'undefined' &&
      CSS.supports('anchor-name: --jn-test') &&
      CSS.supports('position-area: bottom span-right') &&
      CSS.supports('position-try-fallbacks: flip-block, flip-inline')
    )
  } catch {
    return false
  }
}

/**
 * Whether the Floating UI fallback is forced: `globalThis.JOINERY_ANCHOR_FALLBACK === true`,
 * which CI's fallback run (and `pnpm test:anchor-fallback`) sets. Read on every call.
 */
export function isAnchorFallbackForced(): boolean {
  return globalThis.JOINERY_ANCHOR_FALLBACK === true
}

/**
 * How a floating element would be positioned now: `css` where the browser has CSS anchor
 * positioning, `floating-ui` where it hasn't, where the fallback is forced, or where an option
 * needs Floating UI (custom `middleware`, an `offsetOptions` function, a virtual reference,
 * collision padding, or Floating UI-only `flipOptions`, `shiftOptions` or `hideOptions`).
 */
export function anchorMode(
  reference?: Element | VirtualElement,
  options: AnchorOptions = {},
): AnchorMode {
  if (isAnchorFallbackForced() || !supportsAnchorPositioning()) return 'floating-ui'
  return needsFloatingUI(reference ?? document.documentElement, resolve(options))
    ? 'floating-ui'
    : 'css'
}
