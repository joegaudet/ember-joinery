import { detectOverflow, flip } from '@floating-ui/dom'
import type { ElementContext, FlipOptions, Middleware, MiddlewareState } from '@floating-ui/dom'

export type AnchorFlipOptions = Omit<FlipOptions, 'elementContext'> & {
  /**
   * Which element must stay inside its clipping boundary: Floating UI's `floating` (the
   * default) or `reference`, or `both`, to flip when either overflows. A floating element in the
   * top layer ignores the scroll containers of its anchor, so `floating` alone leaves it
   * attached to an anchor that is clipped.
   */
  elementContext?: ElementContext | 'both'
}

/**
 * Middleware that passes the whole middleware state on, as ember-primitives' `exposeMetadata`:
 * it lands in `middlewareData.metadata`.
 */
export function exposeMetadata(): Middleware {
  return {
    name: 'metadata',
    fn: data => ({ data }),
  }
}

async function detectOverflowOfBoth(
  state: MiddlewareState,
  options?: Parameters<typeof detectOverflow>[1],
) {
  const floating = await detectOverflow(state, { ...options, elementContext: 'floating' })
  const reference = await detectOverflow(state, { ...options, elementContext: 'reference' })
  return {
    top: Math.max(floating.top, reference.top),
    right: Math.max(floating.right, reference.right),
    bottom: Math.max(floating.bottom, reference.bottom),
    left: Math.max(floating.left, reference.left),
  }
}

/**
 * Floating UI's `flip`, with ember-primitives' `elementContext: 'both'`: two flips would
 * disagree and undo each other, so `both` feeds the overflow of both elements into one.
 */
export function flipTo(options: AnchorFlipOptions = {}): Middleware {
  const { elementContext, ...flipOptions } = options
  if (elementContext !== 'both') return flip({ ...flipOptions, elementContext })

  const middleware = flip(flipOptions)
  return {
    ...middleware,
    fn: state =>
      middleware.fn({
        ...state,
        platform: { ...state.platform, detectOverflow: detectOverflowOfBoth },
      }),
  }
}

/** The arrow's measured size, for `transformOrigin`. */
export interface ArrowSize {
  width: number
  height: number
}

/**
 * The point the floating element grows from: the arrow's tip, or the edge facing the anchor
 * (its start, centre or end), as Radix's Popper works it out. Shared by both modes.
 */
export function originFor(
  placement: string,
  floatingSize: { width: number; height: number },
  arrow: { x?: number; y?: number; centerOffset?: number } | undefined,
  arrowSize: ArrowSize,
): { x: string; y: string } {
  const [side, align = 'center'] = placement.split('-')
  const hidden = !arrow || arrow.centerOffset !== 0
  const width = hidden ? 0 : arrowSize.width
  const height = hidden ? 0 : arrowSize.height
  const noArrow = { start: '0%', center: '50%', end: '100%' }[align] ?? '50%'
  const arrowX = `${(arrow?.x ?? 0) + width / 2}px`
  const arrowY = `${(arrow?.y ?? 0) + height / 2}px`
  switch (side) {
    case 'top':
      return { x: hidden ? noArrow : arrowX, y: `${floatingSize.height + height}px` }
    case 'right':
      return { x: `${-height}px`, y: hidden ? noArrow : arrowY }
    case 'left':
      return { x: `${floatingSize.width + height}px`, y: hidden ? noArrow : arrowY }
    default:
      return { x: hidden ? noArrow : arrowX, y: `${-height}px` }
  }
}

/**
 * Middleware that works out the transform origin, as Radix's Popper does, into
 * `middlewareData.transformOrigin` (`{ x, y }`, as CSS lengths).
 */
export function transformOrigin(arrowSize: ArrowSize = { width: 0, height: 0 }): Middleware {
  return {
    name: 'transformOrigin',
    fn: ({ placement, rects, middlewareData }) => ({
      data: originFor(placement, rects.floating, middlewareData.arrow, arrowSize),
    }),
  }
}
