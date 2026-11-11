import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Select, type SelectBlockParams, type SelectSize } from '@ember-joinery/ember'
import type { SelectPosition } from '@ember-joinery/primitives/select'
import {
  isEmpty,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
} from '../-private/options.ts'

export interface SelectControlSignature {
  Args: ControlSignature['Args'] & {
    /** Where the list opens: `item-aligned` (the default), over the trigger, or `popper`, below it. */
    position?: SelectPosition
    /** The trigger's `@size`: `default` or `sm`. */
    size?: SelectSize
  }
  Blocks: {
    /**
     * The list's items, instead of one per option: the Select's parts, to write them as a
     * Select's (`<s.Item @value="auto">Auto</s.Item><s.Separator />`). Each item's `@value` is
     * an option's key.
     */
    default: [select: SelectBlockParams]
  }
  /** The trigger: a `<button role="combobox">`, which the field's label names. */
  Element: HTMLButtonElement
}

/**
 * Joinery's Select as a Formwright control, `@control="select"`: a trigger showing the chosen
 * option (or `@placeholder`), and a list of the field's `@options` in the top layer. It stores
 * the option chosen, or its key with `@storeKey`. The trigger takes the field's id, so the
 * label names it, and `aria-invalid` and `aria-describedby`; attributes go on the trigger.
 *
 * With a block, the block writes the list's items, with the Select's parts:
 *
 *   <f.Field @for="language" @control="select" @options={{languages}} as |field|>
 *     <field.Control as |s|>
 *       <s.Item @value="auto">Auto</s.Item>
 *       <s.Separator />
 *       {{#each languages as |l|}}<s.Item @value={{l.value}}>{{l.label}}</s.Item>{{/each}}
 *     </field.Control>
 *   </f.Field>
 */
export class SelectControl extends Component<SelectControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get value(): string {
    if (isEmpty(this.args.value)) return ''
    const value = this.args.value
    const selected = this.options.find(option => matches(value, option, this.args.optionKey))
    if (selected !== undefined) return this.keyFor(selected)
    // A stored key whose option isn't listed (items from the block): the key itself.
    return typeof value === 'object' ? this.keyFor(value) : String(value)
  }

  get disabled(): boolean {
    // A Select has no read-only state; as Formwright's native select, read-only disables it.
    return Boolean(this.args.disabled || this.args.readonly)
  }

  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  isDisabled = (option: unknown): boolean => isOptionDisabled(option)

  choose = (key: string): void => {
    const option = this.options.find(o => this.keyFor(o) === key)
    if (option !== undefined) {
      this.args.onChange(toStored(option, this.args.storeKey, this.args.optionKey))
    } else {
      // An item the block wrote, with no option behind it: its key is the value.
      this.args.onChange(key === '' ? null : key)
    }
  }

  <template>
    <Select
      @value={{this.value}}
      @onValueChange={{this.choose}}
      @disabled={{this.disabled}}
      @required={{@required}}
      @formName={{@name}}
      data-test-fw-control={{@type}}
      as |s|
    >
      <s.Trigger
        @size={{@size}}
        id={{@id}}
        aria-invalid={{if @invalid "true"}}
        aria-describedby={{@describedBy}}
        ...attributes
      >
        <s.Value @placeholder={{@placeholder}} />
      </s.Trigger>
      <s.Content @position={{@position}}>
        {{#if (has-block)}}
          {{yield s}}
        {{else}}
          {{#each this.options as |option|}}
            <s.Item
              @value={{this.keyFor option}}
              @disabled={{this.isDisabled option}}
              data-test-fw-option={{this.keyFor option}}
            >{{this.labelFor option}}</s.Item>
          {{/each}}
        {{/if}}
      </s.Content>
    </Select>
  </template>
}
