# Portal

Renders content somewhere else in the document, as ember-primitives' and Radix's `Portal` do:
in a named target, an element, an element's id, or the end of `<body>`. The content stays its
component's own (its state, its actions, its destruction); only its DOM moves.

Joinery's overlays don't need one: the [top layer](/primitives/top-layer.md) puts them above
everything without moving them. Use a portal where the DOM position itself matters, such as
rendering into another region of the page.

<Example @name="portal-tray" @title="A card's note, in the tray" />

## Usage

```gts
import { Portal, PortalTargets } from '@ember-joinery/primitives/portal'

<template>
  {{! once, in the application template }}
  <PortalTargets />

  <Portal @to="popover">…</Portal>
</template>
```

`<PortalTargets />` renders ember-primitives' three targets, for popovers, tooltips and modals.
`@to` finds the nearest one above the portal, by its short name (`popover`, `tooltip`,
`modal`) or its full one (`PORTALS.popover`). `<PortalTarget @name="tray" />` adds a target of
your own, which can render before or after its portals.

## API

| Argument    | Type                  | What it does                                                                                        |
| ----------- | --------------------- | --------------------------------------------------------------------------------------------------- |
| `@to`       | `string` \| `Element` | A target's name, a selector, or an element. Without it (or `@wormhole`), the end of `<body>`        |
| `@append`   | `boolean`             | Add to what the target holds, instead of replacing it. Default `false`; `<body>` is always appended |
| `@wormhole` | `string` \| `Element` | ember-wormhole's way: an element's id, a selector, or an element. Always appends                    |

`wormhole(query)` finds the element for an id or a selector, and `findNearestTarget(origin,
name)` the target a portal at `origin` would use.

## Testing

A part rendered somewhere else names its component in `data-test-jn-owner` (the root's `id`),
and the harnesses follow it, so `card.part('note')` finds the note in the tray, as the
example's test does.
