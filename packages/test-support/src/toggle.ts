import { ButtonHarness } from './button.ts'

/**
 * Drives a `<Toggle>` from `@ember-joinery/ember`, the primitives' `Toggle`, or an element made
 * a toggle with `asToggle`. It is a button (every `ButtonHarness` member works: `variant` is
 * `default` or `outline`, `size` `default`, `sm` or `lg`), whose pressed state is read from
 * `aria-pressed`.
 *
 *   const bold = new ToggleHarness('bold') // <Toggle @name="bold">
 *   await bold.toggle()
 *   assert.true(bold.isPressed)
 */
export class ToggleHarness extends ButtonHarness {
  static override component = 'toggle'

  /** Whether it is pressed (`aria-pressed="true"`). */
  override get isPressed(): boolean {
    return this.element.getAttribute('aria-pressed') === 'true'
  }

  /** Radix's `data-state`: `on` or `off`. */
  get state(): string | null {
    return this.element.getAttribute('data-state')
  }

  /** Presses it, as a click does: on becomes off, and off on. */
  async toggle(): Promise<void> {
    await this.click()
  }
}
