import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { controllable } from './controllable-state.ts'
import { BubbleInput, FormControl, preventEnter } from './-private/form-control.ts'
import { Indicator } from './-private/indicator.gts'

/** A checkbox's state: checked, unchecked, or (neither) indeterminate, as in Radix. */
export type CheckedState = boolean | 'indeterminate'

/** A checkbox's `data-state`, from its state. */
function checkedStateName(checked: CheckedState): 'checked' | 'unchecked' | 'indeterminate' {
  if (checked === 'indeterminate') return 'indeterminate'
  return checked ? 'checked' : 'unchecked'
}

/** A checkbox's `aria-checked`, from its state: `mixed` while indeterminate. */
function ariaChecked(checked: CheckedState): 'true' | 'false' | 'mixed' {
  if (checked === 'indeterminate') return 'mixed'
  return checked ? 'true' : 'false'
}

export interface CheckboxSignature {
  Args: {
    /** The controlled state: `true`, `false` or `'indeterminate'`. */
    checked?: CheckedState
    /** The first state, when uncontrolled. Default `false`. */
    defaultChecked?: CheckedState
    /** Called with each new state the user asks for. */
    onCheckedChange?: (checked: CheckedState) => void
    /** Whether it can't be changed. */
    disabled?: boolean
    /** Whether a form needs it checked to submit. */
    required?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** Its name, for `CheckboxHarness` (`data-test-jn-name`). Its form field name is `name`. */
    name?: string
  }
  Blocks: {
    default: [
      checkbox: {
        /** The mark, rendered while it is checked or indeterminate: `<c.Indicator>✓</c.Indicator>`. */
        Indicator: WithBoundArgs<typeof Indicator, 'present' | 'state' | 'disabled'>
        /** Its state: `true`, `false` or `'indeterminate'`. */
        checked: CheckedState
        /** Whether it is checked (not indeterminate). */
        isChecked: boolean
        /** Whether it is indeterminate. */
        isIndeterminate: boolean
      },
    ]
  }
  /** A `<button role="checkbox">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/**
 * A control that the user checks and unchecks: Radix's `Checkbox`, headless. It is a
 * `<button role="checkbox">` with `aria-checked` (`mixed` while indeterminate) and
 * `data-state`, which a click or Space toggles (an indeterminate one becomes checked) and Enter
 * leaves alone. Its state is controlled or not, as in Radix:
 *
 *   <Checkbox @checked={{this.terms}} @onCheckedChange={{this.setTerms}} id="terms" as |c|>
 *     <c.Indicator>✓</c.Indicator>
 *   </Checkbox>
 *   <label for="terms">Accept terms and conditions</label>
 *
 * In a form, it renders a hidden native checkbox beside it, as Radix's does, which repeats the
 * `name`, `value` (default `on`) and `form` you give the checkbox: the form submits it, checks
 * `@required`, hears its `change`, and a reset puts the checkbox back to its first state.
 */
export class Checkbox extends Component<CheckboxSignature> {
  checked = controllable(this, 'checked', false)
  /** The state it started in, which a form reset goes back to. */
  #initial: CheckedState = this.checked.value
  form = new FormControl({ onReset: () => this.checked.set(this.#initial) })

  get state(): CheckedState {
    return this.checked.value
  }

  get isChecked(): boolean {
    return this.state === true
  }

  get isIndeterminate(): boolean {
    return this.state === 'indeterminate'
  }

  get isPresent(): boolean {
    return this.state !== false
  }

  get stateName(): string {
    return checkedStateName(this.state)
  }

  get ariaChecked(): string {
    return ariaChecked(this.state)
  }

  /** Toggles it, unless a listener of the caller's called `preventDefault()` first. */
  toggle = (event: MouseEvent): void => {
    if (event.defaultPrevented) return
    this.checked.set(checked => (checked === 'indeterminate' ? true : !checked))
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      role="checkbox"
      aria-checked={{this.ariaChecked}}
      aria-required={{if @required "true"}}
      data-state={{this.stateName}}
      data-disabled={{if @disabled ""}}
      disabled={{@disabled}}
      value="on"
      data-test-jn="checkbox"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.form.source}}
      {{on "keydown" preventEnter}}
      {{on "click" this.toggle}}
    >
      {{yield
        (hash
          Indicator=(component
            Indicator present=this.isPresent state=this.stateName disabled=@disabled
          )
          checked=this.state
          isChecked=this.isChecked
          isIndeterminate=this.isIndeterminate
        )
      }}
    </As>
    {{#if this.form.isFormControl}}
      <input
        type="checkbox"
        aria-hidden="true"
        tabindex="-1"
        name={{this.form.fieldName}}
        value={{if this.form.value this.form.value "on"}}
        form={{this.form.form}}
        required={{@required}}
        disabled={{@disabled}}
        {{BubbleInput checked=this.isChecked indeterminate=this.isIndeterminate}}
      />
    {{/if}}
  </template>
}

export default Checkbox
