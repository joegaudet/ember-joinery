---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Accordion` is shadcn's Accordion, and `@ember-joinery/primitives/accordion` the headless one
under it, Radix's, covering ember-primitives' too: `@type="single"` (optionally `@collapsible`) or
`"multiple"`, controlled (`@value`, `@onValueChange`) or not (`@defaultValue`), disabled items or
a disabled accordion, each item a heading with a trigger (`aria-expanded`, `aria-controls`) and a
content region labelled by it, and the arrow keys, Home and End between triggers, by
`@orientation` and direction. The styled trigger draws upstream's chevrons (`@icon` and
`@openIcon` replace them), and the content animates from its measured height.
`AccordionState` and `AccordionItemState` hold the behaviour for components built on it.
`@ember-joinery/test-support` adds `AccordionHarness`.
