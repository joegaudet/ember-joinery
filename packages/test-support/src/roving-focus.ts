import { focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

/**
 * Drives a `<RovingFocusGroup>` from `@ember-joinery/primitives/roving-focus`: items that share
 * one tab stop, with the arrow keys, Home and End moving between them. Items are found by their
 * `data-test-jn-value` (their `@tabStopId`).
 *
 *   const toolbar = new RovingFocusGroupHarness('format')
 *   await toolbar.focus('bold')
 *   await toolbar.press('ArrowRight')
 *   assert.strictEqual(toolbar.focused, 'italic')
 *   assert.strictEqual(toolbar.tabStop, 'italic') // where Tab comes back to
 */
export class RovingFocusGroupHarness extends Harness {
  static override component = 'roving-focus-group'

  /** Each item's element, in order. */
  get items(): HTMLElement[] {
    return this.parts('item')
  }

  /** Each item's id, in order. */
  get ids(): string[] {
    return this.values('item')
  }

  /** The item with this id. Throws when there is none. */
  item(id: string): HTMLElement {
    return this.part('item', id)
  }

  /** `horizontal`, `vertical`, or `undefined` when every arrow key moves focus. */
  get orientation(): string | undefined {
    return this.element.getAttribute('data-orientation') ?? undefined
  }

  /**
   * The id of the item in the tab order (`tabindex="0"`), which Tab lands on, or `null` when no
   * item is: then the group itself takes the Tab and sends focus on to an item.
   */
  get tabStop(): string | null {
    const item = this.items.find(element => element.getAttribute('tabindex') === '0')
    return item?.getAttribute(attributes.value) ?? null
  }

  /** Whether Tab stops on the group itself (`tabindex="0"`), on its way to an item. */
  get isGroupTabbable(): boolean {
    return this.element.getAttribute('tabindex') === '0'
  }

  /** The id of the item that has focus, or `null` when focus is elsewhere. */
  get focused(): string | null {
    const active = document.activeElement
    const item = this.items.find(element => element === active || element.contains(active))
    return item?.getAttribute(attributes.value) ?? null
  }

  /** Focuses an item, as a click or a script would. */
  async focus(id: string): Promise<void> {
    await focus(this.item(id))
  }

  /** Presses a key on the focused item: `'ArrowRight'`, `'Home'`, `'End'`. */
  async press(key: string, modifiers?: KeyModifiers): Promise<void> {
    await pressKey(key, modifiers)
  }
}
