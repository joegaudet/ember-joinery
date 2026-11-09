# Slider

An input where the user selects a value from within a given range.

<Example @name="slider-demo" @title="Slider" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Slider } from '@ember-joinery/ember'
```

## Usage

```gts
import { array } from '@ember/helper'

<template><Slider @defaultValue={{array 33}} @max={{100}} @step={{1}} /></template>
```

The value is an array, one number per thumb, as upstream's: `@defaultValue` starts it, or
`@value` and `@onValueChange` control it. It renders one thumb for each number. Size it with a
class or your own CSS: it is as wide as its container (`w-full`).

## Range

Use an array with two values for a range slider.

<Example @name="slider-range" @title="Range" />

## Multiple Thumbs

Use an array with multiple values for multiple thumbs.

<Example @name="slider-multiple" @title="Multiple Thumbs" />

Thumbs can meet and pass each other, as in Radix: the values stay sorted, and focus moves with
the value being dragged. `@minStepsBetweenThumbs` keeps them apart.

## Vertical

Use `@orientation="vertical"` for a vertical slider.

<Example @name="slider-vertical" @title="Vertical" />

A vertical slider is as tall as its container, and at least 10rem (`min-h-40`); upstream's
example sets `h-40`.

## Controlled

<Example @name="slider-controlled" @title="Controlled" />

Pass `@value` and `@onValueChange` to own the value, as the example does: the slider shows
`@value`, and `@onValueChange` hears each new one. `@onValueCommit` hears the value once a drag
ends, or a key has moved it. Upstream's label names the slider's root through `htmlFor`, which
labels no thumb; Joinery's example keeps that, so its thumbs keep their own names (see
[Accessibility](#accessibility)).

## Disabled

Use `@disabled` to disable the slider.

<Example @name="slider-disabled" @title="Disabled" />

## RTL

Joinery's slider takes its direction from the nearest `dir` (see
[Direction](/primitives/direction.md)), or from `@dir`: right to left, the range fills from the
right, and the left arrow steps up.

<Example @name="slider-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Slider

| Argument                 | Type                                                    | Default                   | What it does                                                 |
| ------------------------ | ------------------------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| `@defaultValue`          | `number[]`                                              | `[min]`                   | The first value, uncontrolled: one number per thumb          |
| `@value`                 | `number[]`                                              |                           | The value, controlled                                        |
| `@onValueChange`         | `(value: number[]) => void`                             |                           | Called with each new value, as it slides and steps           |
| `@onValueCommit`         | `(value: number[]) => void`                             |                           | Called when a drag ends, or a key has moved it               |
| `@min`                   | `number`                                                | `0`                       | The lowest value                                             |
| `@max`                   | `number`                                                | `100`                     | The highest value                                            |
| `@step`                  | `number \| number[]`                                    | `1`                       | How far a step moves; an array makes it snap to those values |
| `@minStepsBetweenThumbs` | `number`                                                | `0`                       | The fewest steps thumbs keep between them                    |
| `@orientation`           | `"horizontal" \| "vertical"`                            | `"horizontal"`            | Which way it runs                                            |
| `@disabled`              | `boolean`                                               | `false`                   | Whether it can't be moved                                    |
| `@inverted`              | `boolean`                                               | `false`                   | Run the values from the end of the line, or from the top     |
| `@dir`                   | `"ltr" \| "rtl"`                                        | the document's            | The text direction                                           |
| `@getThumbLabel`         | `(index: number, count: number) => string \| undefined` | `defaultSliderThumbLabel` | Each thumb's name                                            |
| `@fieldName`             | `string`                                                |                           | The form field the values submit as (`name[]` for several)   |
| `@form`                  | `string`                                                |                           | The `id` of the form the values belong to                    |
| `@as`                    | tag name                                                | `span`                    | The root's tag                                               |
| `@name`                  | `string`                                                |                           | Its name, for `SliderHarness` (`data-test-jn-name`)          |

A number in place of the array (`@defaultValue={{50}}`) works too, as in ember-primitives, and
`@onValueChange` then hears a number. Attributes go on the root `<span>`. For your own parts,
use the [Slider primitive](/primitives/slider.md).

### Data attributes

| Part   | `class` and `data-slot`           | Data attributes                     |
| ------ | --------------------------------- | ----------------------------------- |
| Root   | `jn-slider`, `slider`             | `data-orientation`, `data-disabled` |
| Track  | `jn-slider-track`, `slider-track` | `data-orientation`, `data-disabled` |
| Range  | `jn-slider-range`, `slider-range` | `data-orientation`, `data-disabled` |
| Thumbs | `jn-slider-thumb`, `slider-thumb` | `data-orientation`, `data-disabled` |

The root also has `data-test-jn="slider"` and `data-test-jn-name`; the track, range and thumbs
`data-test-jn-part` (`track`, `range`, `thumb`), and each thumb `data-test-jn-value`, its index.

## Keyboard interactions

| Key                      | What it does                                  |
| ------------------------ | --------------------------------------------- |
| `Tab`                    | Moves focus to each thumb in turn             |
| `ArrowRight`, `ArrowUp`  | Steps up (`ArrowLeft` steps up right to left) |
| `ArrowLeft`, `ArrowDown` | Steps down                                    |
| `PageUp`, `PageDown`     | Steps up or down ten times as far             |
| `Shift` with an arrow    | Steps ten times as far                        |
| `Home`                   | Moves the first thumb to the min              |
| `End`                    | Moves the last thumb to the max               |

That is the [APG slider pattern](https://www.w3.org/WAI/ARIA/apg/patterns/slider/), with
Radix's keys for several thumbs: `Home` and `End` move the outermost ones. Pressing the track
moves the nearest thumb there, and dragging slides it.

## Accessibility

- Each thumb is a `role="slider"` with `aria-valuemin`, `aria-valuenow`, `aria-valuemax` and
  `aria-orientation`. A disabled slider's thumbs leave the tab order.
- Each thumb needs a name. By default it is `Value` (ember-primitives'), or `Minimum` and
  `Maximum` for a range and `Value 2 of 3` past two (Radix's); give `@getThumbLabel` for words
  of your own, or another language. Upstream's examples name no thumb; Joinery's defaults name
  them, so the audit every example runs passes.

## Testing

`SliderHarness` from `@ember-joinery/test-support` drives a `<Slider>`:

```ts
import { SliderHarness } from '@ember-joinery/test-support'

