---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Rating` is ember-primitives' Rating: a `<fieldset role="radiogroup">` of native radios,
controlled or not (`@value`, `@defaultValue`, `@onValueChange`), with `@max`, half ratings
through `@step`, `@readonly`, a display-only mode (`@interactive={{false}}`) that summarises
itself, and its strings as arguments (`@itemLabel`, `@summary`).
`@ember-joinery/primitives/rating` is the headless one, whose block lays it out with `Stars`,
`Item` and `Range`; `@ember-joinery/ember`'s draws lucide's Star in shadcn's terms, in three
sizes, with half stars. `@ember-joinery/test-support` adds `RatingHarness`, which reads each
item's state (`stars`) and its icon's text (`starTexts`), and picks a value between the items on
a range or number input.
