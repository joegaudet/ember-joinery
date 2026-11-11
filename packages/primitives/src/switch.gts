import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { WithBoundArgs } from '@glint/template'
import { As, type TagName } from './as.gts'
import { controllable } from './controllable-state.ts'
import { BubbleInput, FormControl } from './-private/form-control.ts'

export interface SwitchThumbSignature {
  Args: {
    /** The tag to render. Default `span`. */
    as?: TagName
    /** @internal Bound by the switch. */
    checked: boolean
    /** @internal Bound by the switch. */
    disabled?: boolean
  }
  /** What the thumb shows, if anything: an icon, say. */
  Blocks: { default: [] }
  Element: HTMLElement
}

/** The part of a switch that slides: Radix's `Switch.Thumb`, with the switch's `data-state`. */
const SwitchThumb: TOC<SwitchThumbSignature> = <template>
  <As
    @as={{@as}}
    @tag="span"
    data-state={{if @checked "checked" "unchecked"}}
    data-disabled={{if @disabled ""}}
    data-test-jn-part="thumb"
    ...attributes
  >{{yield}}</As>
</template>

export interface SwitchSignature {
  Args: {
    /** The controlled state. */
    checked?: boolean
    /** The first state, when uncontrolled. Default `false`. */
    defaultChecked?: boolean
    /** Called with each new state the user asks for. */
    onCheckedChange?: (checked: boolean) => void
    /** Whether it can't be changed. */
    disabled?: boolean
    /** Whether a form needs it on to submit. */
    required?: boolean
    /** The tag to render. Default `button`. */
    as?: TagName
    /** Its name, for `SwitchHarness` (`data-test-jn-name`). Its form field name is `name`. */
    name?: string
  }
  Blocks: {
    default: [
      control: {
        /** The part that slides: `<s.Thumb />`, with anything it should show inside it. */
        Thumb: WithBoundArgs<typeof SwitchThumb, 'checked' | 'disabled'>
        /** Whether it is on. */
        isChecked: boolean
      },
    ]
  }
  /** A `<button role="switch">`, or the tag `@as` names. */
  Element: HTMLButtonElement
}

/**
 * A control that turns something on and off: Radix's `Switch`, headless, which also covers
 * ember-primitives' `Switch`. It is a `<button role="switch">` with `aria-checked` and
 * `data-state`, which a click, Space or Enter toggles, and it yields its thumb, which you
 * render and style (or fill) yourself. Its state is controlled or not, as in Radix:
 *
 *   <Switch @checked={{this.airplane}} @onCheckedChange={{this.setAirplane}} id="airplane" as |s|>
 *     <s.Thumb />
 *   </Switch>
 *   <label for="airplane">Airplane Mode</label>
 *
 * In a form, it renders a hidden native checkbox beside it, as Radix's does (and as
 * ember-primitives' switch is one), which repeats the `name`, `value` (default `on`) and `form`
 * you give the switch, so the form submits it and checks `@required`.
 */
export class Switch extends Component<SwitchSignature> {
  checked = controllable(this, 'checked', false)
  form = new FormControl()

  get isChecked(): boolean {
    return this.checked.value
  }

  /** Toggles it, unless a listener of the caller's called `preventDefault()` first. */
  toggle = (event: MouseEvent): void => {
    if (event.defaultPrevented) return
    this.checked.set(checked => !checked)
  }

  <template>
    <As
      @as={{@as}}
      @tag="button"
      type="button"
      role="switch"
      aria-checked={{if this.isChecked "true" "false"}}
      aria-required={{if @required "true"}}
      data-state={{if this.isChecked "checked" "unchecked"}}
      data-disabled={{if @disabled ""}}
      disabled={{@disabled}}
      value="on"
      data-test-jn="switch"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.form.source}}
      {{on "click" this.toggle}}
    >
      {{yield
        (hash
          Thumb=(component SwitchThumb checked=this.isChecked disabled=@disabled)
          isChecked=this.isChecked
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
        {{BubbleInput checked=this.isChecked}}
      />
    {{/if}}
  </template>
}

export default Switch
