---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Switch` is shadcn's Switch, on Radix's, in its `default` and `sm` sizes: `@checked`,
`@defaultChecked` and `@onCheckedChange`, `@disabled` and `@required`, and a block that renders
inside the thumb (an icon, say). In a form, a hidden native checkbox beside it submits its
`name` and `value`. `@ember-joinery/primitives/switch` is the headless one, covering
ember-primitives' `Switch`, with a `Thumb` you render yourself, and
`@ember-joinery/test-support` adds `SwitchHarness`.
