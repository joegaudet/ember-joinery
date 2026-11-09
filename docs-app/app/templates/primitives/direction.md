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
Components don't need a context to find it: they read the direction from the document where
they are, so it also holds for content in the top layer, such as an open popover.

```ts
import { getDirection, isRTL } from '@ember-joinery/primitives/direction'

getDirection(element) // 'rtl' or 'ltr', from the nearest dir (dir="auto" too)
getDirection(element, this.args.dir) // a component's own @dir wins
isRTL(element)
```

## API

| Argument     | Type             | Default | What it does                               |
| ------------ | ---------------- | ------- | ------------------------------------------ |
| `@dir`       | `'ltr' \| 'rtl'` | `ltr`   | The direction of everything inside         |
| `@direction` | `'ltr' \| 'rtl'` |         | The same, by the name shadcn uses; it wins |

It yields the direction. Its element takes attributes, and has `data-slot="direction-provider"`.

## Upstream

shadcn's [Direction](https://ui.shadcn.com/docs/components/direction) and Radix's
[Direction Provider](https://www.radix-ui.com/primitives/docs/utilities/direction-provider).
`useDirection()` becomes `getDirection(element)`.
