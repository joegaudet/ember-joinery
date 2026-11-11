import {
  registerControl,
  registerLayout,
  setDefaultLayout,
  type ControlComponent,
  type ControlSignature,
  type ControlWiring,
  type ItemOf,
  type LengthArgs,
  type OptionArgs,
  type RangeArgs,
} from '@ember-formwright/ember'
import { CheckboxControl, type CheckboxControlSignature } from './controls/checkbox.gts'
import {
  CheckboxGroupControl,
  type CheckboxGroupControlSignature,
} from './controls/checkbox-group.gts'
import { ComboboxControl, type ComboboxControlSignature } from './controls/combobox.gts'
import { CurrencyControl, type CurrencyControlSignature } from './controls/currency.gts'
import { DatePickerControl, type DatePickerControlSignature } from './controls/date-picker.gts'
import { InputControl, type InputControlSignature } from './controls/input.gts'
import { InputOTPControl, type InputOTPControlSignature } from './controls/input-otp.gts'
import {
  NativeSelectControl,
  type NativeSelectControlSignature,
} from './controls/native-select.gts'
import { RadioGroupControl, type RadioGroupControlSignature } from './controls/radio-group.gts'
import { RatingControl, type RatingControlSignature } from './controls/rating.gts'
import { SelectControl, type SelectControlSignature } from './controls/select.gts'
import { SliderControl, type SliderControlSignature } from './controls/slider.gts'
import { SwitchControl, type SwitchControlSignature } from './controls/switch.gts'
import { TextareaControl, type TextareaControlSignature } from './controls/textarea.gts'
import { ToggleControl, type ToggleControlSignature } from './controls/toggle.gts'
import { ToggleGroupControl, type ToggleGroupControlSignature } from './controls/toggle-group.gts'
import { JoineryFieldLayout } from './layout.gts'

/**
 * Joinery's inputs, by the Formwright control name each registers as (all but FileDrop, which
 * keeps no value: it hands each drop to a callback). Formwright's own names
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
  rating: RatingControl,
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
 * Registers Joinery's inputs as Formwright controls (see `joineryControls`), for every form.
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

/** A control's own args: all but the wiring every control gets (and its options, if any). */
type OwnArgs<S extends { Args: object }> = Omit<
  S['Args'],
  keyof ControlWiring<unknown> | 'options' | 'optionKey' | 'optionLabel' | 'storeKey'
>

/** A Joinery control as a Formwright one: storing `V`, with its own args and element. */
type Joinery<
  S extends { Args: object; Element: Element },
  V,
  Extra extends object = object,
> = ControlSignature<V, OwnArgs<S> & Extra, S['Element']>

type TextInput = Joinery<InputControlSignature, string, Pick<LengthArgs, 'maxLength'>>
type DateInput = Joinery<InputControlSignature, string, RangeArgs>

/** A toggle group stores a list when its path is one, else the option pressed or null. */
type ToggleGroupStored<T> =
  NonNullable<T> extends readonly unknown[] ? ItemOf<NonNullable<T>>[] : NonNullable<T> | null

/** A slider stores a list of numbers when its path is one (a range), else a number. */
type SliderStored<T> = NonNullable<T> extends readonly number[] ? number[] : number

declare module '@ember-formwright/ember' {
  /**
   * Joinery's controls by the names `joineryControls` registers. The types always declare all
   * of them, whichever `registerJoineryControls({ only, except })` registers.
   */
  interface FormwrightControls {
    input: TextInput
    text: TextInput
    email: TextInput
    password: TextInput
    search: TextInput
    tel: TextInput
    url: TextInput
    color: TextInput
    date: DateInput
    datetime: DateInput
    time: DateInput
    number: Joinery<InputControlSignature, number | null, RangeArgs>
    textarea: Joinery<TextareaControlSignature, string>
    currency: Joinery<CurrencyControlSignature, number | null>
    checkbox: Joinery<CheckboxControlSignature, boolean>
    switch: Joinery<SwitchControlSignature, boolean>
    toggle: Joinery<ToggleControlSignature, boolean>
    rating: Joinery<RatingControlSignature, number | null>
    'input-otp': Joinery<InputOTPControlSignature, string>
    'date-picker': Joinery<DatePickerControlSignature, Date | null>
  }

  interface FormwrightChoiceControls<T> {
    select: Joinery<SelectControlSignature, NonNullable<T> | null, OptionArgs<NonNullable<T>>>
    'native-select': Joinery<
      NativeSelectControlSignature,
      NonNullable<T> | null,
      OptionArgs<NonNullable<T>>
    >
    combobox: Joinery<ComboboxControlSignature, NonNullable<T> | null, OptionArgs<NonNullable<T>>>
    radio: Joinery<RadioGroupControlSignature, NonNullable<T>, OptionArgs<NonNullable<T>>>
    'checkbox-group': Joinery<CheckboxGroupControlSignature, ItemOf<T>[], OptionArgs<ItemOf<T>>>
    'toggle-group': Joinery<
      ToggleGroupControlSignature,
      ToggleGroupStored<T>,
      OptionArgs<NonNullable<ToggleGroupStored<T>> extends (infer E)[] ? E : NonNullable<T>>
    >
    slider: Joinery<SliderControlSignature, SliderStored<T>>
    range: Joinery<SliderControlSignature, SliderStored<T>>
  }
}
