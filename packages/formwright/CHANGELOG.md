# @ember-joinery/formwright

## 1.1.0

### Patch Changes

- @ember-joinery/ember@1.1.0
  - @ember-joinery/primitives@1.1.0
  - @ember-joinery/test-support@1.1.0

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/formwright` is a new opt-in package that builds Joinery's forms on Formwright, as
  shadcn's are built on react-hook-form. `setupJoineryForms()` registers Joinery's inputs as
  Formwright controls (`input` and its types, `number`, `currency`, `textarea`, `select`,
  `native-select`, `combobox`, `checkbox`, `checkbox-group`, `radio`, `switch`, `toggle`,
  `toggle-group`, `slider`, `range`, `rating`, `input-otp` and `date-picker`), so Formwright's own
  names render Joinery's components, and makes `JoineryFieldLayout` the layout every field uses:
  shadcn's Field around a FieldLabel, the control, a FieldDescription and a FieldError, or a FieldSet
  under a FieldLegend for a group control, in each control's orientation, or
  `@layout="joinery-vertical"`, `joinery-horizontal` or `joinery-responsive`.
  `registerJoineryControls({ only, except })` and `registerJoineryLayouts()` register them alone, each
  control is exported for `@control={{…}}`, and `asFieldErrors` makes a layout of your own's errors a
  FieldError. A textarea field's `@showCount` shows its count in an Input Group addon, as Formwright's
  own textarea shows one. Its `/test-support` has a field harness for each control on Formwright's
  `FieldHarness` (`InputFieldHarness`, `SelectFieldHarness`, `RadioGroupFieldHarness`,
  `DatePickerFieldHarness`…), each reaching Joinery's own harness for its component, and `@form` and
  `findForm()`, which find a Formwright form inside a Joinery harness, following its portalled and
  top-layer parts, so a form in a dialog is the dialog's. `@ember-joinery/ember`'s `joinery.css` now
  styles Formwright's fields (`formwright.css`): it takes Formwright's wrappers out of the Field's box
  tree and restates the Field's rules one wrapper down. Nothing in the core packages imports it.

### Minor Changes

- 17c5b5c: The Formwright controls' built-in strings go through the app's translator, from
  `@ember-joinery/formwright/messages`: the date picker's placeholder, the combobox's empty text,
  and a range slider's thumb names (`{label}, {thumb}`, with the slider's own `Minimum` and
  `Maximum`); a rating's stars use the primitives' message. An argument still wins. The date
  picker's and the currency control's `@locale` default to the translator's.

### Patch Changes

- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
