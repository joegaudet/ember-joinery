import { Harness } from './harness.ts'
import { borderBox } from './-private/size.ts'

/**
 * Drives a `<Skeleton>` from `@ember-joinery/ember`: a placeholder shown while content loads.
 * It has no ARIA of its own (mark the region that is loading with `aria-busy`), so a test
 * counts and measures them.
 *
 *   assert.strictEqual(SkeletonHarness.findAll().length, 3)
 */
export class SkeletonHarness extends Harness {
  static override component = 'skeleton'

  /** Its laid-out width, border included, in CSS pixels (a transform on the page doesn't change it). */
  get width(): number {
    return borderBox(this.element).width
  }

  /** Its laid-out height, border included, in CSS pixels. */
  get height(): number {
    return borderBox(this.element).height
  }

  /** Whether it pulses: its animation runs (a `prefers-reduced-motion` rule of yours can stop it). */
  get isPulsing(): boolean {
    const style = getComputedStyle(this.element)
    return style.animationName !== 'none' && style.animationDuration !== '0s'
  }
}
