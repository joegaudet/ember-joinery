import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
  RadioGroup,
} from '@ember-joinery/ember'
import {
  descriptionOf,
  isEmpty,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
  type OptionAccessor,
} from '../-private/options.ts'

/** How a radio group shows its choices. */
export type RadioGroupControlVariant = 'list' | 'card'

export interface RadioGroupControlSignature {
  Args: ControlSignature['Args'] & {
    /**
     * `list` (the default): each choice a radio and its label. `card`: each choice a card
     * (a `FieldLabel` around a horizontal `Field`) with its title and description, and the radio
     * at its end, which highlights while it is chosen.
     */
    variant?: RadioGroupControlVariant
    /**
     * Each option's description, shown under its label: a property name or a function. Default:
     * the option's `description`, if it has one.
     */
    optionDescription?: OptionAccessor
  }
  /** The RadioGroup's root, a `<div role="radiogroup">`. */
  Element: HTMLDivElement
}

/**
 * Joinery's Radio Group as a Formwright control, `@control="radio"`: one radio for each of the
 * field's `@options`, storing the option chosen (or its key, with `@storeKey`). The arrow keys
 * move between the radios, and the group is one tab stop. Its field is a `FieldSet` under a
 * legend. `@variant="card"` shows each choice as a card with its description.
 */
export class RadioGroupControl extends Component<RadioGroupControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get value(): string | null {
    if (isEmpty(this.args.value)) return null
    const selected = this.options.find(option =>
      matches(this.args.value, option, this.args.optionKey),
    )
    return selected === undefined ? null : this.keyFor(selected)
  }

  get isCard(): boolean {
    return this.args.variant === 'card'
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled || this.args.readonly)
  }

  /** The first radio takes the field's id, so focusing the field lands on the group. */
  idFor = (index: number): string => (index === 0 ? this.args.id : `${this.args.id}-${index}`)
  titleIdFor = (index: number): string => `${this.idFor(index)}-title`
  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  descriptionFor = (option: unknown): string | undefined =>
    descriptionOf(option, this.args.optionDescription)
  isDisabled = (option: unknown): boolean => isOptionDisabled(option)

  choose = (key: string): void => {
    const option = this.options.find(o => this.keyFor(o) === key)
    if (option !== undefined) {
      this.args.onChange(toStored(option, this.args.storeKey, this.args.optionKey))
    }
  }

  <template>
    <RadioGroup
      @value={{this.value}}
      @onValueChange={{this.choose}}
      @disabled={{this.disabled}}
      @required={{@required}}
      @formName={{@name}}
      aria-invalid={{if @invalid "true"}}
      data-test-fw-control={{@type}}
      ...attributes
      as |group|
    >
      {{#each this.options as |option index|}}
        {{#if this.isCard}}
          {{!
            The radio names itself by the card's title (aria-labelledby): axe can't read a name
            through the field's role="group" inside the label, though browsers do.
          }}
          <FieldLabel for={{this.idFor index}}>
            <Field @orientation="horizontal" @invalid={{@invalid}}>
              <FieldContent>
                <FieldTitle id={{this.titleIdFor index}}>{{this.labelFor option}}</FieldTitle>
                {{#let (this.descriptionFor option) as |description|}}
                  {{#if description}}
                    <FieldDescription>{{description}}</FieldDescription>
                  {{/if}}
                {{/let}}
              </FieldContent>
              <group.Item
                @value={{this.keyFor option}}
                @disabled={{this.isDisabled option}}
                id={{this.idFor index}}
                aria-labelledby={{this.titleIdFor index}}
                aria-invalid={{if @invalid "true"}}
                data-test-fw-option={{this.keyFor option}}
              />
            </Field>
          </FieldLabel>
        {{else}}
          <Field @orientation="horizontal" @invalid={{@invalid}}>
            <group.Item
              @value={{this.keyFor option}}
              @disabled={{this.isDisabled option}}
              id={{this.idFor index}}
              aria-invalid={{if @invalid "true"}}
              data-test-fw-option={{this.keyFor option}}
            />
            {{#let (this.descriptionFor option) as |description|}}
              {{#if description}}
                <FieldContent>
                  <FieldLabel for={{this.idFor index}}>{{this.labelFor option}}</FieldLabel>
                  <FieldDescription>{{description}}</FieldDescription>
                </FieldContent>
              {{else}}
                <FieldLabel
                  for={{this.idFor index}}
                  class="jn-formwright-option-label"
                >{{this.labelFor option}}</FieldLabel>
              {{/if}}
            {{/let}}
          </Field>
        {{/if}}
      {{/each}}
    </RadioGroup>
  </template>
}
