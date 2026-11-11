---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Marker` is shadcn's Marker: an inline status, note, bordered row or labelled separator in a
conversation, with `@variant`, `@as`, an `asMarker` modifier for your own elements and components
(`<LinkTo {{asMarker}}>`), and its parts, yielded and exported (`MarkerIcon`, which is hidden
from assistive technology, and `MarkerContent`); `markerClasses()` and `markerAttributes()`
return what it renders, as upstream's `markerVariants`. `@ember-joinery/test-support` adds
`MarkerHarness`.
