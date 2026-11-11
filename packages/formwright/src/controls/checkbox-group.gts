import Component from '@glimmer/component'
import { fn } from '@ember/helper'
import type { ControlSignature, MaxArgs, OptionArgs } from '@ember-formwright/ember'
import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
} from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'
import {
  descriptionOf,
  isOptionDisabled,
  keyString,
  labelOf,
  matches,
  toStored,
  type OptionAccessor,
} from '../-private/options.ts'

export interface CheckboxGroupControlSignature {
  Args: ControlSignature<unknown[]>['Args'] &
    OptionArgs &
    MaxArgs & {
      /**
       * Each option's description, shown under its label: a property name or a function. Default:
       * the option's `description`, if it has one.
       */
      optionDescription?: OptionAccessor
    }
  /** The `FieldGroup` of checkboxes, `data-slot="checkbox-group"`. */
  Element: HTMLElement
}

/**
 * Joinery's Checkbox, one for each of the field's `@options`, as a Formwright control:
 * `@control="checkbox-group"`, which stores the options checked (or their keys, with
 * `@storeKey`), and `@max` caps. Its field is a `FieldSet` under a legend, and its checkboxes a
 * `FieldGroup` with `data-slot="checkbox-group"`, each a horizontal `Field`: the checkbox, then
 * its label, or its label and description in a `FieldContent`, as upstream's examples write them.
 */
export class CheckboxGroupControl extends Component<CheckboxGroupControlSignature> {
  get options(): readonly unknown[] {
    return this.args.options ?? []
  }

  get value(): unknown[] {
    return this.args.value ?? []
  }

  get atMax(): boolean {
    return this.args.max !== undefined && this.value.length >= Number(this.args.max)
  }

  /** The first checkbox takes the field's id, so focusing the field lands on the group. */
  idFor = (index: number): string => (index === 0 ? this.args.id : `${this.args.id}-${index}`)
  keyFor = (option: unknown): string => keyString(option, this.args.optionKey)
  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  descriptionFor = (option: unknown): string | undefined =>
    descriptionOf(option, this.args.optionDescription)
  isChecked = (option: unknown): boolean =>
    this.value.some(value => matches(value, option, this.args.optionKey))
  isDisabled = (option: unknown): boolean =>
    Boolean(
      this.args.disabled ||
      this.args.readonly ||
      isOptionDisabled(option) ||
      (this.atMax && !this.isChecked(option)),
    )

  toggle = (option: unknown, checked: CheckedState): void => {
    const others = this.value.filter(value => !matches(value, option, this.args.optionKey))
    this.args.onChange(
      checked === true
        ? [...others, toStored(option, this.args.storeKey, this.args.optionKey)]
        : others,
    )
  }

  <template>
    <FieldGroup data-slot="checkbox-group" data-test-fw-control={{@type}} ...attributes>
      {{#each this.options as |option index|}}
        <Field @orientation="horizontal" @invalid={{@invalid}}>
          <Checkbox
            @checked={{this.isChecked option}}
            @onCheckedChange={{fn this.toggle option}}
            @disabled={{this.isDisabled option}}
            id={{this.idFor index}}
            name={{@name}}
            value={{this.keyFor option}}
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
      {{/each}}
    </FieldGroup>
  </template>
}
