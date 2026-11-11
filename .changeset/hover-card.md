---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`HoverCard` is shadcn's Hover Card, on Radix's: it opens once the pointer has rested on its
trigger for `@openDelay` (or the trigger has focus), below it, centred and 4px off, and closes
`@closeDelay` after the pointer leaves both, staying open while text in it is selected; a touch
doesn't open it. `@ember-joinery/primitives/hover-card` is the headless one, and
`@ember-joinery/test-support` adds `HoverCardHarness`.
