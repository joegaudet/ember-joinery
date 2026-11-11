import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Checkbox } from '@ember-joinery/ember'
import type { CheckedState } from '@ember-joinery/primitives/checkbox'

export interface CheckboxControlSignature {
  Args: ControlSignature<boolean>['Args']
  /** A `<button role="checkbox">`, which the field's label names. */
  Element: HTMLButtonElement
}

/**
 * Joinery's Checkbox as a Formwright control, `@control="checkbox"`: one checkbox that stores
 * `true` or `false`. Its field puts it before its label (Joinery's layout), as upstream's
 * examples do. Read-only disables it, as Formwright's native checkbox does.
 */
export class CheckboxControl extends Component<CheckboxControlSignature> {
  onChange = (checked: CheckedState): void => this.args.onChange(checked === true)

  <template>
    <Checkbox
      @checked={{if @value true false}}
      @onCheckedChange={{this.onChange}}
      @disabled={{if @readonly true @disabled}}
      @required={{@required}}
      id={{@id}}
      name={{@name}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
    />
  </template>
}
