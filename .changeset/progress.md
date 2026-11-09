---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`@ember-joinery/primitives/progress` is ember-primitives' and Radix's Progress: a
`progressbar` with its value, max and `@getValueLabel` text in ARIA and data attributes,
indeterminate without a value, clamping out-of-range values, and yielding an `Indicator` and
the value, percent and state; `resolveProgress()` returns what it renders. `Progress` in
`@ember-joinery/ember` is shadcn's, on it, and announces its value, which upstream's leaves off.
`@ember-joinery/test-support` adds `ProgressHarness`.
