# Aspect Ratio

Holds its content to a width-to-height ratio, as Radix's `AspectRatio`: an outer box as wide as
its container, held to the ratio by its bottom padding, and an inner box that fills it. It sets
only the styles that hold the ratio, through the CSSOM, so a strict Content Security Policy
allows them; the styled [Aspect Ratio](/components/aspect-ratio.md) is built on it.

<Example @name="aspect-ratio-headless" @title="A 16:9 box" />

## Usage

```gts
import { AspectRatio } from '@ember-joinery/primitives/aspect-ratio'

const widescreen = 16 / 9

<template>
  <AspectRatio @ratio={{widescreen}}>
    <img src="/photo.jpg" alt="A landscape" style="width: 100%; height: 100%; object-fit: cover" />
  </AspectRatio>
</template>
```

## API

| Argument | Type     | Default | What it does                                             |
| -------- | -------- | ------- | -------------------------------------------------------- |
| `@ratio` | `number` | `1`     | Width over height; one it can't use is a square          |
| `@as`    | tag name | `div`   | The inner element's tag                                  |
| `@name`  | `string` |         | Its name, for `AspectRatioHarness` (`data-test-jn-name`) |

Attributes, `class` included, go on the inner box; its `position` and insets are the
component's. The outer box carries `data-jn-aspect-ratio-wrapper`.

## Testing

```ts
import { AspectRatioHarness } from '@ember-joinery/test-support'

const box = new AspectRatioHarness()
box.ratio // 1.777…
box.width // 256
box.wrapper // the outer box
```
