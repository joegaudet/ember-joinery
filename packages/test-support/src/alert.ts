import { Harness } from './harness.ts'

function text(element: Element | null): string {
  return (element?.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives an `<Alert>` from `@ember-joinery/ember`. It reads the title and description, and
 * finds what is inside, such as the action's button, with `find()`:
 *
 *   const alert = new AlertHarness('payment') // <Alert @name="payment">
 *   assert.strictEqual(alert.title, 'Payment failed')
 *   await alert.find(ButtonHarness).click()
 */
export class AlertHarness extends Harness {
  static override component = 'alert'

  /** All the text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /** Its title's text, or `''` without one. */
  get title(): string {
    return text(this.queryPart('title'))
  }

  /** Its description's text, or `''` without one. */
  get description(): string {
    return text(this.queryPart('description'))
  }

  /** Its `@variant`: `default` or `destructive`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Its role: `alert`, as upstream's, unless given another (`role="status"`). */
  get role(): string | null {
    return this.element.getAttribute('role')
  }

  /** Whether it shows an icon: an `<svg>` of its own, before its text. */
  get hasIcon(): boolean {
    return this.element.querySelector(':scope > svg') !== null
  }

  /** The action's container, where its button goes. Throws when it has none. */
  get action(): HTMLElement {
    return this.part('action')
  }
}
