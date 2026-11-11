# Aspect Ratio

Displays content within a desired ratio.

<Example @name="aspect-ratio-demo" @title="Aspect Ratio" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { AspectRatio } from '@ember-joinery/ember'
```

## Usage

```gts
import { AspectRatio } from '@ember-joinery/ember'

const widescreen = 16 / 9

<template>
  <AspectRatio @ratio={{widescreen}}>
    <img src="..." alt="Image" class="size-full rounded-md object-cover" />
  </AspectRatio>
</template>
```

A template can't divide, so work the ratio out in JavaScript (`16 / 9`) or write it as a
number (`1.7778`). The box is as wide as its container; give what goes inside a width and
height of 100%.

## Square

A square aspect ratio component using `@ratio={{1}}`. This is useful for displaying images in a
square format.

<Example @name="aspect-ratio-square" @title="Square" />

## Portrait

A portrait aspect ratio component using a ratio of `9 / 16`. This is useful for displaying
images in a portrait format.

<Example @name="aspect-ratio-portrait" @title="Portrait" />

## RTL

The box is the same in both directions; the content around it lays itself out right to left
inside any element with `dir="rtl"` (see [Direction](/primitives/direction.md)).

<Example @name="aspect-ratio-rtl" @title="RTL" @dir="rtl" />

## API Reference

### AspectRatio

| Argument | Type     | Default | What it does                                             |
| -------- | -------- | ------- | -------------------------------------------------------- |
| `@ratio` | `number` | `1`     | Width over height                                        |
| `@as`    | tag name | `div`   | The inner element's tag                                  |
| `@name`  | `string` |         | Its name, for `AspectRatioHarness` (`data-test-jn-name`) |

It yields its block. It renders two boxes, as Radix's does: an outer one as wide as its
container, held to the ratio by its bottom padding, and an inner one that fills it. Attributes,
`class` included, go on the inner one, whose position and insets are the component's own (set
through the CSSOM, so a strict Content Security Policy allows them); style it with `class`. It
is the primitives' [`AspectRatio`](/primitives/aspect-ratio.md), as upstream's is Radix's.

### Data attributes

| Attribute                      | Value             |
| ------------------------------ | ----------------- |
| `class`                        | `jn-aspect-ratio` |
| `data-slot`                    | `aspect-ratio`    |
| `data-test-jn`                 | `aspect-ratio`    |
| `data-test-jn-name`            | its `@name`       |
| `data-jn-aspect-ratio-wrapper` | on the outer box  |

Upstream's adds only `data-slot`; no rule styles `jn-aspect-ratio`, which every part has as
its styling hook.

## Keyboard interactions

The box takes no focus and has no keys; what's inside keeps its own.

## Accessibility

The box adds nothing for assistive technology. Give an image its `alt`, and a video or map its
own name, as you would without it.

## Testing

`AspectRatioHarness` from `@ember-joinery/test-support` finds the inner box
(`data-test-jn="aspect-ratio"`), styled or headless:

```ts
import { AspectRatioHarness } from '@ember-joinery/test-support'

const photo = new AspectRatioHarness()
assert.strictEqual(photo.height, (photo.width * 9) / 16)
```

| Member    | What it is                             |
| --------- | -------------------------------------- |
| `ratio`   | Its width over its height, as laid out |
| `width`   | Its laid-out width, in CSS pixels      |
| `height`  | Its laid-out height, in CSS pixels     |
| `wrapper` | The outer box                          |

## Upstream

shadcn/ui's [Aspect Ratio](https://ui.shadcn.com/docs/components/radix/aspect-ratio), from
`apps/v4/registry/bases/radix/ui/aspect-ratio.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
on Radix's `AspectRatio`.
