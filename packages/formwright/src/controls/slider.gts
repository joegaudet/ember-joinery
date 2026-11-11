import Component from '@glimmer/component'
import type { ControlSignature, RangeArgs } from '@ember-formwright/ember'
import { Slider, defaultSliderThumbLabel } from '@ember-joinery/primitives/slider'
import { toNumber } from '../-private/options.ts'

export interface SliderControlSignature {
  Args: ControlSignature<number | number[] | null>['Args'] &
    RangeArgs & {
      /** Called once a drag or a key press ends, with the value it ended on, as Slider's. */
      onValueCommit?: (value: number[]) => void
      /** The Slider's `@orientation`: `horizontal` (the default) or `vertical`. */
      orientation?: 'horizontal' | 'vertical'
    }
  /** The Slider's root (size it with a class); the field's id is on its first thumb. */
  Element: HTMLElement
}

/**
 * Joinery's Slider as a Formwright control, `@control="slider"` (and `range`): a number, or a
 * range when the field's value is a list (`[25, 75]`, one thumb each), between `@min` and
 * `@max` (0 to 100 by default) in steps of `@step`. Each thumb is named after the field's
 * label, since a `<label>` can't name a `role="slider"`, and each is described by the field's
 * hint and errors and `aria-invalid` while the field is: the thumbs take the focus, so they
 * carry what a field puts on its control, and the first takes the field's id.
 *
 * It renders Joinery's Slider markup on the primitive itself (the styled Slider's classes and
 * `data-slot`s, which a test holds to the styled one), since the styled Slider passes nothing
 * to its thumbs.
 */
export class SliderControl extends Component<SliderControlSignature> {
  get isRange(): boolean {
    return Array.isArray(this.args.value)
  }

  get min(): number {
    return toNumber(this.args.min) ?? 0
  }

  get values(): number[] {
    const value = this.args.value
    if (Array.isArray(value)) return value
    return [value ?? this.min]
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled || this.args.readonly)
  }

  thumbLabel = (index: number, count: number): string => {
    const label = this.args.label
    if (!label) return defaultSliderThumbLabel(index, count)
    return count === 1 ? label : `${label}, ${defaultSliderThumbLabel(index, count)}`
  }

  /** The field's id goes on the first thumb, the element its label and Formwright focus. */
  thumbId = (index: number): string | undefined => (index === 0 ? this.args.id : undefined)

  onValueChange = (values: number[]): void => {
    this.args.onChange(this.isRange ? values : (values[0] ?? null))
  }

  <template>
    <Slider
      @value={{this.values}}
      @onValueChange={{this.onValueChange}}
      @onValueCommit={{@onValueCommit}}
      @min={{toNumber @min}}
      @max={{toNumber @max}}
      @step={{toNumber @step}}
      @orientation={{@orientation}}
      @disabled={{this.disabled}}
      @getThumbLabel={{this.thumbLabel}}
      @fieldName={{@name}}
      class="jn-slider"
      data-slot="slider"
      data-test-fw-control={{@type}}
      ...attributes
      as |s|
    >
      <s.Track class="jn-slider-track" data-slot="slider-track">
        <s.Range class="jn-slider-range" data-slot="slider-range" />
      </s.Track>
      {{#each s.thumbs as |thumb|}}
        <s.Thumb
          @index={{thumb.index}}
          id={{this.thumbId thumb.index}}
          aria-describedby={{@describedBy}}
          aria-invalid={{if @invalid "true"}}
          class="jn-slider-thumb"
          data-slot="slider-thumb"
        />
      {{/each}}
    </Slider>
  </template>
}
