---
'@ember-joinery/formwright': minor
---

The Formwright controls' built-in strings go through the app's translator, from
`@ember-joinery/formwright/messages`: the date picker's placeholder, the combobox's empty text,
and a range slider's thumb names (`{label}, {thumb}`, with the slider's own `Minimum` and
`Maximum`); a rating's stars use the primitives' message. An argument still wins. The date
picker's and the currency control's `@locale` default to the translator's.
