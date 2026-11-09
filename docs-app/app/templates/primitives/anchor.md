# Anchor

Places one element against another, as Radix's Popper and ember-primitives' floating-ui
utilities do: on a side of it, at an alignment, flipping to the other side when there is no
room and shifting to stay in view. Where the browser has
[CSS anchor positioning](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_anchor_positioning),
the browser does the positioning, so it keeps up with scrolling without JavaScript. Elsewhere,
[Floating UI](https://floating-ui.com/) does it.

<Example @name="anchor-placement" @title="Side and alignment" />

## Usage

The `anchorTo` modifier goes on the floating element, with what to anchor it to: an element,
a selector, or a Floating UI virtual element (a point, for a context menu).

```gts
import { anchorTo } from '@ember-joinery/primitives/anchor'
import { topLayer } from '@ember-joinery/primitives/layer'

<template>
  <button id="more" type="button">More</button>
  <div {{topLayer}} {{anchorTo "#more" side="bottom" align="start" sideOffset=4}}>…</div>
</template>
```

`FloatingUI` is ember-primitives' component: no element of its own, it yields a modifier for
the reference, one for the floating element (`undefined` until the reference has rendered),
and the data of where it went.

```gts
import { FloatingUI } from '@ember-joinery/primitives/anchor'

<template>
  <FloatingUI @placement="bottom-start" @offsetOptions={{8}} as |reference floating util|>
    <button type="button" {{reference}}>More</button>
    {{#if floating}}
      <div {{floating}}>Placed {{util.data.placement}}</div>
    {{/if}}
  </FloatingUI>
</template>
```

In JavaScript, `anchor(floating, reference, options)` does the same and returns a function
that stops it.

## What the floating element gets

| On the element                                     | What it is                                                           |
| -------------------------------------------------- | -------------------------------------------------------------------- |
| `data-side`                                        | The side it ended up on, after any flip: `top`, `right`, `bottom`…   |
| `data-align`                                       | Where along that side: `start`, `center` or `end`                    |
| `--jn-anchor-width`, `--jn-anchor-height`          | The anchor's size, to make a menu as wide as its trigger             |
| `--jn-anchor-available-width`, `-available-height` | The room between the anchor and the viewport's edge                  |
| `--jn-anchor-transform-origin`                     | Where it grows from (the arrow's tip, or the edge facing the anchor) |

shadcn's styles animate on `data-side` (`data-[side=bottom]:slide-in-from-top-2`), and Joinery's
components map the custom properties to the names shadcn's styles read
(`--radix-popover-content-transform-origin`). Everything it set is put back when it stops.

## Options

`anchorTo`, `FloatingUI` and `anchor()` take Radix's Popper arguments and ember-primitives'
floating-ui ones. Where both name the same thing, Radix's win.

| Option                                       | Default  | What it does                                                                                                |
| -------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `side`                                       | `bottom` | The side of the anchor: `top`, `right`, `bottom` or `left`                                                  |
| `align`                                      | `center` | Where along it: `start`, `center` or `end`. `start` is the inline start, so the right edge in RTL           |
| `sideOffset`                                 | `0`      | The distance from the anchor, in pixels                                                                     |
| `alignOffset`                                | `0`      | A shift from the `start` or `end` edge, in pixels                                                           |
| `avoidCollisions`                            | `true`   | Flip and shift to stay in view                                                                              |
| `collisionPadding`                           | `0`      | How far from the viewport's edges to stay                                                                   |
| `sticky`                                     | `always` | `partial` stops it shifting past its anchor (Radix's default)                                               |
| `hideWhenDetached`                           | `true`   | Hide it while the anchor is scrolled out of view                                                            |
| `arrow`, `arrowPadding`                      |          | An arrow element inside it, placed and turned to point at the anchor as Radix's `PopperArrow` is            |
| `strategy`                                   | `fixed`  | The CSS `position`: `fixed` or `absolute`                                                                   |
| `placement`                                  | `bottom` | Floating UI's placement, such as `top-start`                                                                |
| `offsetOptions`                              | `0`      | Floating UI's offset: a distance, `{ mainAxis, crossAxis, alignmentAxis }`, or a function                   |
| `flipOptions`, `shiftOptions`, `hideOptions` |          | Floating UI's options for those. `flipOptions.elementContext: 'both'` also flips when the anchor is clipped |
| `middleware`                                 |          | More Floating UI middleware                                                                                 |
| `setData`                                    |          | Called with where it went, every time it moves (`anchorTo` only; `FloatingUI` yields it)                    |

## CSS anchor positioning, or Floating UI

`anchorMode(reference, options)` says which one positions an element: `css` where the browser
has anchor positioning and every option can be expressed in CSS, and `floating-ui` otherwise.
These need Floating UI: custom `middleware`, an `offsetOptions` function, a virtual reference,
collision padding, a cross-axis offset on a centred element, and Floating UI-only settings in
`flipOptions`, `shiftOptions` or `hideOptions`. The same module exports Floating UI's
`exposeMetadata` and ember-primitives' `flipTo` middleware, and `transformOrigin`.

The mode is decided each time an element is anchored, from `supportsAnchorPositioning()` and
`globalThis.JOINERY_ANCHOR_FALLBACK`: when that is `true`, Floating UI is used everywhere. CI
runs the whole test suite a second time that way.

## Testing

`placementOf(element)` from `@ember-joinery/test-support` reads `data-side` and `data-align`,
and `settled()` waits until the element is in place. `setupAnchorFallback(hooks)` forces
Floating UI for a module's tests, so a test can cover both modes, as this page's example does.
