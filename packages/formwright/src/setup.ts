import {
  registerControl,
  registerLayout,
  setDefaultLayout,
  type ControlComponent,
} from '@ember-formwright/ember'
import { CheckboxControl } from './controls/checkbox.gts'
import { CheckboxGroupControl } from './controls/checkbox-group.gts'
import { ComboboxControl } from './controls/combobox.gts'
import { CurrencyControl } from './controls/currency.gts'
import { DatePickerControl } from './controls/date-picker.gts'
import { InputControl } from './controls/input.gts'
import { InputOTPControl } from './controls/input-otp.gts'
import { NativeSelectControl } from './controls/native-select.gts'
import { RadioGroupControl } from './controls/radio-group.gts'
import { SelectControl } from './controls/select.gts'
import { SliderControl } from './controls/slider.gts'
import { SwitchControl } from './controls/switch.gts'
import { TextareaControl } from './controls/textarea.gts'
import { ToggleControl } from './controls/toggle.gts'
import { ToggleGroupControl } from './controls/toggle-group.gts'
import { JoineryFieldLayout } from './layout.gts'

/**
 * Every Joinery input, by the Formwright control name it registers as. Formwright's own names
 * (`input` and its types, `textarea`, `select`, `radio`, `checkbox`, `checkbox-group`,
 * `currency`, `range`) get Joinery's component; the rest are new.
 */
export const joineryControls: Readonly<Record<string, ControlComponent>> = Object.freeze({
  input: InputControl,
  text: InputControl,
  email: InputControl,
  password: InputControl,
  search: InputControl,
  tel: InputControl,
  url: InputControl,
  color: InputControl,
  date: InputControl,
  datetime: InputControl,
  time: InputControl,
  number: InputControl,
  textarea: TextareaControl,
  currency: CurrencyControl,
  select: SelectControl,
  'native-select': NativeSelectControl,
  combobox: ComboboxControl,
  checkbox: CheckboxControl,
  'checkbox-group': CheckboxGroupControl,
  radio: RadioGroupControl,
  switch: SwitchControl,
  toggle: ToggleControl,
  'toggle-group': ToggleGroupControl,
  slider: SliderControl,
  range: SliderControl,
  'input-otp': InputOTPControl,
  'date-picker': DatePickerControl,
})

/** The controls made of several choices: their field is a `FieldSet` under a legend. */
export const joineryGroupControls: ReadonlySet<string> = new Set([
  'radio',
  'checkbox-group',
  'toggle-group',
])

/** Which of Joinery's controls `registerJoineryControls()` registers. */
export interface RegisterJoineryControlsOptions {
  /** Register only these names. */
  only?: readonly string[]
  /** Register every name but these, to keep Formwright's own (`except: ['select']`). */
  except?: readonly string[]
}

/**
 * Registers every Joinery input as a Formwright control (see `joineryControls`), for every form.
 * Formwright's own names then render Joinery's components: `@control="select"` is Joinery's
 * Select. Call it once, at boot (`setupJoineryForms()` does).
 */
export function registerJoineryControls(options: RegisterJoineryControlsOptions = {}): void {
  for (const [name, control] of Object.entries(joineryControls)) {
    if (options.only && !options.only.includes(name)) continue
    if (options.except?.includes(name)) continue
    registerControl(name, control, { group: joineryGroupControls.has(name) })
  }
}

/** Joinery's field layout, horizontal whatever the control. */
export class HorizontalFieldLayout extends JoineryFieldLayout {
  override get orientation(): 'horizontal' {
    return 'horizontal'
  }
}

/** Joinery's field layout, responsive: stacked until its FieldGroup is 28rem wide. */
export class ResponsiveFieldLayout extends JoineryFieldLayout {
  override get orientation(): 'responsive' {
    return 'responsive'
  }
}

/** Joinery's field layout, stacked whatever the control. */
export class VerticalFieldLayout extends JoineryFieldLayout {
  override get orientation(): 'vertical' {
    return 'vertical'
  }
}

/**
 * Makes Joinery's field layout available to every form: `@layout="joinery"` (each control's
 * own orientation), `"joinery-vertical"`, `"joinery-horizontal"` and `"joinery-responsive"`.
 */
export function registerJoineryLayouts(): void {
  registerLayout('joinery', JoineryFieldLayout)
  registerLayout('joinery-vertical', VerticalFieldLayout)
  registerLayout('joinery-horizontal', HorizontalFieldLayout)
  registerLayout('joinery-responsive', ResponsiveFieldLayout)
}

/**
 * Sets Formwright up to render Joinery: registers every Joinery control and layout, and makes
 * `joinery` the layout every field uses unless it or its form has a `@layout`. Call it once, at
 * boot, e.g. in app.ts.
 *
 *   import { setupJoineryForms } from '@ember-joinery/formwright'
 *   setupJoineryForms()
 */
export function setupJoineryForms(options: RegisterJoineryControlsOptions = {}): void {
  registerJoineryControls(options)
  registerJoineryLayouts()
  setDefaultLayout('joinery')
}
