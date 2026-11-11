import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { ToggleGroup, type ToggleSize, type ToggleVariant } from '@ember-joinery/ember'
import {
  isEmpty,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
} from '../-private/options.ts'

export interface ToggleGroupControlSignature {
  Args: ControlSignature['Args'] & {
    /**
     * Whether several options can be pressed at once. Default: whether the field's value is a
     * list. A single toggle group stores the option pressed, or `null`; a multiple one, a list.
     */
    multiple?: boolean
    /** The items' `@variant`: `default` or `outline`. */
    variant?: ToggleVariant
    /** The items' `@size`: `default`, `sm` or `lg`. */
    size?: ToggleSize
    /** The gap between the items, as ToggleGroup's `@spacing`. */
    spacing?: number
    /** `horizontal` (the default) or `vertical`, for the arrow keys and the layout. */
    orientation?: 'horizontal' | 'vertical'
  }
  Blocks: {
    /** What each item shows, an icon or text, given its option. Default: the option's label. */
    default: [option: unknown, pressed: boolean]
  }
  /** The ToggleGroup's root, a `<div role="group">`. */
  Element: HTMLDivElement
}

/**
 * Joinery's Toggle Group as a Formwright control, `@control="toggle-group"`: a toggle for each
 * of the field's `@options`, storing the one pressed (or, with `@multiple`, the ones pressed;
 * their keys, with `@storeKey`). The arrow keys move between the toggles. Its field is a
 * `FieldSet` under a legend, which names the group.
 */
export class ToggleGroupControl extends Component<ToggleGroupControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get isMultiple(): boolean {
    return this.args.multiple ?? Array.isArray(this.args.value)
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled || this.args.readonly)
  }

  get singleValue(): string {
    if (isEmpty(this.args.value)) return ''
    const selected = this.options.find(option =>
      matches(this.args.value, option, this.args.optionKey),
    )
    return selected === undefined ? '' : this.keyFor(selected)
  }

  get multipleValue(): string[] {
    const value = Array.isArray(this.args.value) ? (this.args.value as unknown[]) : []
    return this.options
      .filter(option => value.some(v => matches(v, option, this.args.optionKey)))
      .map(option => this.keyFor(option))
  }

  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  isDisabled = (option: unknown): boolean => isOptionDisabled(option)

  optionFor = (key: string): unknown => this.options.find(o => this.keyFor(o) === key)

  store = (option: unknown): unknown => toStored(option, this.args.storeKey, this.args.optionKey)

  chooseOne = (key: string): void => {
    const option = this.optionFor(key)
    this.args.onChange(option === undefined ? null : this.store(option))
  }

  chooseMany = (keys: string[]): void => {
    const options = this.options.filter(option => keys.includes(this.keyFor(option)))
    this.args.onChange(options.map(this.store))
  }

  <template>
    {{#if this.isMultiple}}
      <ToggleGroup
        @type="multiple"
        @value={{this.multipleValue}}
        @onValueChange={{this.chooseMany}}
        @disabled={{this.disabled}}
        @variant={{@variant}}
        @size={{@size}}
        @spacing={{@spacing}}
        @orientation={{@orientation}}
        id={{@id}}
        data-test-fw-control={{@type}}
        ...attributes
        as |g|
      >
        {{#each this.options as |option|}}
          <g.Item
            @value={{this.keyFor option}}
            @disabled={{this.isDisabled option}}
            aria-invalid={{if @invalid "true"}}
            data-test-fw-option={{this.keyFor option}}
            as |pressed|
          >
            {{#if (has-block)}}{{yield option pressed}}{{else}}{{this.labelFor option}}{{/if}}
          </g.Item>
        {{/each}}
      </ToggleGroup>
    {{else}}
      <ToggleGroup
        @type="single"
        @value={{this.singleValue}}
        @onValueChange={{this.chooseOne}}
        @disabled={{this.disabled}}
        @variant={{@variant}}
        @size={{@size}}
        @spacing={{@spacing}}
        @orientation={{@orientation}}
        id={{@id}}
        data-test-fw-control={{@type}}
        ...attributes
        as |g|
      >
        {{#each this.options as |option|}}
          <g.Item
            @value={{this.keyFor option}}
            @disabled={{this.isDisabled option}}
            aria-invalid={{if @invalid "true"}}
            data-test-fw-option={{this.keyFor option}}
            as |pressed|
          >
            {{#if (has-block)}}{{yield option pressed}}{{else}}{{this.labelFor option}}{{/if}}
          </g.Item>
        {{/each}}
      </ToggleGroup>
    {{/if}}
  </template>
}
