import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Switch, type SwitchSize } from '@ember-joinery/ember'

export interface SwitchControlSignature {
  Args: ControlSignature<boolean>['Args'] & {
    /** The Switch's `@size`: `default` or `sm`. */
    size?: SwitchSize
  }
  /** A `<button role="switch">`, which the field's label names. */
  Element: HTMLButtonElement
}

/**
 * Joinery's Switch as a Formwright control, `@control="switch"`: it stores `true` or
 * `false`. Its field puts it after its label, hint and errors (Joinery's layout), as upstream's
 * examples do. Read-only disables it.
 */
export class SwitchControl extends Component<SwitchControlSignature> {
  onChange = (checked: boolean): void => this.args.onChange(checked)

  <template>
    <Switch
      @checked={{if @value true false}}
      @onCheckedChange={{this.onChange}}
      @disabled={{if @readonly true @disabled}}
      @required={{@required}}
      @size={{@size}}
      id={{@id}}
      name={{@name}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
    />
  </template>
}
