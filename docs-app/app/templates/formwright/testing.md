# Testing

Describe each form once as a Formwright `FormHarness`, its fields with `@field` and the harness
for each control, as Formwright's own guide does. `@ember-joinery/formwright/test-support` has
a field harness for each Joinery control, built on Formwright's `FieldHarness` and driving the
control through Joinery's own harness, and `@form`, which declares a form inside a Joinery
harness, a dialog's or a card's.

```ts
import { FormHarness, field } from '@ember-formwright/test-support'
import { InputFieldHarness, SelectFieldHarness } from '@ember-joinery/formwright/test-support'

class LanguageForm extends FormHarness {
  static formName = 'language-preferences'
  @field(InputFieldHarness) declare name: InputFieldHarness
  @field(SelectFieldHarness) declare language: SelectFieldHarness
}

const form = new LanguageForm()
await form.language.choose('fr')
await form.submit()
assert.deepEqual(form.name.errors, ['Enter your name.'])
```

## In a Joinery component

`@form` declares a Formwright form inside a Joinery harness, as `@child` declares a component.
It follows the component's portalled and top-layer parts, so it finds the form in a dialog's
content:

<Example @name="formwright-dialog" @title="Dialog" />

```ts
import { ButtonHarness, DialogHarness, child } from '@ember-joinery/test-support'
import { form } from '@ember-joinery/formwright/test-support'

class EditProfile extends DialogHarness {
  static named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @form(ProfileForm, 'profile') declare profile: ProfileForm
}

await dialog.open()
await dialog.profile.name.fillIn('Ada Lovelace')
await dialog.save.click()
```

The form is the one named `name` (its `@name`), else the class's `static formName`, else the
first form inside the component. Each harness is created the first time you read it and kept;
`findForm(harness, ProfileForm)` makes a one-off. To nest one Formwright form in another, use
Formwright's own `@form` on the `FormHarness`.

## Field harnesses

| Harness                     | Controls                          | Adds                                                                               |
| --------------------------- | --------------------------------- | ---------------------------------------------------------------------------------- |
| `InputFieldHarness`         | `input` and its types, `textarea` | Formwright's `InputHarness` (`fillIn`, `value`), `placeholder`                     |
| `NumberFieldHarness`        | `number`                          | Formwright's `NumberHarness` (`fillIn(n)`, `value`)                                |
| `NativeSelectFieldHarness`  | `native-select`                   | Formwright's `SelectHarness` (`select(key)`, `value`, `options`)                   |
| `SelectFieldHarness`        | `select`                          | `value`, `text`, `options`, `isOpen`, `open()`, `choose(key)`, `select`            |
| `ComboboxFieldHarness`      | `combobox`                        | `value`, `items`, `open()`, `typeIn(text)`, `select(label)`, `clear()`, `combobox` |
| `CheckboxFieldHarness`      | `checkbox`                        | `value`, `check()`, `uncheck()`, `toggle()`, `checkbox`                            |
| `SwitchFieldHarness`        | `switch`                          | `value`, `check()`, `uncheck()`, `toggle()`, `switch`                              |
| `ToggleFieldHarness`        | `toggle`                          | `value`, `toggle()`, `toggleButton`                                                |
| `CheckboxGroupFieldHarness` | `checkbox-group`                  | `value`, `options`, `select(keys)`, `toggle(key)`, `isOptionDisabled(key)`         |
| `RadioGroupFieldHarness`    | `radio`                           | `value`, `options`, `select(key)`, `radioGroup`                                    |
| `ToggleGroupFieldHarness`   | `toggle-group`                    | `value`, `options`, `select(keys)`, `toggle(key)`, `toggleGroup`                   |
| `SliderFieldHarness`        | `slider`, `range`                 | `value`, `press(key, thumb?)`, `slideTo(percent)`, `slider`                        |
| `InputOTPFieldHarness`      | `input-otp`                       | `value`, `isComplete`, `fillIn(code)`, `typeIn(text)`, `paste(text)`, `otp`        |
| `DatePickerFieldHarness`    | `date-picker`                     | `text`, `isEmpty`, `pick(day)`, `datePicker`                                       |

Every one is a `FieldHarness`, so it has Formwright's `label`, `hint`, `errors`, `isInvalid`,
`isDirty`, `isRequired`, `isDisabled` and `control` too. The member named after a component
(`select`, `checkbox`, `radioGroup`…) is Joinery's own harness for it, for what it reads and
does beyond the field: `form.plan.radioGroup.press('ArrowDown')`. Formwright's `CurrencyHarness`
drives a `currency` field.

Each harness checks it is pointed at its control: `SelectFieldHarness` on a `switch` field fails
with a message that says so. Joinery's `select` replaces Formwright's native one, so a
Formwright `SelectHarness` can't drive it; use `SelectFieldHarness`.
