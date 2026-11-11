# Direction

Joinery supports right-to-left layouts: components use logical properties, and their arrow
keys follow the text direction. `DirectionProvider` sets the direction for everything inside it,
as Radix's and shadcn's do, and `getDirection` is how a component reads it.

<Example @name="direction-provider" @title="Switching direction" />

## Usage

```gts
import { DirectionProvider } from '@ember-joinery/primitives/direction'

<template>
  <DirectionProvider @dir="rtl">
    {{! every component in here lays out, and moves with the arrow keys, right to left }}
  </DirectionProvider>
</template>
```

For a whole right-to-left app, set `dir="rtl"` on `<html>` as well, as shadcn's docs do; the
provider is for a part of a page that differs from the rest.

The provider renders a `<div dir>` with `display: contents`, so it adds no box to the layout.
Inside phrasing content, such as a `<p>` or a `<button>`, where a `<div>` isn't allowed, give it
`@as="span"`. It sets `display` through the CSSOM rather than a `style` attribute, so a strict
Content Security Policy doesn't block it. Components don't need a context to find it: they read
the direction from the document where they are, so it also holds for content in the top layer,
such as an open popover. (Radix's provider renders no element; this one needs one to carry
`dir`.)

```ts
import { getDirection, isRTL } from '@ember-joinery/primitives/direction'

getDirection(element) // 'rtl' or 'ltr', from the nearest dir (dir="auto" too)
getDirection(element, this.args.dir) // a component's own @dir wins
isRTL(element)
```

## API

| Argument     | Type             | Default | What it does                                   |
| ------------ | ---------------- | ------- | ---------------------------------------------- |
| `@dir`       | `'ltr' \| 'rtl'` | `ltr`   | The direction of everything inside             |
| `@direction` | `'ltr' \| 'rtl'` |         | The same, by the name shadcn uses; it wins     |
| `@as`        | tag name         | `div`   | The tag to render (`span` in phrasing content) |

It yields the direction. Its element takes attributes, and has `data-slot="direction-provider"`.

## Testing

The provider wraps content, so, like `VisuallyHidden`, it isn't a component root for the
harnesses and has no harness: a part inside it still belongs to the component around it. Test
the direction where it matters, in the content: a component's harness, or `getDirection` on
its element, as the example's test does.

## Upstream

shadcn's [Direction](https://ui.shadcn.com/docs/components/direction) and Radix's
[Direction Provider](https://www.radix-ui.com/primitives/docs/utilities/direction-provider).
`useDirection()` becomes `getDirection(element)`.
