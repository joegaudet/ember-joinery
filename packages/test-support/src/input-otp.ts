import { blur, fillIn, find, focus, getRootElement, settled } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { controlDescription, controlLabel, isMarkedInvalid, textOf } from './-private/control.ts'
import { selectors } from './selectors.ts'

/** The keys `InputOTPHarness#press` edits and moves with, as a browser's text input does. */
export type InputOTPKey = 'Backspace' | 'Delete' | 'ArrowLeft' | 'ArrowRight' | 'Home' | 'End'

function keyEvent(input: HTMLInputElement, type: 'keydown' | 'keyup', key: string): KeyboardEvent {
  const event = new KeyboardEvent(type, { key, bubbles: true, cancelable: true, view: window })
  input.dispatchEvent(event)
  return event
}

/** Tells the page the selection moved, as the browser does after a caret move. */
function selectionMoved(input: HTMLInputElement): void {
  input.ownerDocument.dispatchEvent(new Event('selectionchange'))
}

/** Replaces the input's selection with `text`, as typing does: within `maxlength`, then `input`. */
function insert(input: HTMLInputElement, text: string, inputType: string): void {
  const value = input.value
  const start = input.selectionStart ?? value.length
  const end = input.selectionEnd ?? start
  const max = input.maxLength
  const room = max < 0 ? text.length : max - (value.length - (end - start))
  const inserted = text.slice(0, Math.max(0, room))
  if (!inserted) return
  input.value = value.slice(0, start) + inserted + value.slice(end)
  const caret = start + inserted.length
  input.setSelectionRange(caret, caret)
  input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType, data: inserted }))
  selectionMoved(input)
}

/** Deletes the selection, or the character before (or after) the caret, as a browser does. */
function remove(input: HTMLInputElement, forward: boolean): void {
  const value = input.value
  let start = input.selectionStart ?? value.length
  let end = input.selectionEnd ?? start
  if (start === end) {
    if (forward) end = Math.min(value.length, end + 1)
    else start = Math.max(0, start - 1)
  }
  if (start === end) return
  input.value = value.slice(0, start) + value.slice(end)
  input.setSelectionRange(start, start)
  const inputType = forward ? 'deleteContentForward' : 'deleteContentBackward'
  input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType }))
  selectionMoved(input)
}

/** Moves the caret, as an arrow key, Home or End does in a left-to-right text input. */
function move(input: HTMLInputElement, key: 'ArrowLeft' | 'ArrowRight' | 'Home' | 'End'): void {
  const length = input.value.length
  const start = input.selectionStart ?? length
  const end = input.selectionEnd ?? start
  let caret: number
  if (key === 'Home') caret = 0
  else if (key === 'End') caret = length
  else if (start !== end) caret = key === 'ArrowLeft' ? start : end
  else caret = key === 'ArrowLeft' ? Math.max(0, start - 1) : Math.min(length, end + 1)
  input.setSelectionRange(caret, caret)
  selectionMoved(input)
}

/**
 * Drives an `<InputOTP>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/input-otp`: one native `<input>` laid over its slots. State comes
 * from the input and its ARIA, and from the slots' `data-active`. It types, deletes and moves the
 * caret the way a browser edits the input, and pastes and autofills a code as a browser does:
 *
 *   const otp = new InputOTPHarness('verification') // <InputOTP @name="verification">
 *   await otp.typeIn('123')
 *   assert.deepEqual(otp.chars, ['1', '2', '3', '', '', ''])
 *   assert.strictEqual(otp.activeIndex, 3)
 *   await otp.paste('456')
 *   assert.true(otp.isComplete)
 */
export class InputOTPHarness extends Harness {
  static override component = 'input-otp'

  /** The native `<input>` that holds the code. */
  get input(): HTMLInputElement {
    return this.part<HTMLInputElement>('input')
  }

  /** The code it holds. */
  get value(): string {
    return this.input.value
  }

  /** How many characters the code has (`@maxLength`). */
  get maxLength(): number {
    return this.input.maxLength
  }

  /** Whether the code has all its characters. */
  get isComplete(): boolean {
    return this.value.length === this.maxLength
  }

  /** The slots, in document order. */
  get slots(): HTMLElement[] {
    return this.parts('slot')
  }

  /** The slot for one character of the code, from 0. Throws when there is none. */
  slot(index: number): HTMLElement {
    return this.part('slot', String(index))
  }

  /** What each slot shows, in document order (`''` for an empty one). */
  get chars(): string[] {
    return this.slots.map(slot => textOf(slot))
  }

  /** The indexes of the slots the selection is on (`data-active="true"`). */
  get activeIndexes(): number[] {
    return this.slots
      .filter(slot => slot.getAttribute('data-active') === 'true')
      .map(slot => Number(slot.getAttribute('data-test-jn-value')))
  }

  /** The index of the first active slot, or `null` while none is (it doesn't have focus). */
  get activeIndex(): number | null {
    return this.activeIndexes[0] ?? null
  }

