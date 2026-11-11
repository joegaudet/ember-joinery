# Icon

Draws an icon from [Lucide](https://lucide.dev/), the icon set shadcn/ui uses. Joinery uses
the framework-agnostic `lucide` package: import each icon you use, so a build keeps only those.

<Example @name="icon-demo" @title="Icons" />

## Usage

```gts
import { ArrowUp } from 'lucide'
import { Icon } from '@ember-joinery/ember'

<template><Icon @icon={{ArrowUp}} /></template>
```

Add `lucide` to your app (`pnpm add lucide`). Upstream's examples import from `lucide-react`,
with an `Icon` suffix: `ArrowUpIcon` there is `ArrowUp` here.

It renders an `<svg>` as lucide-react does: 24×24, `fill="none"`, a round `currentColor`
stroke, and the class `lucide`. Inside a component, the component's CSS sizes it (a Button's
icons are 16px). Mark an icon's side in a Button or a Badge with `data-icon="inline-start"` or
`data-icon="inline-end"`.

Components that show an icon of their own (a Select's chevron, a Dialog's close button) take a
replacement for it, so you can use any icon set.

## API

| Argument               | Type            | Default        | What it does                                                     |
| ---------------------- | --------------- | -------------- | ---------------------------------------------------------------- |
| `@icon`                | a `lucide` icon |                | The icon to draw                                                 |
| `@size`                | `number`        | `24`           | Its width and height                                             |
| `@color`               | `string`        | `currentColor` | The stroke colour                                                |
| `@strokeWidth`         | `number`        | `2`            | The stroke width, in the 24-unit grid                            |
| `@absoluteStrokeWidth` | `boolean`       | `false`        | Keep the stroke `@strokeWidth` pixels wide at any size           |
| `@label`               | `string`        |                | What a standalone icon means; without it, the icon is decorative |
| `@name`                | `string`        |                | Its name, for `IconHarness` (`data-test-jn-name`)                |

`@icon` takes lucide's own format, `['svg', attributes, elements]`, or the elements alone (as
newer `lucide` versions export them). It draws the elements lucide's icons are made of
(`path`, `circle`, `rect`, `line`, `polyline`, `polygon` and `ellipse`).

## Accessibility

Without `@label`, an icon has `aria-hidden="true"`: next to text, or inside a button that has
`aria-label`, it adds nothing to read. With `@label`, it is an image (`role="img"`) with that
name.

## Testing

`IconHarness` from `@ember-joinery/test-support` finds an icon (`data-test-jn="icon"`).

| Member         | What it is                            |
| -------------- | ------------------------------------- |
| `label`        | Its `@label`, or `null`               |
| `isDecorative` | Whether assistive technology skips it |

## Upstream

shadcn/ui's components use `lucide-react`; Joinery's `<Icon>` draws the same icons from
`lucide`, at the version upstream pins (0.474.0).
