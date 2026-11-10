import { InputHarness } from '@ember-joinery/test-support'
import { backspace, pasteText, typeText } from './-private/typing.ts'

/**
 * Drives a `<MaskedInput>` from `@ember-joinery/maskito`. It is an `InputHarness` (its `value`,
 * `label`, `fillIn()` and the rest), and it types the way a browser does, so the mask answers
 * each keystroke as it would a user's.
 *
 *   const price = new MaskedInputHarness('price') // <MaskedInput @name="price">
 *   await price.typeText('1234.5')
 *   assert.strictEqual(price.value, '1,234.5')
 *
 * `fillIn()` replaces the text at once, as autofill does, and the mask shapes the result.
 */
export class MaskedInputHarness extends InputHarness {
  static override component = 'masked-input'

  /**
   * Types `text` at the end, one character at a time, each with the `beforeinput` and `input`
   * a keyboard sends; the mask turns away what doesn't fit.
   */
  async typeText(text: string): Promise<void> {
    await typeText(this.control, text)
  }

  /** Presses Backspace at the end, `times` times; the mask steps over its fixed characters. */
  async backspace(times = 1): Promise<void> {
    await backspace(this.control, times)
  }

  /** Selects everything and pastes `text` over it, as a user does. */
  async paste(text: string): Promise<void> {
    await pasteText(this.control, text)
  }
}
