import { blur, fillIn, focus, triggerEvent, typeIn } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { controlDescription, controlLabel, isMarkedInvalid } from './-private/control.ts'

/**
 * Drives an `<Input>` from `@ember-joinery/ember`, or an `<input>` made one with its `asInput`
 * modifier. State comes from the element and its ARIA; it types the way a user does.
 *
 *   const email = new InputHarness('email') // <Input @name="email">
 *   await email.fillIn('ada@example.com')
 *   assert.strictEqual(email.value, 'ada@example.com')
 *   assert.strictEqual(email.label, 'Email')
 */
export class InputHarness extends Harness {
  static override component = 'input'

  /** The `<input>` itself. */
  get control(): HTMLInputElement {
    return this.element as HTMLInputElement
  }

  /** What it holds now. */
  get value(): string {
    return this.control.value
  }

  /** Its `type`: `text` (the default), `email`, `password`, `file`… */
  get type(): string {
    return this.control.type
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

  /** For a file input, the names of the files chosen. */
  get fileNames(): string[] {
    return [...(this.control.files ?? [])].map(file => file.name)
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

  /** For a file input, chooses `files`, as the file picker does (a `change` event). */
  async chooseFiles(files: File[]): Promise<void> {
    await triggerEvent(this.control, 'change', { files })
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
