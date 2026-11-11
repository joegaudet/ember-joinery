import { FieldHarness } from '@ember-formwright/test-support'
import { RatingHarness } from '@ember-joinery/test-support'

/**
 * A `rating` field, Joinery's Rating: `value` (`null` for none), `select(value)`, and its
 * stars' keyboard (`press('ArrowRight')`) through Joinery's `RatingHarness`.
 *
 *   class ReviewForm extends FormHarness {
 *     @field(RatingFieldHarness) declare stars: RatingFieldHarness
 *   }
 *
 *   await review.stars.select(4)
 *   assert.strictEqual(review.stars.value, 4)
 */
export class RatingFieldHarness extends FieldHarness {
  static override controls = ['rating']

  /** Joinery's harness for the field's Rating: its stars, their radios and its keyboard. */
  get rating(): RatingHarness {
    return new RatingHarness({ within: this.element })
  }

  /** The rating picked, or `null` for none. */
  get value(): number | null {
    return this.rating.value || null
  }

  /** Each star's value, in order. */
  get options(): number[] {
    return this.rating.options
  }

  /** Each star as `★` while the rating reaches it, `☆` otherwise: `★ ★ ★ ☆ ☆`. */
  get stars(): string {
    return this.rating.stars
  }

  /** Picks this rating, as a click on its star does: picking the current one clears it. */
  async select(value: number): Promise<void> {
    await this.rating.select(value)
  }

  /** Presses a key on the focused star: the arrow keys move and pick, Space picks. */
  async press(key: string): Promise<void> {
    await this.rating.press(key)
  }

  /** Focuses the checked star, or the first, as Tab does. */
  async focus(): Promise<void> {
    await this.rating.focus()
  }
}
