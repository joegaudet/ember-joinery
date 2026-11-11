import { focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey, typeKeys } from './focus.ts'
import { pressEscape, pressOutside, press } from './layers.ts'
import { accessibleName, shownInTopLayer, text } from './-private/overlay.ts'
import { controlDescription, controlLabel, isMarkedInvalid } from './-private/control.ts'
import { isDisabled } from './-private/checkable.ts'

/**
 * Drives a `<Select>` from `@ember-joinery/ember` or `@ember-joinery/primitives/select`: a
 * button (`role="combobox"`) that opens a listbox of options. It reads the state from the
 * trigger's ARIA and the options' (`aria-expanded`, `aria-disabled`, `data-state`), and acts as
 * a user does: a press on the trigger, a press on an option, keys and typeahead.
 *
 *   const fruit = new SelectHarness('fruit') // <Select @name="fruit">
 *   await fruit.select('banana')
 *   assert.strictEqual(fruit.value, 'banana')
 *   assert.strictEqual(fruit.valueText, 'Banana')
 *
 * While it is closed its options aren't in the page (as Radix's aren't): read them after
 * `open()`.
 */
export class SelectHarness extends Harness {
  static override component = 'select'

  /** The trigger: the `Trigger` part, or your own element with the `trigger` modifier. */
  get trigger(): HTMLElement {
    return this.part('trigger')
  }

  /** The listbox, or `null` while it is closed. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** Whether it is open, from the trigger's `aria-expanded`. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Whether the listbox is showing in the browser's top layer (itself, or its item-aligned wrapper). */
  get isShown(): boolean {
    const content = this.content
    return shownInTopLayer(content) || shownInTopLayer(content?.parentElement)
  }

  /** Where the listbox went: `item-aligned` over the trigger, or `popper` below it. */
  get position(): 'item-aligned' | 'popper' | null {
    const content = this.content
    if (!content) return null
    return content.parentElement?.getAttribute('data-test-jn-part') === 'content-wrapper'
      ? 'item-aligned'
      : 'popper'
  }

  /** The side the `popper` listbox was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** The chosen value, or `''` while none is chosen. */
  get value(): string {
    return this.element.getAttribute('data-test-jn-value') ?? ''
  }

  /** What the trigger's value shows: the chosen option's text, or the placeholder. */
  get valueText(): string {
    return text(this.queryPart('value') ?? this.trigger)
  }

  /** Whether the value shows its placeholder (the trigger's `data-placeholder`). */
  get isPlaceholder(): boolean {
    return this.trigger.hasAttribute('data-placeholder')
  }

  /**
   * The trigger's accessible name: `aria-labelledby`'s text, else `aria-label`, else its
   * `<label>`'s text (a combobox isn't named by its own text).
   */
  get label(): string {
    return controlLabel(this.#control)
  }

  /** The text of what the trigger's `aria-describedby` names (a field's description and errors). */
  get description(): string {
    return controlDescription(this.#control)
  }

  /** The trigger, read as a labelled control: a `<button>` has `labels` too. */
  get #control(): HTMLInputElement {
    return this.trigger as unknown as HTMLInputElement
  }

  /** The listbox's accessible name (its trigger, unless you named it). */
  get contentLabel(): string {
    const content = this.content
    return content ? accessibleName(content) : ''
  }

  /** Whether it is disabled: the trigger's `disabled`, or `aria-disabled="true"` on your own element. */
  get isDisabled(): boolean {
    return isDisabled(this.trigger)
  }

  /** Whether the trigger is marked invalid with `aria-invalid`. */
  get isInvalid(): boolean {
    return isMarkedInvalid(this.trigger)
  }

  /** Whether it is marked required (`aria-required`). */
  get isRequired(): boolean {
    return this.trigger.getAttribute('aria-required') === 'true'
  }

  /** Whether the trigger has focus. */
  get isFocused(): boolean {
    return document.activeElement === this.trigger
  }

  /** The options' elements, in order (while open). */
  get optionElements(): HTMLElement[] {
    return this.parts('option')
  }

  /** Every option's value, in order (while open). */
  get options(): string[] {
    return this.values('option')
  }

  /** Every option's text, in order (while open). */
  get optionTexts(): string[] {
    return this.optionElements.map(option => text(option))
  }

  /** The option with this value. Throws when there is none. */
  option(value: string): HTMLElement {
    return this.part('option', value)
  }

  /** The value of the option that has focus (`data-highlighted`), or `null`. */
  get highlighted(): string | null {
    const option = this.optionElements.find(element => element.hasAttribute('data-highlighted'))
    return option?.getAttribute('data-test-jn-value') ?? null
  }

  /** Whether the option with this value is the chosen one (`data-state="checked"`). */
  isOptionSelected(value: string): boolean {
    return this.option(value).getAttribute('data-state') === 'checked'
  }

  /** Whether the option with this value can't be chosen (`aria-disabled`). */
  isOptionDisabled(value: string): boolean {
    return this.option(value).getAttribute('aria-disabled') === 'true'
  }

  /** Each group's label, in order (while open). */
  get groups(): string[] {
    return this.parts('group').map(group => {
      const id = group.getAttribute('aria-labelledby')
      return id ? text(document.getElementById(id)) : ''
    })
  }

  /** The values of the options in the group with this label. */
  optionsIn(group: string): string[] {
    const found = this.parts('group').find(element => {
      const id = element.getAttribute('aria-labelledby')
      return id ? text(document.getElementById(id)) === group : false
    })
    if (!found) throw new Error(`Joinery harness: no group "${group}" in ${this}`)
    return [...found.querySelectorAll('[data-test-jn-part="option"]')].map(
      option => option.getAttribute('data-test-jn-value') ?? '',
    )
  }

  /** Whether the "scroll up" and "scroll down" buttons are showing. */
  get canScrollUp(): boolean {
    return this.queryPart('scroll-up-button') !== null
  }

  get canScrollDown(): boolean {
    return this.queryPart('scroll-down-button') !== null
  }

  /** The hidden native `<select>` that carries the value in a form, or `null` outside one. */
  get nativeSelect(): HTMLSelectElement | null {
    return this.queryPart<HTMLSelectElement>('native-select')
  }

  /** Opens it with a press on the trigger, as a mouse does, unless it is open. */
  async open(): Promise<void> {
    if (!this.isOpen) await press(this.trigger)
  }

  /** Opens it from the keyboard: focuses the trigger and presses `key` (Enter, Space, or an arrow). */
  async openWithKeyboard(key: 'Enter' | ' ' | 'ArrowDown' | 'ArrowUp' = 'Enter'): Promise<void> {
    await focus(this.trigger)
    await pressKey(key)
  }

  /** Closes it with Escape, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await pressEscape()
  }

  /** Presses Escape where focus is. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the listbox, as a user dismissing it makes. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }

  /** Chooses the option with this value: opens it, then presses the option, as a mouse does. */
  async select(value: string): Promise<void> {
    await this.open()
    await press(this.option(value))
  }

  /** Presses the option with this value (it must be open). */
  async pressOption(value: string): Promise<void> {
    await press(this.option(value))
  }

  /** Presses a key where focus is: an arrow, Home, End, Enter, Space or Escape. */
  async pressKey(key: string): Promise<void> {
    await pressKey(key)
  }

  /** Types `text` where focus is: on the closed trigger it chooses, in the open list it moves focus. */
  async typeahead(text: string): Promise<void> {
    await typeKeys(text)
  }

  /** Moves focus to the trigger. */
  async focus(): Promise<void> {
    await focus(this.trigger)
  }
}
