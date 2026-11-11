import Component from '@glimmer/component'
import type { ControlSignature } from '@ember-formwright/ember'
import { Toggle, type ToggleSize, type ToggleVariant } from '@ember-joinery/ember'

export interface ToggleControlSignature {
  Args: ControlSignature<boolean>['Args'] & {
    /** The Toggle's `@variant`: `default` or `outline`. */
    variant?: ToggleVariant
    /** The Toggle's `@size`: `default`, `sm` or `lg`. */
    size?: ToggleSize
  }
  Blocks: {
    /** What the toggle shows, an icon or text. Without a block, the field's `@label`. */
    default: [pressed: boolean]
  }
  /** A `<button aria-pressed>`, which the field's label names. */
  Element: HTMLButtonElement
}

/**
 * Joinery's Toggle as a Formwright control, `@control="toggle"`: a two-state button that
 * stores `true` (pressed) or `false`. Give it what to show with a block, or it shows the
 * field's label. Read-only disables it.
 */
export class ToggleControl extends Component<ToggleControlSignature> {
  onPressedChange = (pressed: boolean): void => this.args.onChange(pressed)

  <template>
    <Toggle
      @pressed={{if @value true false}}
      @onPressedChange={{this.onPressedChange}}
      @disabled={{if @readonly true @disabled}}
      @variant={{@variant}}
      @size={{@size}}
      id={{@id}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      as |pressed|
    >
      {{#if (has-block)}}{{yield pressed}}{{else}}{{@label}}{{/if}}
    </Toggle>
  </template>
}
