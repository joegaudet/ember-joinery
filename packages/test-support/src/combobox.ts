import { blur, focus, settled, triggerEvent } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { pressKey } from './focus.ts'
import { pressEscape, pressOutside, press } from './layers.ts'
import { shownInTopLayer, text } from './-private/overlay.ts'
import { controlDescription, controlLabel, isMarkedInvalid } from './-private/control.ts'

/** Dispatches an `input` event the way typing makes one, with its `inputType`. */
function inputEvent(input: HTMLInputElement, inputType: string, data: string | null): void {
  input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType, data }))
}

/**
 * A press on a button that keeps focus where it is (its `mousedown` is prevented), as the
 * trigger, the clear button and a chip's remove button do: `click()` would focus it.
 */
async function pressInPlace(element: Element): Promise<void> {
  await triggerEvent(element, 'pointerdown', { pointerType: 'mouse', button: 0 })
  await triggerEvent(element, 'mousedown', { button: 0 })
  await triggerEvent(element, 'pointerup', { pointerType: 'mouse', button: 0 })
  await triggerEvent(element, 'mouseup', { button: 0 })
  await triggerEvent(element, 'click', { button: 0 })
}

/**
 * Drives a `<Combobox>` from `@ember-joinery/ember` or `@ember-joinery/primitives/combobox`: an
 * input that filters a list of items. It reads the state from the input's ARIA and the items'
 * (`aria-expanded`, `aria-activedescendant`, `aria-selected`), and acts as a user does: typing
 * (with real `input` events, so the list filters and opens as it does for a person), the arrow
 * keys, presses on items, chips and buttons.
 *
 *   const framework = new ComboboxHarness('framework') // <Combobox @name="framework">
 *   await framework.type('sv')
 *   assert.deepEqual(framework.items, ['SvelteKit'])
 *   await framework.pressKey('ArrowDown')
 *   await framework.pressKey('Enter')
 *   assert.strictEqual(framework.inputValue, 'SvelteKit')
 *
 * Items are named by their label (`data-test-jn-value`). While the list is closed its items
 * aren't in the page: read them after `open()` or `type()`.
 */
export class ComboboxHarness extends Harness {
  static override component = 'combobox'

  /** The text input, or `null` while it is inside the closed popup. */
  get input(): HTMLInputElement | null {
    return this.queryPart<HTMLInputElement>('input')
  }

