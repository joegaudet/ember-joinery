---
'@ember-joinery/formwright': major
'@ember-joinery/ember': minor
---

`@ember-joinery/formwright` is a new opt-in package that builds Joinery's forms on Formwright,
as shadcn's are built on react-hook-form. `setupJoineryForms()` registers Joinery's inputs as
Formwright controls (`input` and its types, `number`, `currency`, `textarea`, `select`,
`native-select`, `combobox`, `checkbox`, `checkbox-group`, `radio`, `switch`, `toggle`,
`toggle-group`, `slider`, `range`, `input-otp` and `date-picker`), so Formwright's own names render
Joinery's components, and makes `JoineryFieldLayout` the layout every field uses: shadcn's Field
around a FieldLabel, the control, a FieldDescription and a FieldError, or a FieldSet under a
FieldLegend for a group control, in each control's orientation, or `@layout="joinery-vertical"`,
`joinery-horizontal` or `joinery-responsive`. `registerJoineryControls({ only, except })` and
`registerJoineryLayouts()` register them alone, each control is exported for `@control={{…}}`,
and `asFieldErrors` makes a layout of your own's errors a FieldError. Its `/test-support` has a
field harness for each control on Formwright's `FieldHarness` (`InputFieldHarness`,
`SelectFieldHarness`, `RadioGroupFieldHarness`, `DatePickerFieldHarness`…), each reaching
Joinery's own harness for its component, and `@form` and `findForm()`, which find a Formwright
form inside a Joinery harness, following its portalled and top-layer parts, so a form in a
dialog is the dialog's. `@ember-joinery/ember`'s `joinery.css` now styles Formwright's fields
(`formwright.css`): it takes Formwright's wrappers out of the Field's box tree and restates the
Field's rules one wrapper down. Nothing in the core packages imports it.
