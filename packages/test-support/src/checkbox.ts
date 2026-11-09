import { blur, click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { accessibleName, hiddenInputOf, isDisabled, isInvalid } from './-private/checkable.ts'

/**
 * Drives a `<Checkbox>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/checkbox`. State comes from its ARIA: `aria-checked` (`mixed`
 * while indeterminate), `aria-required` and `aria-invalid`.
 *
 *   const terms = new CheckboxHarness('terms') // <Checkbox @name="terms">
 *   await terms.check()
 *   assert.true(terms.isChecked)
 */
export class CheckboxHarness extends Harness {
  static override component = 'checkbox'

  /** `checked`, `unchecked` or `indeterminate`, from `aria-checked`. */
  get state(): 'checked' | 'unchecked' | 'indeterminate' {
    const checked = this.element.getAttribute('aria-checked')
    if (checked === 'mixed') return 'indeterminate'
    return checked === 'true' ? 'checked' : 'unchecked'
  }

  /** Whether it is checked (`aria-checked="true"`); an indeterminate one isn't. */
  get isChecked(): boolean {
    return this.state === 'checked'
  }

  /** Whether it is indeterminate (`aria-checked="mixed"`). */
  get isIndeterminate(): boolean {
    return this.state === 'indeterminate'
  }

  /** Its accessible name: `aria-label`, `aria-labelledby`, or its `<label>`'s text. */
  get label(): string {
    return accessibleName(this.element)
  }

  /** Whether it can't be changed. */
  get isDisabled(): boolean {
    return isDisabled(this.element)
  }

  /** Whether a form needs it checked (`aria-required="true"`). */
  get isRequired(): boolean {
    return this.element.getAttribute('aria-required') === 'true'
  }

  /** Whether it is marked invalid (`aria-invalid`). */
  get isInvalid(): boolean {
    return isInvalid(this.element)
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  /** Its mark, while it shows (checked or indeterminate), or `null`. */
  get indicator(): HTMLElement | null {
    return this.queryPart('indicator')
  }

  /** The hidden native checkbox it renders in a form, which the form submits, or `null`. */
  get input(): HTMLInputElement | null {
    return hiddenInputOf(this.element)
  }

  /** Clicks it, as a user would: it toggles (an indeterminate one becomes checked). */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Toggles it with a click. */
  async toggle(): Promise<void> {
    await this.click()
  }

  /** Clicks it unless it is checked already. */
  async check(): Promise<void> {
    if (!this.isChecked) await this.click()
  }

  /** Clicks it until it is unchecked: twice from indeterminate, which a click checks first. */
  async uncheck(): Promise<void> {
    for (let clicks = 0; clicks < 2 && this.state !== 'unchecked'; clicks++) await this.click()
  }

  /** Moves focus to it, as tabbing to it would. */
  async focus(): Promise<void> {
    await focus(this.element)
  }

  /** Moves focus away from it. */
  async blur(): Promise<void> {
    await blur(this.element)
  }
}
