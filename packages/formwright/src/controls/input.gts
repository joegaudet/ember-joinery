import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from '@ember-formwright/ember'
import { inputClasses, type InputGroupParts } from '@ember-joinery/ember'

/** Formwright's control names whose `<input>` takes another `type`. */
const NATIVE_TYPES: Record<string, string> = { input: 'text', datetime: 'datetime-local' }

/** The controls whose value is a number (or `null` while empty). */
const NUMERIC = new Set(['number'])

export interface InputControlSignature {
  Args: ControlSignature<string | number | null>['Args'] & {
    /**
     * The parts an `<InputGroup>` yields, to render as the group's input (`g.Input`) inside it:
     * `<InputGroup as |g|><field.Control @group={{g}} />…</InputGroup>`.
     */
    group?: InputGroupParts
    /**
     * Its `autocomplete`: what the browser may fill in (`username`, `email`, `new-password`,
     * `off`). An argument, since a field's `Control` takes only global attributes.
     */
    autocomplete?: string
  }
  Element: HTMLInputElement
}

/**
 * Joinery's Input as a Formwright control: `@control="input"` (and `text`, `email`,
 * `password`, `search`, `tel`, `url`, `color`, `date`, `datetime`, `time` and `number`, each
 * its own `type`). A `number` field stores a number, or `null` while it is empty. In an
 * `<InputGroup>`, give it the group's parts (`@group`) to render as the group's input.
 */
export class InputControl extends Component<InputControlSignature> {
  get inputType(): string {
    return NATIVE_TYPES[this.args.type] ?? this.args.type
  }

  get classes(): string {
    return this.args.group ? `${inputClasses()} jn-input-group-input` : inputClasses()
  }

  get slot(): string {
    return this.args.group ? 'input-group-control' : 'input'
  }

  get displayValue(): string | number {
    return this.args.value ?? ''
  }

  onInput = (event: Event): void => {
    const raw = (event.target as HTMLInputElement).value
    if (NUMERIC.has(this.args.type)) this.args.onChange(raw === '' ? null : Number(raw))
    else this.args.onChange(raw)
  }

  <template>
    <input
      id={{@id}}
      name={{@name}}
      class={{this.classes}}
      type={{this.inputType}}
      value={{this.displayValue}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      maxlength={{@maxLength}}
      min={{@min}}
      max={{@max}}
      step={{@step}}
      autocomplete={{@autocomplete}}
      data-slot={{this.slot}}
      data-test-jn="input"
      data-test-fw-control={{@type}}
      ...attributes
      {{on "input" this.onInput}}
    />
  </template>
}
