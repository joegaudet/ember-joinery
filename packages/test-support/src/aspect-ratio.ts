import { Harness } from './harness.ts'
import { borderBox as size } from './-private/size.ts'

/**
 * Drives an `<AspectRatio>`, from `@ember-joinery/ember` or
 * `@ember-joinery/primitives/aspect-ratio`. Its element is the inner box, which holds the
 * content and takes the ratio.
 *
 *   const photo = new AspectRatioHarness()
 *   assert.strictEqual(Math.round(photo.ratio * 100) / 100, 1.78) // 16 / 9
 */
export class AspectRatioHarness extends Harness {
  static override component = 'aspect-ratio'

  /** Its width over its height, as laid out. `NaN` while it takes no space. */
  get ratio(): number {
    const { width, height } = size(this.element)
    return height ? width / height : Number.NaN
  }

  /** Its laid-out width, border included, in CSS pixels (a transform on the page doesn't change it). */
  get width(): number {
    return size(this.element).width
  }

  /** Its laid-out height, border included, in CSS pixels. */
  get height(): number {
    return size(this.element).height
  }

  /** The outer box, which holds the ratio, around the element. */
  get wrapper(): HTMLElement {
    return this.element.parentElement!
  }
}
