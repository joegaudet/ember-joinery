import { click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { pressKey, type KeyModifiers } from './focus.ts'
import { accessibleName, hiddenInputOf, isDisabled, isInvalid } from './-private/checkable.ts'

/**
 * Drives a `<RadioGroup>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/radio-group`. Items are found by their `@value`
 * (`data-test-jn-value`), and state comes from ARIA: each item's `aria-checked`, the group's
 * `aria-required` and `aria-orientation`.
 *
 *   const spacing = new RadioGroupHarness('spacing') // <RadioGroup @name="spacing">
 *   await spacing.choose('compact')
 *   assert.strictEqual(spacing.value, 'compact')
 *   await spacing.press('ArrowUp') // focus, and the choice, move to the previous item
 */
export class RadioGroupHarness extends Harness {
  static override component = 'radio-group'

  /** Each item's element, in order. */
  get items(): HTMLElement[] {
    return this.parts('item')
  }

  /** Each item's value, in order. */
  get options(): string[] {
    return this.values('item')
  }

  /** The item with this value. Throws when there is none. */
  item(value: string): HTMLElement {
    return this.part('item', value)
  }

  /** The chosen item's value, or `null` when none is. */
  get value(): string | null {
    const item = this.items.find(element => element.getAttribute('aria-checked') === 'true')
    return item?.getAttribute(attributes.value) ?? null
  }

  /** Whether the item with this value is chosen. */
  isChecked(value: string): boolean {
    return this.item(value).getAttribute('aria-checked') === 'true'
  }

  /** Whether the item with this value can't be chosen. */
  isItemDisabled(value: string): boolean {
    return isDisabled(this.item(value))
  }

  /** Whether the item with this value is marked invalid (`aria-invalid`). */
  isItemInvalid(value: string): boolean {
    return isInvalid(this.item(value))
  }

  /** The accessible name of the item with this value: its `<label>`'s text, or its ARIA. */
  labelOf(value: string): string {
    return accessibleName(this.item(value))
  }

  /** The group's accessible name: `aria-label` or `aria-labelledby`. */
  get label(): string {
    return accessibleName(this.element)
  }

  /** Whether every item is disabled (the group's `@disabled`). */
  get isDisabled(): boolean {
    return this.element.hasAttribute('data-disabled')
  }

  /** Whether a form needs a choice (`aria-required="true"`). */
  get isRequired(): boolean {
    return this.element.getAttribute('aria-required') === 'true'
  }

  /** `horizontal`, `vertical`, or `null` when every arrow key moves (`aria-orientation`). */
  get orientation(): string | null {
    return this.element.getAttribute('aria-orientation')
  }

  /** The value of the item that has focus, or `null` when focus is elsewhere. */
  get focused(): string | null {
    const active = document.activeElement
    const item = this.items.find(element => element === active)
    return item?.getAttribute(attributes.value) ?? null
  }

  /** The value of the item Tab enters on (`tabindex="0"`), or `null` before any has had focus. */
  get tabStop(): string | null {
    const item = this.items.find(element => element.getAttribute('tabindex') === '0')
    return item?.getAttribute(attributes.value) ?? null
  }

  /** The hidden native radio the item with this value renders in a form, or `null`. */
  inputOf(value: string): HTMLInputElement | null {
    return hiddenInputOf(this.item(value))
  }

  /** Clicks the item with this value, as a user would, which chooses it. */
  async choose(value: string): Promise<void> {
    await click(this.item(value))
  }

  /** Moves focus to the item with this value, as a click would, without choosing it. */
  async focus(value: string): Promise<void> {
    await focus(this.item(value))
  }

  /** Presses a key on the focused item: an arrow moves focus and the choice. */
  async press(key: string, modifiers?: KeyModifiers): Promise<boolean> {
    return pressKey(key, modifiers)
  }
}
