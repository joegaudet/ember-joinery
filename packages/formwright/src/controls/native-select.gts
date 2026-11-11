import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { NativeSelect, type NativeSelectSize } from '@ember-joinery/ember'
import {
  isEmpty,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
} from '../-private/options.ts'

export interface NativeSelectControlSignature {
  Args: ControlSignature['Args'] & {
    /** NativeSelect's `@size`: `default` or `sm`. */
    size?: NativeSelectSize
  }
  Element: HTMLSelectElement
}

/**
 * Joinery's Native Select as a Formwright control, `@control="native-select"`: a native
 * `<select>` of the field's `@options`, after an empty option that shows `@placeholder`. It
 * stores the option chosen (or its key, with `@storeKey`), or `null` for the empty option.
 */
export class NativeSelectControl extends Component<NativeSelectControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get selected(): unknown {
    return this.options.find(option => matches(this.args.value, option, this.args.optionKey))
  }

  get value(): string {
    if (isEmpty(this.args.value)) return ''
    const selected = this.selected
    return selected === undefined ? '' : this.keyFor(selected)
  }

  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  isDisabled = (option: unknown): boolean => isOptionDisabled(option)

  choose = (key: string): void => {
    const option = this.options.find(o => this.keyFor(o) === key)
    this.args.onChange(
      option === undefined ? null : toStored(option, this.args.storeKey, this.args.optionKey),
    )
  }

  <template>
    <NativeSelect
      @value={{this.value}}
      @onValueChange={{this.choose}}
      @size={{@size}}
      id={{@id}}
      name={{@name}}
      disabled={{if @readonly true @disabled}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      as |s|
    >
      <s.Option @value="" disabled={{@required}}>{{@placeholder}}</s.Option>
      {{#each this.options as |option|}}
        <s.Option
          @value={{this.keyFor option}}
          disabled={{this.isDisabled option}}
          data-test-fw-option={{this.keyFor option}}
        >{{this.labelFor option}}</s.Option>
      {{/each}}
    </NativeSelect>
  </template>
}
