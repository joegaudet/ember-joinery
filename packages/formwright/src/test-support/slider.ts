import { FieldHarness } from '@ember-formwright/test-support'
import { SliderHarness } from '@ember-joinery/test-support'

/**
 * A `slider` (or `range`) field, Joinery's Slider: `value`, and its thumbs driven by key
 * (`press('ArrowRight')`) or pointer (`slideTo(percent)`) through Joinery's `SliderHarness`.
 */
export class SliderFieldHarness extends FieldHarness {
  static override controls = ['slider', 'range']

  /** Joinery's harness for the field's Slider. */
  get slider(): SliderHarness {
    return new SliderHarness({ within: this.element })
  }

  /** Each thumb's value, in order. */
  get value(): number[] {
    return this.slider.value
  }

  /** Presses a key on a thumb (default the first): `ArrowRight`, `PageUp`, `Home`… */
  async press(key: string, thumb = 0): Promise<void> {
    await this.slider.press(key, { thumb })
  }

  /** Presses the track at `percent` of its length, so the nearest thumb moves there. */
  async slideTo(percent: number): Promise<void> {
    await this.slider.slideTo(percent)
  }
}
