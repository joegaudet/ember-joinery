# Direction

A provider component that sets the text direction for your application.

The `DirectionProvider` component is used to set the text direction (`ltr` or `rtl`) for your
application. This is essential for supporting right-to-left languages like Arabic, Hebrew, and
Persian.

Here's a preview of the component in RTL mode, in Arabic (upstream's preview also offers Hebrew
and English, a picker the frame doesn't have; its RTL switch turns the direction back). To see
more examples, look for the RTL section on components pages.

<Example @name="card-rtl" @title="Direction" @dir="rtl" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

```gts
import { DirectionProvider } from '@ember-joinery/ember'
```

It is the same component as `DirectionProvider` from `@ember-joinery/primitives/direction`
(see the [primitive's page](/primitives/direction.md)).

## Usage

```gts
import { DirectionProvider } from '@ember-joinery/ember'

<template>
  {{! for a whole app, set dir="rtl" on <html> as well }}
  <DirectionProvider @direction="rtl">
    {{! your app content }}
  </DirectionProvider>
</template>
```

`@direction` and `@dir` are the same argument, by both of upstream's names; `@direction` wins.
The provider renders a `<div dir>` with `display: contents`, so it adds no box to the layout
(`@as="span"` inside a `<p>` or a `<button>`). Joinery's components read the direction from
the document where they are, so `dir="rtl"` on any ancestor does the same as the provider.

## useDirection

Upstream's `useDirection` hook gets the current direction. In Ember it is a function of an
element, `getDirection`, which reads the direction where the element is (the nearest `dir`, up
to `<html>`):

```gts
import Component from '@glimmer/component'
import { getDirection } from '@ember-joinery/ember'

export default class MyComponent extends Component {
  onKeyDown = (event: KeyboardEvent) => {
    const direction = getDirection(event.currentTarget as Element) // 'ltr' or 'rtl'
    // …
  }
}
```

`isRTL(element)` is the same as `getDirection(element) === 'rtl'`. A component with a `@dir` of
its own passes it as the second argument, which wins: `getDirection(element, this.args.dir)`.

## API Reference

### DirectionProvider

| Argument     | Type             | Default | What it does                                   |
| ------------ | ---------------- | ------- | ---------------------------------------------- |
| `@direction` | `"ltr" \| "rtl"` |         | The direction of everything inside; it wins    |
| `@dir`       | `"ltr" \| "rtl"` | `"ltr"` | The same, by Radix's name                      |
| `@as`        | tag name         | `div`   | The tag to render (`span` in phrasing content) |

It yields the direction. Its element takes attributes, and has `data-slot="direction-provider"`
and `dir`.

### getDirection and isRTL

| Function                          | What it returns                                                   |
| --------------------------------- | ----------------------------------------------------------------- |
| `getDirection(element, explicit)` | `'ltr'` or `'rtl'`: `explicit` when it is one, else the element's |
| `isRTL(element, explicit)`        | Whether that is `'rtl'`                                           |

Without an element, they read `<html>`.

## Testing

The provider wraps content, so, like `VisuallyHidden`, it isn't a component root for the
harnesses and has no harness: test the direction where it matters, in the content, with a
component's harness or `getDirection` on its element.

## Upstream

shadcn/ui's [Direction](https://ui.shadcn.com/docs/components/radix/direction), from
`apps/v4/registry/bases/radix/ui/direction.tsx` at shadcn-ui/ui@8ab2771.
