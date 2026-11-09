# Dismiss

Overlays close when you press Escape or press outside them, and when several are open, the
top one closes first. The dismiss stack keeps that order for every open layer, as Radix's
`DismissableLayer` does:

- **Escape** goes to the top layer only. It closes, and the keydown is cancelled, so nothing
  underneath (another layer, a `<dialog>`) closes with it.
- **A press outside** goes to every layer it lands outside of, top first.
- **Focus moving outside** goes to every layer it left.
- **A nested layer counts as inside** the one it is in, wherever it is rendered: a layer whose
  element or trigger is inside another is nested in it. So a press in a submenu leaves its
  menu open, and a press in the menu closes only the submenu.

<Example @name="dismiss-nested" @title="Nested panels" />

## Usage

```gts
import { array } from '@ember/helper'
import { dismissable } from '@ember-joinery/primitives/dismiss'
import { topLayer } from '@ember-joinery/primitives/layer'

<template>
  {{#if this.open}}
    <div {{topLayer}} {{dismissable onDismiss=this.close inside=(array this.trigger)}}>…</div>
  {{/if}}
</template>
```

`onDismiss` hears why (`escape-key`, `pointer-outside` or `focus-outside`): close the layer
there. `inside` lists elements that count as part of the layer though they are outside it,
usually its trigger, so pressing the trigger toggles the layer instead of dismissing it and
opening it again. Events from before the layer opened, such as the press that opened it, are
ignored. A touch waits for its click, so a finger that goes down to scroll closes nothing.

## Keeping a layer open

Each handler gets the event first, and cancelling it (`event.preventDefault()`) keeps the
layer open:

| Argument               | Called when                           | With                                                      |
| ---------------------- | ------------------------------------- | --------------------------------------------------------- |
| `onEscapeKeyDown`      | Escape is pressed and this is the top | The `keydown`                                             |
| `onPointerDownOutside` | A pointer goes down outside it        | A `CustomEvent` whose `detail.originalEvent` is the press |
| `onFocusOutside`       | Focus moves outside it                | A `CustomEvent` whose `detail.originalEvent` is the focus |
| `onInteractOutside`    | Either of the last two, after its own | The same event                                            |

## Modal layers

`disableOutsidePointerEvents=true` makes everything outside the layer ignore the pointer, as a
modal menu does: `pointer-events: none` on `<body>`, and `auto` on the layer and the layers
above it. Layers below it stop hearing presses outside them, too. Everything goes back when it
closes.

## Branches and the stack

`{{dismissableBranch}}` makes an element count as inside every layer, as Radix's
`DismissableLayer.Branch` does: for something that sits beside the layers, such as a toast
region. `registerDismissable(element, options)` puts an element on the stack from JavaScript,
and `dismissableLayers()` lists the stack, bottom first.

A [top layer](/primitives/top-layer.md) with `popover="auto"` is on the stack too, but it is the
browser's to close: Escape and presses are left to it while it is on top.

## Testing

`@ember-joinery/test-support` presses the way a user does:

- `pressEscape(target?)` presses Escape where focus is (or on `target`);
- `press(element)` presses an element as a pointer does (`pointerdown`, then a click). The
  dismiss stack listens for `pointerdown`, which `click()` alone doesn't send;
- `pressOutside(target?)` presses outside every layer (on the test's root element by default).
