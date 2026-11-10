import { InputHarness, SelectHarness } from '@ember-joinery/test-support'
import { Harness } from '@ember-joinery/test-support'
import { backspace, pasteText, typeText } from './-private/typing.ts'

/**
 * Drives a `<PhoneInput>` from `@ember-joinery/maskito`: its input (an `InputHarness`) and its
 * country picker (a `SelectHarness`). It reads what the input shows, masked, and the country
 * chosen; the number it stores, in E.164 form, is what `@onValueChange` hears.
 *
 *   const phone = new PhoneInputHarness('phone') // <PhoneInput @name="phone">
 *   await phone.selectCountry('GB')
 *   await phone.typeText('7911123456')
 *   assert.strictEqual(phone.value, '+44 7911 123456')
 *   assert.strictEqual(phone.country, 'GB')
 */
export class PhoneInputHarness extends Harness {
  static override component = 'phone-input'

  /** The input, as an `InputHarness`: its `label`, `description`, `isInvalid`, `fillIn()`… */
  get input(): InputHarness {
    return this.child(InputHarness)
  }

  /** The country picker, as a `SelectHarness`: its `options`, `open()`, `typeahead()`… */
  get picker(): SelectHarness {
    return this.child(SelectHarness, 'country')
  }

  /** The `<input type="tel">` itself. */
  get control(): HTMLInputElement {
    return this.input.control
  }

  /** The Input Group around the input and the picker. */
  get group(): HTMLElement {
    return this.picker.part('group')
  }

  /** What the input shows, masked: `+1 212 555-0123`. */
  get value(): string {
    return this.control.value
  }

  /** The country shown, as its ISO 3166 code (`US`). */
  get country(): string {
    return this.element.getAttribute('data-test-jn-value') ?? ''
  }

  /** The name of the country shown, as the picker reads it to assistive technology. */
  get countryName(): string {
    return this.picker.part('country-name').textContent?.trim() ?? ''
  }

  /** The flag the picker shows. */
  get flag(): string {
    return this.picker.trigger.querySelector('.jn-phone-input-flag')?.textContent?.trim() ?? ''
  }

  /** The calling code beside the flag (`+1`), in the national format; `''` otherwise. */
  get callingCode(): string {
    return this.picker.queryPart('calling-code')?.textContent?.trim() ?? ''
  }

  /** The input's accessible name. */
  get label(): string {
    return this.input.label
  }

  /** The text of what the input's `aria-describedby` names. */
  get description(): string {
    return this.input.description
  }

  /** The input's placeholder. */
  get placeholder(): string {
    return this.input.placeholder
  }

  /** Whether the input and the picker are disabled. */
  get isDisabled(): boolean {
    return this.input.isDisabled && this.picker.isDisabled
  }

  /** Whether the input is marked invalid (`aria-invalid`), which rings the whole group. */
  get isInvalid(): boolean {
    return this.input.isInvalid
  }

  /** Whether the input has focus. */
  get isFocused(): boolean {
    return this.input.isFocused
  }

  /** The country codes the picker offers, in order. It opens the picker to read them. */
  async countries(): Promise<string[]> {
    if (!this.picker.isOpen) await this.picker.open()
    return this.picker.options
  }

  /** Opens the picker and chooses the country with this ISO 3166 code. */
  async selectCountry(code: string): Promise<void> {
    await this.picker.select(code)
  }

  /** Types `text` at the end, one character at a time, as a keyboard does. */
  async typeText(text: string): Promise<void> {
    await typeText(this.control, text)
  }

  /** Presses Backspace at the end, `times` times. */
  async backspace(times = 1): Promise<void> {
    await backspace(this.control, times)
  }

  /** Selects everything and pastes `text` over it; an international number switches country. */
  async paste(text: string): Promise<void> {
    await pasteText(this.control, text)
  }

  /** Replaces the text at once, as autofill does; the mask shapes it. */
  async fillIn(text: string): Promise<void> {
    await this.input.fillIn(text)
  }

  /** Empties the input. */
  async clear(): Promise<void> {
    await this.input.fillIn('')
  }

  /** Moves focus to the input. */
  async focus(): Promise<void> {
    await this.input.focus()
  }
}
