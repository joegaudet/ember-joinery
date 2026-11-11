import { focus } from '@ember/test-helpers'
import { pressKey } from './focus.ts'
import { MenuHarness, pressAsBrowser } from './-private/menu.ts'

export { MenuLevel, SubMenu } from './-private/menu.ts'

/**
 * Drives a `<DropdownMenu>` from `@ember-joinery/ember` or
 * `@ember-joinery/primitives/dropdown-menu`. It reads the state from the trigger's ARIA
 * (`aria-expanded`) and the items' (`aria-checked`, `aria-disabled`), finds items by their
 * text, and acts as a user does: a press on the trigger, keys, a click on an item.
 *
 *   const menu = new DropdownMenuHarness('account') // <DropdownMenu @name="account">
 *   await menu.open()
 *   assert.deepEqual(menu.items, ['Profile', 'Billing', 'Log out'])
 *   await menu.sub('Invite users').open()
 *   await menu.select('Profile')
 *   assert.false(menu.isOpen)
 */
export class DropdownMenuHarness extends MenuHarness {
  static override component = 'dropdown-menu'

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /**
   * Presses the trigger as a pointer does, which opens the menu when it is closed and closes it
   * when it is open. Focus goes to the content, not an item.
   */
  async toggle(): Promise<void> {
    await pressAsBrowser(this.trigger)
  }

  /** Opens it with a press on the trigger, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await this.toggle()
  }

  /** Closes it with a press on the trigger, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await this.toggle()
  }

  /**
   * Opens it from the keyboard: focus on the trigger, then `key` (Enter, Space or ArrowDown).
   * Focus goes to the first item.
   */
  async openWithKeyboard(key: 'Enter' | ' ' | 'ArrowDown' = 'Enter'): Promise<void> {
    await focus(this.trigger)
    await pressKey(key)
  }
}
