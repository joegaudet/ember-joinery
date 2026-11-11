import { settled } from '@ember/test-helpers'

/** The pointer events a mouse sends, which `sendPointer()` dispatches. */
export type PointerEventType =
  | 'pointerdown'
  | 'pointermove'
  | 'pointerup'
  | 'pointercancel'
  | 'pointerenter'
  | 'pointerleave'
  | 'pointerover'
  | 'pointerout'

/** The pointer `sendPointer()` uses: the mouse's. */
const MOUSE_POINTER_ID = 1

/**
 * Dispatches one pointer event on `target` as a mouse sends it (a real `PointerEvent`, the
 * primary pointer, the main button), then waits for the app to settle. `pointerenter` and
 * `pointerleave` don't bubble, as in a browser; the rest do. Pass where it is (`clientX`,
 * `clientY`) and anything else to change.
 *
 *   await sendPointer(handle, 'pointerdown', { clientX: 100, clientY: 20 })
 *   await sendPointer(handle, 'pointermove', { clientX: 140, clientY: 20 })
 *   await sendPointer(handle, 'pointerup', { clientX: 140, clientY: 20, buttons: 0 })
 *
 * `@ember/test-helpers`' `triggerEvent` makes a plain `Event` for these, without the
 * `PointerEvent` interface; components that check for one need this.
 */
export async function sendPointer(
  target: Element | Document,
  type: PointerEventType,
  init: PointerEventInit = {},
): Promise<PointerEvent> {
  const bubbles = type !== 'pointerenter' && type !== 'pointerleave'
  const pressed = type === 'pointerdown' || type === 'pointermove'
  const event = new PointerEvent(type, {
    bubbles,
    cancelable: true,
    composed: true,
    view: window,
    pointerId: MOUSE_POINTER_ID,
    pointerType: 'mouse',
    isPrimary: true,
    button: type === 'pointermove' ? -1 : 0,
    buttons: pressed ? 1 : 0,
    ...init,
  })
  target.dispatchEvent(event)
  await settled()
  return event
}
