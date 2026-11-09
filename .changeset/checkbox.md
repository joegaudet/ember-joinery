---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Checkbox` is shadcn's Checkbox, on Radix's: `@checked`, `@defaultChecked` and
`@onCheckedChange` (controlled or not), the `'indeterminate'` state (`aria-checked="mixed"`),
`@disabled`, `@required`, and `@icon` and `@indeterminateIcon` to replace its marks. In a form, a
hidden native checkbox beside it submits its `name` and `value`, and a reset restores it.
`@ember-joinery/primitives/checkbox` is the headless one, with its `Indicator`, and
`@ember-joinery/test-support` adds `CheckboxHarness`.