  /** Whether a slot draws the caret: the styled slot's, where the next character goes. */
  hasCaret(index: number): boolean {
    return Boolean(this.slot(index).querySelector(selectors.part('caret')))
  }

  /** Its groups of slots (the styled component's), in document order. */
  get groups(): HTMLElement[] {
    return this.parts('group')
  }

  /** The separators between its groups (the styled component's). */
  get separators(): HTMLElement[] {
    return this.parts('separator')
  }

  /** The input's accessible name: its label, `aria-label` or `aria-labelledby`. */
  get label(): string {
    return controlLabel(this.input)
  }

  /** The text of what its `aria-describedby` names, or `''`. */
  get description(): string {
    return controlDescription(this.input)
  }

  /** Whether it is `disabled`. */
  get isDisabled(): boolean {
    return this.input.disabled
  }

  /** Whether a form needs it filled (`required`). */
  get isRequired(): boolean {
    return this.input.required
  }

  /** Whether it is marked invalid: `aria-invalid` on the input, or on any slot (as upstream's example marks it). */
  get isInvalid(): boolean {
    return isMarkedInvalid(this.input) || this.slots.some(slot => isMarkedInvalid(slot))
  }

  /** Whether the input has focus. */
  get isFocused(): boolean {
    return this.input.ownerDocument.activeElement === this.input
  }

  /** Moves focus to it, as tabbing does: the selection goes to the last character, or after it. */
  async focus(): Promise<void> {
    await focus(this.input)
  }

  /** Moves focus away. */
  async blur(): Promise<void> {
    await blur(this.input)
  }

  /** Replaces the whole code, in one `input` event, as `fillIn` does an input's value. */
  async fillIn(code: string): Promise<void> {
    await fillIn(this.input, code)
  }

  /** Empties it. */
  async clear(): Promise<void> {
    await fillIn(this.input, '')
  }

  /**
   * Types `text` a key at a time into the selection, as a browser does: each key replaces the
   * selected character (or goes after the caret), within `maxlength`. It focuses the input first.
   */
  async typeIn(text: string): Promise<void> {
    if (!this.isFocused) await this.focus()
    for (const character of text) {
      const input = this.input
      const down = keyEvent(input, 'keydown', character)
      if (!down.defaultPrevented) insert(input, character, 'insertText')
      keyEvent(input, 'keyup', character)
      await settled()
    }
  }

  /**
   * Presses a key that edits or moves through the code, as a browser does in a text input:
   * Backspace and Delete delete, the arrows, Home and End move the caret (left to right).
   */
  async press(key: InputOTPKey): Promise<void> {
    if (!this.isFocused) await this.focus()
    const input = this.input
    const down = keyEvent(input, 'keydown', key)
    if (!down.defaultPrevented) {
      if (key === 'Backspace' || key === 'Delete') remove(input, key === 'Delete')
      else move(input, key)
    }
    keyEvent(input, 'keyup', key)
    await settled()
  }

  /** Puts the caret before one character, as clicking that slot does. */
  async clickSlot(index: number): Promise<void> {
    if (!this.isFocused) await this.focus()
    const input = this.input
    const caret = Math.min(index, input.value.length)
    input.setSelectionRange(caret, caret)
    selectionMoved(input)
    await settled()
  }

  /** Pastes `text` from the clipboard into the selection, as Ctrl+V does. It focuses the input first. */
  async paste(text: string): Promise<void> {
    if (!this.isFocused) await this.focus()
    const clipboardData = new DataTransfer()
    clipboardData.setData('text/plain', text)
    const event = new ClipboardEvent('paste', { clipboardData, bubbles: true, cancelable: true })
    const input = this.input
    if (input.dispatchEvent(event)) insert(input, text, 'insertFromPaste')
    await settled()
  }

  /**
   * Fills the whole code in, as a browser's autofill does with a code it was sent: the value at
   * once, then an `input` event with no typing, and `change`. It doesn't move focus.
   */
  async autofill(code: string): Promise<void> {
    const input = this.input
    input.value = code
    input.dispatchEvent(new Event('input', { bubbles: true }))
    input.dispatchEvent(new Event('change', { bubbles: true }))
    await settled()
  }
}

/**
 * Fills an OTP input with `code`, as ember-primitives' `fillOTP` does: the only `InputOTP` in
 * the test, or the one in `within` (a selector or an element) when there are several.
 *
 *   await fillOTP('123456')
 *   await fillOTP('123456', '[data-test-login]')
 */
export async function fillOTP(code: string, within?: string | Element): Promise<void> {
  const scope = typeof within === 'string' ? find(within) : (within ?? getRootElement())
  if (!scope) throw new Error(`fillOTP: nothing matches ${String(within)}`)
  const component = selectors.component('input-otp')
  const root =
    scope instanceof Element && scope.matches(component) ? scope : scope.querySelector(component)
  if (!root) throw new Error('fillOTP: no InputOTP found')
  const input = root.querySelector<HTMLInputElement>(selectors.part('input'))
  if (!input) throw new Error('fillOTP: the InputOTP has no input')
  await fillIn(input, code)
}