  #input(): HTMLInputElement {
    const input = this.input
    if (!input) throw new Error(`Joinery harness: ${this} has no input showing`)
    return input
  }

  /** The button that opens and closes the list, or `null` without one. */
  get trigger(): HTMLElement | null {
    return this.queryPart('trigger')
  }

  /** The clear button, or `null` while there's nothing to clear. */
  get clearButton(): HTMLElement | null {
    return this.queryPart('clear')
  }

  /** The popup, or `null` while it is closed. */
  get content(): HTMLElement | null {
    return this.queryPart('content')
  }

  /** The `listbox`, or `null` while it is closed. */
  get list(): HTMLElement | null {
    return this.queryPart('list')
  }

  /** The element whose `aria-expanded` says whether it's open: the input, or the trigger when the input is in the popup. */
  get #combobox(): HTMLElement {
    const trigger = this.trigger
    if (trigger?.getAttribute('role') === 'combobox') return trigger
    return this.input ?? (trigger as HTMLElement)
  }

  /** Whether the list is open (`aria-expanded`). */
  get isOpen(): boolean {
    return this.#combobox.getAttribute('aria-expanded') === 'true'
  }

  /** Whether the popup is showing in the browser's top layer. */
  get isShown(): boolean {
    return shownInTopLayer(this.content)
  }

  /** The side the popup was placed on, after any flip (`data-side`). */
  get side(): string | null {
    return this.content?.getAttribute('data-side') ?? null
  }

  /** The input's text. */
  get inputValue(): string {
    return this.input?.value ?? ''
  }

  /** The input's accessible name: its label, `aria-label` or placeholder. */
  get label(): string {
    const input = this.input
    return input ? controlLabel(input) : ''
  }

  /** The text of what the input's `aria-describedby` names, or `''`. */
  get description(): string {
    const input = this.input
    return input ? controlDescription(input) : ''
  }

  /** The input's placeholder. */
  get placeholder(): string {
    return this.input?.placeholder ?? ''
  }

  /** Whether it is disabled. */
  get isDisabled(): boolean {
    return this.input?.disabled ?? this.trigger?.hasAttribute('disabled') ?? false
  }

  /** Whether the input is marked invalid with `aria-invalid`. */
  get isInvalid(): boolean {
    const input = this.input
    return input ? isMarkedInvalid(input) : false
  }

  /** Whether it is marked required (`aria-required`). */
  get isRequired(): boolean {
    return this.#combobox.getAttribute('aria-required') === 'true'
  }

  /** Whether the input has focus. */
  get isFocused(): boolean {
    return document.activeElement === this.input
  }

  /** The items' elements, in order (while open). */
  get itemElements(): HTMLElement[] {
    return this.parts('item')
  }

  /** Every item's label (its `data-test-jn-value`), in order (while open). */
  get items(): string[] {
    return this.values('item')
  }

  /** Every item's text, in order (while open). */
  get itemTexts(): string[] {
    return this.itemElements.map(item => text(item))
  }

  /** The item with this label. Throws when there is none. */
  item(label: string): HTMLElement {
    return this.part('item', label)
  }

  /** The label of the highlighted item (the input's `aria-activedescendant`), or `null`. */
  get highlighted(): string | null {
    const id = (this.input ?? this.#combobox).getAttribute('aria-activedescendant')
    const item = id ? document.getElementById(id) : null
    return item?.getAttribute('data-test-jn-value') ?? null
  }

  /** Whether the item with this label is chosen (`aria-selected`). */
  isItemSelected(label: string): boolean {
    return this.item(label).getAttribute('aria-selected') === 'true'
  }

  /** Whether the item with this label can't be chosen (`aria-disabled`). */
  isItemDisabled(label: string): boolean {
    return this.item(label).getAttribute('aria-disabled') === 'true'
  }

  /** Each group's label, in order (while open). */
  get groups(): string[] {
    return this.parts('group').map(group => {
      const id = group.getAttribute('aria-labelledby')
      return id ? text(document.getElementById(id)) : ''
    })
  }

  /** Whether nothing matches the query (the popup's `data-empty`). */
  get isEmpty(): boolean {
    return this.content?.hasAttribute('data-empty') ?? false
  }

  /** What the Empty part says now (only while nothing matches), or `''`. */
  get emptyText(): string {
    return text(this.queryPart('empty'))
  }

  /** The chips' labels, in order: the chosen items of a multiple combobox. */
  get chips(): string[] {
    return this.values('chip')
  }

  /** The chip with this label. */
  chip(label: string): HTMLElement {
    return this.part('chip', label)
  }

  /** The values a form would get, from the hidden inputs (with `@formName`). */
  get formValues(): string[] {
    return this.parts<HTMLInputElement>('form-value').map(input => input.value)
  }

  /** Opens the list with a press on the input (or the trigger, when the input is in the popup). */
  async open(): Promise<void> {
    if (this.isOpen) return
    const input = this.input
    if (input) {
      await focus(input)
      await triggerEvent(input, 'mousedown', { button: 0 })
    } else {
      await this.pressTrigger()
    }
  }

  /** Closes the list with Escape, unless it is closed. */
  async close(): Promise<void> {
    if (this.isOpen) await pressEscape()
  }

  /** A press on the trigger: it opens or closes the list. */
  async pressTrigger(): Promise<void> {
    const trigger = this.trigger
    if (!trigger) throw new Error(`Joinery harness: ${this} has no trigger`)
    // A trigger beside the input keeps focus in the input; one that opens a popup with the
    // input inside takes focus, as a button does.
    if (trigger.getAttribute('role') === 'combobox') {
      // The press focuses it before the popup opens and moves focus inside.
      await focus(trigger)
      await triggerEvent(trigger, 'mousedown', { button: 0 })
      await triggerEvent(trigger, 'mouseup', { button: 0 })
      await triggerEvent(trigger, 'click', { button: 0 })
    } else {
      await pressInPlace(trigger)
    }
  }

  /** A press on the clear button. */
  async clear(): Promise<void> {
    const button = this.clearButton
    if (!button) throw new Error(`Joinery harness: ${this} has nothing to clear`)
    await pressInPlace(button)
  }

  /**
   * Types `text` at the end of the input, a character at a time, as a person does: each makes
   * an `input` event with `inputType: 'insertText'`, which filters and opens the list.
   */
  async type(text: string): Promise<void> {
    const input = this.#input()
    if (document.activeElement !== input) await focus(input)
    for (const character of text) {
      await triggerEvent(input, 'keydown', { key: character })
      input.value += character
      inputEvent(input, 'insertText', character)
      await settled()
      await triggerEvent(input, 'keyup', { key: character })
    }
  }

  /** Deletes the input's last `count` characters, as Backspace does. */
  async deleteBackward(count = 1): Promise<void> {
    const input = this.#input()
    if (document.activeElement !== input) await focus(input)
    for (let i = 0; i < count && input.value; i += 1) {
      input.value = input.value.slice(0, -1)
      inputEvent(input, 'deleteContentBackward', null)
      await settled()
    }
  }

  /** Replaces the input's text, as autofill or a paste does (which doesn't open the list). */
  async fill(text: string): Promise<void> {
    const input = this.#input()
    if (document.activeElement !== input) await focus(input)
    input.value = text
    inputEvent(input, 'insertReplacementText', text)
    await settled()
  }

  /** Chooses the item with this label: opens the list unless open, then presses the item. */
  async select(label: string): Promise<void> {
    await this.open()
    await press(this.item(label))
  }

  /** Presses the item with this label (the list must be open). */
  async pressItem(label: string): Promise<void> {
    await press(this.item(label))
  }

  /** Removes the chip with this label, with a press on its remove button. */
  async removeChip(label: string): Promise<void> {
    const remove = this.chip(label).querySelector('[data-test-jn-part="chip-remove"]')
    if (!remove) throw new Error(`Joinery harness: chip "${label}" in ${this} has no remove button`)
    await pressInPlace(remove)
  }

  /** Presses a key where focus is: the arrows, Enter, Escape, Backspace, Home or End. */
  async pressKey(key: string): Promise<void> {
    await pressKey(key)
  }

  /** Presses Escape where focus is. */
  async pressEscape(): Promise<void> {
    await pressEscape()
  }

  /** A press outside the combobox and its popup. */
  async pressOutside(): Promise<void> {
    await pressOutside()
  }

  /** Moves focus to the input. */
  async focus(): Promise<void> {
    await focus(this.#input())
  }

  /** Moves focus away from the input. */
  async blur(): Promise<void> {
    await blur(this.#input())
  }
}
