---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

Layering, anchoring, portals and dismissal, one subpath export each. `layer`: `{{topLayer}}`
puts an element in the browser's top layer with the Popover API (`popover="manual"`, or `auto`
for the browser's light dismiss), nested layers always above their parents. `anchor`:
`anchorTo`, `FloatingUI` and `anchor()` place an element against another with CSS anchor
positioning where the browser has it and Floating UI (offset, flip, shift, size, arrow, hide)
otherwise or when `globalThis.JOINERY_ANCHOR_FALLBACK` is set, taking both Radix's Popper
arguments and ember-primitives' floating-ui ones, setting `data-side`, `data-align` and the
`--jn-anchor-*` custom properties; with ember-primitives' `exposeMetadata` and `flipTo`
middleware. `dismiss`: the dismiss stack (`{{dismissable}}`, `{{dismissableBranch}}`,
`registerDismissable`), as Radix's `DismissableLayer`: Escape closes only the top layer, and
pointers and focus outside close the layers they leave, nested layers counting as inside their
parents. `portal`: ember-primitives' `Portal`, `PortalTargets`, `PortalTarget` and `wormhole`,
with `<body>` as Radix's default target. `@ember-joinery/test-support` adds `press`,
`pressOutside`, `pressEscape`, `isInTopLayer`, `placementOf` and `setupAnchorFallback`.
