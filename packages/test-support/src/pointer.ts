import { settled } from '@ember/test-helpers'

/** Which kind of pointer moves. */
export interface HoverOptions {
  /** `mouse` (the default), `pen` or `touch`. Tooltips and hover cards ignore a touch. */
  pointerType?: 'mouse' | 'pen' | 'touch'
}

/** Which way the pointer leaves an element, and how far it goes. */
export interface UnhoverOptions extends HoverOptions {
  /**
   * The side it leaves through. Default: the side away from where `away` is, or else `top`.
   */
  side?: 'top' | 'right' | 'bottom' | 'left'
  /**
   * An element it moves away from, such as a tooltip: it leaves through the side facing away
   * from it, and so out of the grace area between the two.
   */
  away?: Element | null
  /** How far past the edge it ends up, in pixels. Default 40. */
  distance?: number
}

function pointer(
  type: string,
  target: EventTarget,
  point: { x: number; y: number },
  { pointerType = 'mouse' }: HoverOptions,
  bubbles = true,
): void {
  const init = {
    bubbles,
    cancelable: true,
    composed: true,
    view: window,
    clientX: point.x,
    clientY: point.y,
  }
  const event = type.startsWith('pointer')
    ? new PointerEvent(type, { ...init, pointerType, isPrimary: true, pointerId: 1 })
    : new MouseEvent(type, init)
  target.dispatchEvent(event)
}

function centre(element: Element): { x: number; y: number } {
  const rect = element.getBoundingClientRect()
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 }
}

/**
 * Moves the pointer onto an element and rests it there, as a mouse does: `pointerover`,
 * `pointerenter`, `mouseover` and `mouseenter`, then `pointermove` and `mousemove`, at its
 * centre. `click()` sends none of them. It waits for what that sets off, such as a tooltip's
 * open delay.
 *
 *   await hover(tooltip.trigger)
 */
export async function hover(target: Element, options: HoverOptions = {}): Promise<void> {
  const point = centre(target)
  pointer('pointerover', target, point, options)
  pointer('pointerenter', target, point, options, false)
  pointer('mouseover', target, point, options)
  pointer('mouseenter', target, point, options, false)
  pointer('pointermove', target, point, options)
  pointer('mousemove', target, point, options)
  await settled()
}

/** The side of `from` that faces away from `away`. */
function sideAwayFrom(from: DOMRect, away: DOMRect): UnhoverOptions['side'] {
  const dx = away.left + away.width / 2 - (from.left + from.width / 2)
  const dy = away.top + away.height / 2 - (from.top + from.height / 2)
  if (Math.abs(dy) >= Math.abs(dx)) return dy > 0 ? 'top' : 'bottom'
  return dx > 0 ? 'left' : 'right'
}

/**
 * Moves the pointer off an element, as a mouse does: `pointerout`, `pointerleave`, `mouseout`
 * and `mouseleave` where it crosses the edge, then a `pointermove` and `mousemove` on whatever
 * is under it further on. Give `away` (a tooltip, say) to leave through the side facing away
 * from it. It waits for what that sets off, such as a hover card's close delay.
 *
 *   await unhover(tooltip.trigger, { away: tooltip.content })
 */
export async function unhover(target: Element, options: UnhoverOptions = {}): Promise<void> {
  const rect = target.getBoundingClientRect()
  const side =
    options.side ??
    (options.away ? sideAwayFrom(rect, options.away.getBoundingClientRect()) : 'top')
  const distance = options.distance ?? 40
  const { x, y } = centre(target)
  const edge = {
    top: { x, y: rect.top },
    bottom: { x, y: rect.bottom },
    left: { x: rect.left, y },
    right: { x: rect.right, y },
  }[side!]
  const step = {
    top: { x: 0, y: -1 },
    bottom: { x: 0, y: 1 },
    left: { x: -1, y: 0 },
    right: { x: 1, y: 0 },
  }[side!]
  const exit = { x: edge.x + step.x, y: edge.y + step.y }
  const beyond = { x: edge.x + step.x * distance, y: edge.y + step.y * distance }

  pointer('pointerout', target, exit, options)
  pointer('pointerleave', target, exit, options, false)
  pointer('mouseout', target, exit, options)
  pointer('mouseleave', target, exit, options, false)
  const under = document.elementFromPoint(beyond.x, beyond.y) ?? document.body
  pointer('pointermove', under, beyond, options)
  pointer('mousemove', under, beyond, options)
  await settled()
}
