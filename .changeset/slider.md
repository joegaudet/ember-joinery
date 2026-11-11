---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Slider` is shadcn's Slider, on a new headless `Slider` in `@ember-joinery/primitives/slider`
(Radix's, covering ember-primitives' too): one `role="slider"` thumb per value, ranges and
multiple thumbs that pass each other (`@minStepsBetweenThumbs` keeps them apart), a `@step`
array that snaps to its values, vertical and inverted sliders, right to left through logical
edges, the APG keys, the pointer, `@onValueCommit`, `@getThumbLabel`, and hidden form inputs
with `@fieldName`. `@ember-joinery/test-support` adds `SliderHarness`.
