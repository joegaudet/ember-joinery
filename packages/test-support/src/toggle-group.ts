import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { pressKey, type KeyModifiers } from './focus.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<ToggleGroup>` from `@ember-joinery/ember`, or the primitives' `ToggleGroup`. Its
 * items are found by their `@value` (`data-test-jn-value`), and read through ARIA: a `multiple`
 * group's items by `aria-pressed`, a `single` group's (radios) by `aria-checked`.
 *
 *   const format = new ToggleGroupHarness('format') // <ToggleGroup @name="format">
 *   await format.toggle('bold')
 *   assert.deepEqual(format.value, ['bold'])
 *   await format.press('ArrowRight')
 *   assert.strictEqual(format.focused, 'italic')
 */
export class ToggleGroupHarness extends Harness {
  static override component = 'toggle-group'

  /** Each item's element, in order. */
  get items(): HTMLElement[] {
    return this.parts('item')
  }

  /** Each item's value, in order. */
  get itemValues(): string[] {
    return this.values('item')
  }

  /** The item whose `@value` this is. Throws when there is none. */
  item(value: string): HTMLElement {
    return this.part('item', value)
  }

  /** `single` when its items are radios (`role="radio"`), else `multiple`. */
  get type(): 'single' | 'multiple' {
    return this.items.some(item => item.getAttribute('role') === 'radio') ? 'single' : 'multiple'
  }

  /** Whether an item is pressed: `aria-pressed`, or `aria-checked` in a `single` group. */
  isPressed(value: string): boolean {
    const item = this.item(value)
    const state = item.getAttribute('role') === 'radio' ? 'aria-checked' : 'aria-pressed'
    return item.getAttribute(state) === 'true'
  }

  /** The values of the items pressed now, in order. */
  get value(): string[] {
    return this.itemValues.filter(value => this.isPressed(value))
  }

  /** Whether an item can't be pressed, or, without a value, whether none can. */
  isDisabled(value?: string): boolean {
    const items = value === undefined ? this.items : [this.item(value)]
    return items.length > 0 && items.every(item => item.hasAttribute('data-disabled'))
  }

  /** An item's accessible name: its `aria-label`, else its text. */
  label(value: string): string {
    const item = this.item(value)
    return item.getAttribute('aria-label')?.trim() || text(item)
  }

  /** `horizontal` or `vertical` (`data-orientation`). */
  get orientation(): string | null {
    return this.element.getAttribute('data-orientation')
  }

  /** The styled group's `@variant`, if it was given one. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** The styled group's `@size`, if it was given one. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** The styled group's `@spacing`. */
  get spacing(): number | undefined {
    const spacing = this.element.getAttribute('data-spacing')
    return spacing === null ? undefined : Number(spacing)
  }

  /** The value of the item Tab lands on (`tabindex="0"`), or `null` when none is yet. */
  get tabStop(): string | null {
    const item = this.items.find(element => element.getAttribute('tabindex') === '0')
    return item?.getAttribute(attributes.value) ?? null
  }

  /** The value of the item that has focus, or `null` when focus is elsewhere. */
  get focused(): string | null {
    const active = document.activeElement
    const item = this.items.find(element => element === active || element.contains(active))
    return item?.getAttribute(attributes.value) ?? null
  }

  /** Presses an item, as a click does: pressed becomes unpressed, and the other way. */
  async toggle(value: string): Promise<void> {
    await click(this.item(value))
  }

  /** Focuses an item, as a click or a script would. */
  async focus(value: string): Promise<void> {
    await focus(this.item(value))
  }

  /** Presses a key on the focused item: `'ArrowRight'`, `'Home'`, `' '`. */
  async press(key: string, modifiers?: KeyModifiers): Promise<void> {
    await pressKey(key, modifiers)
  }
}
