import { Harness } from './harness.ts'

/** Drives a `<Spinner>` from `@ember-joinery/ember`: a loading indicator with the `status` role. */
export class SpinnerHarness extends Harness {
  static override component = 'spinner'

  /** What it announces: its `aria-label` (`Loading` unless given `@label`). */
  get label(): string {
    return this.element.getAttribute('aria-label') ?? ''
  }

  /** Its role, `status`, so screen readers announce it. */
  get role(): string | null {
    return this.element.getAttribute('role')
  }
}
