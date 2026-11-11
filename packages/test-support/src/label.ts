import { click } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Label>`, from `@ember-joinery/ember` or `@ember-joinery/primitives/label`.
 *
 *   const email = new LabelHarness('email')
 *   assert.strictEqual(email.text, 'Your email address')
 *   assert.strictEqual(email.control, find('#email'))
 *   await email.click() // focuses the input, as a press on a label does
 */
export class LabelHarness extends Harness {
  static override component = 'label'

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /**
   * The control it labels, as the browser works it out: the element its `for` names, or the
   * first control inside it. `null` when it labels nothing (or isn't a `<label>`).
   */
  get control(): HTMLElement | null {
    const element = this.element
    return element instanceof HTMLLabelElement ? element.control : null
  }

  /** Whether the control it labels is disabled, which dims the label. */
  get isControlDisabled(): boolean {
    const control = this.control
    if (!control) return false
    return ('disabled' in control && Boolean(control.disabled)) || control.matches(':disabled')
  }

  /** Clicks it, as a user would: the browser passes the click to its control. */
  async click(): Promise<void> {
    await click(this.element)
  }
}
