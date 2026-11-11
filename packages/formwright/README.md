# @ember-joinery/formwright

[Joinery](https://joegaudet.com/ember-joinery/) for
[Formwright](https://joegaudet.com/ember-formwright/): Joinery's inputs as Formwright
controls, a field layout in shadcn/ui's Field anatomy, and harnesses built on Formwright's own.
shadcn/ui builds its forms with react-hook-form; this is that, in Ember.

```bash
npm install @ember-joinery/formwright @ember-joinery/ember @ember-formwright/ember
npm install --save-dev @ember-formwright/test-support @ember-joinery/test-support
```

It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles) styles
its fields, as it does every Joinery component.

```ts
// app.ts
import { setupJoineryForms } from '@ember-joinery/formwright'

setupJoineryForms()
```

```gts
import { Form } from '@ember-formwright/ember'
import { Button, FieldGroup, asButton } from '@ember-joinery/ember'

<template>
  <Form @model={{@profile}} @validator={{schema}} @onSubmit={{@save}} as |f|>
    <FieldGroup>
      <f.Field @for="name" @label="Name" @hint="Your public name." />
      <f.Field @for="language" @control="select" @label="Language" @options={{@languages}} />
      <f.Field @for="notify" @control="switch" @label="Email me" />
    </FieldGroup>
    <f.Submit {{asButton}}>Save</f.Submit>
  </Form>
</template>
```

- **`setupJoineryForms()`** registers every control and layout, and makes Joinery's layout every
  field's default. `registerJoineryControls({ only, except })` and `registerJoineryLayouts()` do
  each part alone.
- **Controls**: Formwright's names render Joinery's components (`input` and its types,
  `number`, `textarea`, `currency`, `select`, `checkbox`, `checkbox-group`, `radio`, `range`),
  and Joinery adds `native-select`, `combobox`, `switch`, `toggle`, `toggle-group`, `slider`,
  `rating`, `input-otp` and `date-picker`. Each is also exported (`SelectControl`…) and listed
  in `joineryControls`. Their names are declared to Formwright's types, so Glint checks that a
  field's path holds what its control stores and that it passes only the control's args.
  FileDrop isn't a control, since it keeps no value; the guide's Controls
  page says more.
- **The layout**, `JoineryFieldLayout` (`@layout="joinery"`, `"joinery-vertical"`,
  `"joinery-horizontal"`, `"joinery-responsive"`), renders shadcn's `Field`, `FieldLabel`,
  `FieldDescription` and `FieldError`, a group control's `FieldSet` and `FieldLegend`, with
  Formwright's ids, ARIA and `data-test-fw-*` attributes. `asFieldErrors` makes a custom
  layout's error region shadcn's FieldError.

Its harnesses, at `@ember-joinery/formwright/test-support`, extend Formwright's
`FieldHarness`: `SelectFieldHarness`, `CheckboxFieldHarness`, `CheckboxGroupFieldHarness`,
`RadioGroupFieldHarness`, `SwitchFieldHarness`, `ToggleFieldHarness`,
`ToggleGroupFieldHarness`, `SliderFieldHarness`, `RatingFieldHarness`, `InputOTPFieldHarness`,
`ComboboxFieldHarness`, `DatePickerFieldHarness`, `InputFieldHarness`, `NumberFieldHarness` and
`NativeSelectFieldHarness`. `@form` (and `findForm()`) declares a Formwright form inside a
Joinery harness, a dialog's or a card's:

```ts
import { DialogHarness, ButtonHarness, child } from '@ember-joinery/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { InputFieldHarness, form } from '@ember-joinery/formwright/test-support'

class ProfileForm extends FormHarness {
  @field(InputFieldHarness) declare name: InputFieldHarness
}

class EditProfile extends DialogHarness {
  static named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @form(ProfileForm) declare profile: ProfileForm
}
```

Full documentation: the Formwright section of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Design ported from
[shadcn/ui](https://ui.shadcn.com/) (MIT).
