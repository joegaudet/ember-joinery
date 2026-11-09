import { Harness } from './harness.ts'

/**
 * Drives a `<Separator>`, from `@ember-joinery/ember` or `@ember-joinery/primitives/separator`.
 * Everything comes from its ARIA, and `data-orientation` for a decorative one, which has none.
 *
 *   const separator = new SeparatorHarness()
 *   assert.strictEqual(separator.orientation, 'vertical')
 *   assert.true(separator.isDecorative)
 */
export class SeparatorHarness extends Harness {
  static override component = 'separator'

  /**
   * Its role as assistive technology sees it: `separator` (an `<hr>`'s own, or `role`), or
   * `none` for a decorative one.
   */
  get role(): string | null {
    const element = this.element
    const role = element.getAttribute('role')
    if (role) return role
    return element.localName === 'hr' ? 'separator' : null
  }

  /** Whether assistive technology skips it: `role="none"`, or `aria-hidden="true"`. */
  get isDecorative(): boolean {
    const element = this.element
    const role = element.getAttribute('role')
    return (
      role === 'none' || role === 'presentation' || element.getAttribute('aria-hidden') === 'true'
    )
  }

  /**
   * Which way it runs: `horizontal` or `vertical`. A semantic separator's `aria-orientation`
   * (horizontal when it has none, as the role's default), or a decorative one's
   * `data-orientation`.
   */
  get orientation(): 'horizontal' | 'vertical' {
    const element = this.element
    const value =
      (this.isDecorative ? null : element.getAttribute('aria-orientation')) ??
      element.getAttribute('data-orientation')
    return value === 'vertical' ? 'vertical' : 'horizontal'
  }
}
