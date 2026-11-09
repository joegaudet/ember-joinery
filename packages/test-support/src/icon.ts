import { Harness } from './harness.ts'

/** Drives an `<Icon>` from `@ember-joinery/ember`. */
export class IconHarness extends Harness {
  static override component = 'icon'

  /** What the icon means (`@label`), or `null` for a decorative icon. */
  get label(): string | null {
    return this.element.getAttribute('aria-label')
  }

  /** Whether assistive technology skips it: an icon without `@label`. */
  get isDecorative(): boolean {
    return this.element.getAttribute('aria-hidden') === 'true'
  }
}
