import Component from '@glimmer/component'
import type { ControlSignature, OptionArgs } from '@ember-formwright/ember'
import { Combobox } from '@ember-joinery/ember'
import {
  isEmpty,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
} from '../-private/options.ts'

export interface ComboboxControlSignature {
  Args: ControlSignature['Args'] &
    OptionArgs & {
      /** What the list says when no option matches what was typed. Default `No items found.` */
      emptyText?: string
      /** Shows a button that clears the choice, as Combobox's input's `@showClear`. */
      showClear?: boolean
    }
  /** The combobox's input, which the field's label names. */
  Element: HTMLInputElement
}

/**
 * Joinery's Combobox as a Formwright control, `@control="combobox"`: an input that filters the
 * field's `@options` as you type, with the list in the top layer. It stores the option chosen
 * (or its key, with `@storeKey`), or `null` once it is cleared.
 */
export class ComboboxControl extends Component<ComboboxControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get selected(): unknown {
    if (isEmpty(this.args.value)) return null
    return (
      this.options.find(option => matches(this.args.value, option, this.args.optionKey)) ?? null
    )
  }

  get emptyText(): string {
    return this.args.emptyText ?? 'No items found.'
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled)
  }

  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  isDisabled = (option: unknown): boolean => isOptionDisabled(option)
  isEqual = (option: unknown, value: unknown): boolean =>
    value !== null && value !== undefined && this.keyFor(option) === this.keyFor(value)

  choose = (option: unknown): void => {
    this.args.onChange(
      option === null || option === undefined
        ? null
        : toStored(option, this.args.storeKey, this.args.optionKey),
    )
  }

  <template>
    <Combobox
      @items={{this.options}}
      @value={{this.selected}}
      @onValueChange={{this.choose}}
      @itemToStringLabel={{this.labelFor}}
      @itemToStringValue={{this.keyFor}}
      @isItemEqualToValue={{this.isEqual}}
      @disabled={{this.disabled}}
      @readOnly={{@readonly}}
      @required={{@required}}
      @formName={{@name}}
      data-test-fw-control={{@type}}
      as |c|
    >
      <c.Input
        @disabled={{this.disabled}}
        @showClear={{@showClear}}
        id={{@id}}
        placeholder={{@placeholder}}
        aria-invalid={{if @invalid "true"}}
        aria-describedby={{@describedBy}}
        ...attributes
      />
      <c.Content>
        <c.Empty>{{this.emptyText}}</c.Empty>
        <c.List as |option|>
          <c.Item
            @value={{option}}
            @disabled={{this.isDisabled option}}
            data-test-fw-option={{this.keyFor option}}
          >{{this.labelFor option}}</c.Item>
        </c.List>
      </c.Content>
    </Combobox>
  </template>
}
