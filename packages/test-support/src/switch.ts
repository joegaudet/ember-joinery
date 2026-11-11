import { blur, click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { accessibleName, hiddenInputOf, isDisabled, isInvalid } from './-private/checkable.ts'

/**
 * Drives a `<Switch>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/switch`. State comes from its ARIA: `aria-checked`,
 * `aria-required` and `aria-invalid`.
 *
 *   const airplane = new SwitchHarness('airplane-mode') // <Switch @name="airplane-mode">
 *   await airplane.toggle()
 *   assert.true(airplane.isChecked)
 */
export class SwitchHarness extends Harness {
  static override component = 'switch'

  /** Whether it is on (`aria-checked="true"`). */
  get isChecked(): boolean {
    return this.element.getAttribute('aria-checked') === 'true'
  }

  /** Its accessible name: `aria-label`, `aria-labelledby`, or its `<label>`'s text. */
  get label(): string {
    return accessibleName(this.element)
  }

  /** Its `@size`, `default` or `sm`, for the styled switch; `null` for the headless one. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** Whether it can't be changed. */
  get isDisabled(): boolean {
    return isDisabled(this.element)
  }

  /** Whether a form needs it on (`aria-required="true"`). */
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

  /** The part that slides, or `null` when a headless switch renders none. */
  get thumb(): HTMLElement | null {
    return this.queryPart('thumb')
  }

  /** The hidden native checkbox it renders in a form, which the form submits, or `null`. */
  get input(): HTMLInputElement | null {
    return hiddenInputOf(this.element)
  }

  /** Clicks it, as a user would: it toggles. */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Toggles it with a click. */
  async toggle(): Promise<void> {
    await this.click()
  }

  /** Clicks it unless it is on already. */
  async check(): Promise<void> {
    if (!this.isChecked) await this.click()
  }

  /** Clicks it if it is on. */
  async uncheck(): Promise<void> {
    if (this.isChecked) await this.click()
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
