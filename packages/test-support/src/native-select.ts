import { blur, focus, select } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { controlDescription, controlLabel, isMarkedInvalid, textOf } from './-private/control.ts'

/**
 * Drives a `<NativeSelect>` from `@ember-joinery/ember`: the browser's own `<select>`, so it
 * chooses an option the way the browser's menu does (`input` and `change` events). State comes
 * from the element and its ARIA.
 *
 *   const status = new NativeSelectHarness('status') // <NativeSelect @name="status">
 *   await status.select('done')
 *   assert.strictEqual(status.value, 'done')
 *   assert.strictEqual(status.selectedText, 'Done')
 */
export class NativeSelectHarness extends Harness {
  static override component = 'native-select'

  /** The `<select>` itself (its root is the wrapper around it). */
  get control(): HTMLSelectElement {
    return this.part<HTMLSelectElement>('select')
  }

  /** The icon at its end. */
  get icon(): SVGSVGElement {
    return this.part<SVGSVGElement>('icon')
  }

  /** The value of the option chosen now (`''` for none). */
  get value(): string {
    return this.control.value
  }

  /** The text of the option chosen now, or `''` for none. */
  get selectedText(): string {
    const option = this.control.selectedOptions[0]
    return option ? textOf(option) : ''
  }

  /** Every option's value, in order. */
  get options(): string[] {
    return [...this.control.options].map(option => option.value)
  }

  /** Every option's text, in order. */
  get optionTexts(): string[] {
    return [...this.control.options].map(textOf)
  }

  /** Every group's `label`, in order. */
  get groups(): string[] {
    return [...this.control.querySelectorAll('optgroup')].map(group => group.label)
  }

  /** The values of the options in the group with this `label`, in order. */
  optionsIn(group: string): string[] {
    const found = [...this.control.querySelectorAll('optgroup')].find(
      candidate => candidate.label === group,
    )
    return found ? [...found.querySelectorAll('option')].map(option => option.value) : []
  }

  /** Whether the option with this value can't be chosen (it, or its group, is `disabled`). */
  isOptionDisabled(value: string): boolean {
    const option = [...this.control.options].find(candidate => candidate.value === value)
    if (!option) throw new Error(`Joinery harness: no option "${value}" in ${this}`)
    return option.disabled || Boolean(option.closest('optgroup')?.disabled)
  }

  /** Its `@size`: `default` or `sm`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /**
   * Its accessible name, as assistive technology reads it: `aria-labelledby`'s text, else
   * `aria-label`, else its `<label>`'s text, else `title`.
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

  /** Chooses the option with this value. Fails when the select is disabled, as a user can't. */
  async select(value: string): Promise<void> {
    await select(this.control, value)
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
