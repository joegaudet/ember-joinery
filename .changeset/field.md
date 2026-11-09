---
'@ember-joinery/ember': minor
'@ember-joinery/primitives': patch
'@ember-joinery/test-support': minor
---

`Field` is shadcn's Field family: `Field` (`@orientation` `vertical`, `horizontal` or
`responsive`, `@invalid`, `@disabled`), `FieldSet`, `FieldLegend` (`@variant`), `FieldGroup`,
`FieldContent`, `FieldLabel`, `FieldTitle`, `FieldDescription`, `FieldSeparator` and
`FieldError` (its block, or `@errors`: one message, or a list of distinct ones), with an `as…`
modifier for each part that has nothing of its own to render. `@ember-joinery/test-support`
adds `FieldHarness`, `FieldSetHarness` and `FieldGroupHarness`. A radio group's items now name
their group's `id` (the caller's own, when they give one) in `data-test-jn-owner`, so
`RadioGroupHarness` finds them inside a Field or a label around them, and the checkable
harnesses count a control in a disabled `<fieldset>` as disabled.
