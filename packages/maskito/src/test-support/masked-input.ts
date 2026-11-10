import { InputHarness } from '@ember-joinery/test-support'
import {
  backspace,
  deleteForward,
  dropText,
  pasteText,
  redo,
  typeText,
  undo,
} from './-private/typing.ts'

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

  /**
   * Presses Delete `times` times with the caret at `at` (a character's index); the mask steps
   * over its fixed characters.
   */
  async deleteForward(at: number, times = 1): Promise<void> {
    await deleteForward(this.control, at, times)
  }

  /** Selects everything and pastes `text` over it, as a user does. */
  async paste(text: string): Promise<void> {
    await pasteText(this.control, text)
  }

  /** Drops `text` at the end, as a drag and drop does; the mask shapes it. */
  async drop(text: string): Promise<void> {
    await dropText(this.control, text)
  }

  /** Presses Ctrl+Z: the mask undoes the last edit. */
  async undo(): Promise<void> {
    await undo(this.control)
  }

  /** Presses Ctrl+Shift+Z: the mask redoes the edit undone last. */
  async redo(): Promise<void> {
    await redo(this.control)
  }
}
