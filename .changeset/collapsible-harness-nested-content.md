---
'@ember-joinery/test-support': patch
---

`CollapsibleHarness` finds content that sits inside another component, as upstream's settings
panel puts its `CollapsibleContent` inside a `FieldGroup`: when the content isn't among its own
parts, `content` (and with it `isShown`, `text` and `controlsContent`) is the element the
trigger's `aria-controls` names.
