import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Slider } from '@ember-joinery/ember'
import { defaultSliderThumbLabel } from '@ember-joinery/primitives/slider'
import { toNumber } from '../-private/options.ts'

export interface SliderControlSignature {
  Args: ControlSignature<number | number[] | null>['Args'] & {
    /** Called once a drag or a key press ends, with the value it ended on, as Slider's. */
    onValueCommit?: (value: number[]) => void
    /** The Slider's `@orientation`: `horizontal` (the default) or `vertical`. */
    orientation?: 'horizontal' | 'vertical'
  }
  /** The Slider's root, which takes the field's id. */
  Element: HTMLElement
}

/**
 * Joinery's Slider as a Formwright control, `@control="slider"` (and `range`): a number, or a
 * range when the field's value is a list (`[25, 75]`, one thumb each), between `@min` and
 * `@max` (0 to 100 by default) in steps of `@step`. Each thumb is named after the field's
 * label, since a `<label>` can't name a `role="slider"`.
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
      id={{@id}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
    />
  </template>
}
