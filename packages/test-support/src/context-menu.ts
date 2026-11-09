import { settled } from '@ember/test-helpers'
import { MenuHarness, pressAsBrowser } from './-private/menu.ts'

/** Where in the viewport a right click or long press lands. */
export interface MenuPoint {
  x: number
  y: number
}

/**
 * Drives a `<ContextMenu>` from `@ember-joinery/ember` or
 * `@ember-joinery/primitives/context-menu`. It reads the state from the trigger's `data-state`
 * and the items' ARIA, finds items by their text, and acts as a user does: a right click on the
 * trigger (or a long press), keys, a click on an item.
 *
 *   const menu = new ContextMenuHarness()
 *   await menu.open() // a right click in the middle of the trigger
 *   assert.deepEqual(menu.items, ['Back', 'Forward', 'Reload'])
 *   await menu.select('Reload')
 */
export class ContextMenuHarness extends MenuHarness {
  static override component = 'context-menu'

  /** Whether it is open, from the trigger's `data-state`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('data-state') === 'open'
  }

  /**
   * Right-clicks the trigger, at `point` (in the viewport) or its centre: the menu opens there.
   * A right click while it is open moves it to the new point.
   */
  async open(point?: MenuPoint): Promise<void> {
    await pressAsBrowser(this.trigger, { button: 2, point })
  }

  /**
   * Holds a touch (or a pen) on the trigger until the menu opens, as a long press on a phone
   * does, then lifts it.
   */
  async longPress(
    point?: MenuPoint,
    { pointerType = 'touch' }: { pointerType?: 'touch' | 'pen' } = {},
  ): Promise<void> {
    const { x, y } = point ?? centreOf(this.trigger)
    const init = {
      bubbles: true,
      cancelable: true,
      composed: true,
      view: window,
      clientX: x,
      clientY: y,
      pointerType,
      pointerId: 1,
      isPrimary: true,
    }
    this.trigger.dispatchEvent(new PointerEvent('pointerdown', { ...init, button: 0, buttons: 1 }))
    // settled() waits out the long press.
    await settled()
    this.trigger.dispatchEvent(new PointerEvent('pointerup', { ...init, button: 0, buttons: 0 }))
    await settled()
  }

  /** Closes it with Escape, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.pressEscape()
  }
}

function centreOf(element: Element): MenuPoint {
  const rect = element.getBoundingClientRect()
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 }
}
