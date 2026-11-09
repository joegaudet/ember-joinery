# Top Layer

Popovers, menus and tooltips have to show above everything, whatever their containers'
`overflow`, `z-index` or `transform`. Radix moves them to the end of `<body>` with a portal.
Joinery puts them in the browser's **top layer** instead, with the Popover API, and leaves them
where they are in the DOM: their events, focus order and CSS inheritance stay those of the
component that renders them.

<Example @name="layer-escape-overflow" @title="A popover the card can't clip" />

## Usage

```gts
import { topLayer } from '@ember-joinery/primitives/layer'

<template>
  {{#if this.open}}
    <div {{topLayer}}>Above everything</div>
  {{/if}}
</template>
```

`{{topLayer}}` sets `popover` on the element and calls `showPopover()` once the render is over;
when the element goes, it leaves the top layer. Layers stack in the order they open, and a
layer inside another always goes above it, even when both open in the same render.

## Manual or auto

| `popover=`           | Who closes it                                                                                                                                                                              |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `"manual"` (default) | You do, by removing the element. Pair it with [`{{dismissable}}`](/primitives/dismiss.md) for Escape and presses outside, as Joinery's components do                                       |
| `"auto"`             | The browser: Escape and a press outside close it (light dismiss), and opening another closes it unless it is inside that one. `@onHide` tells you, so your component's state can follow it |

```gts
<div {{topLayer popover="auto" source=this.trigger onHide=this.close}}>…</div>
```

`source` is the element that opened it: an auto popover opened from inside another stays open
with it when its trigger is in that one, wherever the popover is in the DOM.

## Styles

The browser's popover styles apply to the element: a border, padding, `Canvas` colours,
`overflow: auto`, and centred in the viewport (`inset: 0`, `margin: auto`). Style the element
over them, and position it against its trigger with [`anchorTo`](/primitives/anchor.md), which replaces the
positioning ones. An arrow outside the element's box needs `overflow: visible`.

## API

| Argument  | Type                   | What it does                                       |
| --------- | ---------------------- | -------------------------------------------------- |
| `popover` | `'manual'` \| `'auto'` | Who closes it. Default `manual`                    |
| `source`  | `Element`              | The element that opened it, for nesting            |
| `onHide`  | `() => void`           | Called when the browser hides it (an auto popover) |

`isInTopLayer(element)` says whether an element is in the top layer now (an open popover or a
modal `<dialog>`), and `supportsPopover()` whether the browser has the Popover API (every
supported browser does).

## Testing

`isInTopLayer(element)` from `@ember-joinery/test-support` reads the same thing in a test.
Layers are shown once the render is over, and `settled()` waits for that, so after
`await click(trigger)` the content is already in the top layer.