const volume = new SliderHarness('volume') // <Slider @name="volume">
await volume.press('ArrowRight')
assert.deepEqual(volume.value, [76])
await volume.slideTo(25) // a press a quarter of the way along
```

| Member                     | What it is                                                              |
| -------------------------- | ----------------------------------------------------------------------- |
| `value`                    | Each thumb's value (`aria-valuenow`), in order                          |
| `min`, `max`               | Its bounds (`aria-valuemin`, `aria-valuemax`)                           |
| `labels`                   | Each thumb's name                                                       |
| `thumbs`, `thumb(index)`   | The thumbs' elements                                                    |
| `orientation`              | `horizontal` or `vertical`                                              |
| `isDisabled`               | Whether it can't be moved                                               |
| `focused`                  | The index of the thumb with focus, or `null`                            |
| `focus(index)`, `blur()`   | Moves focus to a thumb, or away                                         |
| `press(key, options)`      | Presses a key on the focused thumb (or `{ thumb }`'s); `shiftKey` too   |
| `slideTo(percent)`         | Presses the track at a share of its length, from where the values start |
| `drag(percent, { thumb })` | Drags a thumb there and lets go                                         |
| `pointAt(percent)`         | The client coordinates of that point, for pointer events of your own    |

## Upstream

shadcn/ui's [Slider](https://ui.shadcn.com/docs/components/radix/slider), from
`apps/v4/registry/bases/radix/ui/slider.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
