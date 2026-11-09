---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`RadioGroup` is shadcn's Radio Group, on Radix's: it yields its `Item`s, which share one tab
stop, and an arrow key moves focus and the choice, going round (`@loop`) and flipping right to
left. `@value`, `@defaultValue` and `@onValueChange`, `@disabled` on the group or an item,
`@required`, `@orientation`, and `@formName` for the hidden native radios it submits in a form.
`@ember-joinery/primitives/radio-group` is the headless one, and `@ember-joinery/test-support`
adds `RadioGroupHarness`.
