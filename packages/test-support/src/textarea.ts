import { blur, fillIn, focus, typeIn } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { controlDescription, controlLabel, isMarkedInvalid } from './-private/control.ts'

/**
 * Drives a `<Textarea>` from `@ember-joinery/ember`, or a `<textarea>` made one with its
 * `asTextarea` modifier. State comes from the element and its ARIA; it types the way a user
 * does.
 *
 *   const message = new TextareaHarness('message') // <Textarea @name="message">
 *   await message.fillIn('Hello')
 *   assert.strictEqual(message.value, 'Hello')
 */
export class TextareaHarness extends Harness {
  static override component = 'textarea'

  /** The `<textarea>` itself. */
  get control(): HTMLTextAreaElement {
    return this.element as HTMLTextAreaElement
  }

  /** What it holds now. */
  get value(): string {
    return this.control.value
  }

  /** Its `placeholder`, or `''`. */
  get placeholder(): string {
    return this.control.placeholder
  }

  /**
   * Its accessible name, as assistive technology reads it: `aria-labelledby`'s text, else
   * `aria-label`, else its `<label>`'s text, else `title`, else `placeholder`.
   */
  get label(): string {
    return controlLabel(this.control)
  }

  /** The text of what its `aria-describedby` names (a field's description and errors), or `''`. */
  get description(): string {
    return controlDescription(this.control)
  }

  /** Whether it is `disabled`. */
  get isDisabled(): boolean {
    return this.control.disabled
  }

  /** Whether it is `readonly`. */
  get isReadOnly(): boolean {
    return this.control.readOnly
  }

  /** Whether it is `required`. */
  get isRequired(): boolean {
    return this.control.required
  }

  /** Whether it is marked invalid with `aria-invalid`. */
  get isInvalid(): boolean {
    return isMarkedInvalid(this.control)
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.control.ownerDocument.activeElement === this.control
  }

  /** Replaces what it holds with `text`, as pasting does: one `input` event, then `change`. */
  async fillIn(text: string): Promise<void> {
    await fillIn(this.control, text)
  }

  /** Types `text` one key at a time after what it holds, as a user does. */
  async typeIn(text: string): Promise<void> {
    await typeIn(this.control, text)
  }

  /** Empties it. */
  async clear(): Promise<void> {
    await fillIn(this.control, '')
  }

  /** Moves focus to it, as tabbing to it would. Fails if it can't take focus. */
  async focus(): Promise<void> {
    await focus(this.control)
  }

  /** Moves focus away from it. */
  async blur(): Promise<void> {
    await blur(this.control)
  }
}
