# Slider

A control for choosing a value, or a range, from within bounds. It is Radix's `Slider`, and
covers ember-primitives' too: ranges and multiple thumbs, discrete values, vertical sliders and
a thumb with content of its own. It has no styles; the styled
[Slider](/components/slider.md) is built on it.

<Example @name="slider-headless" @title="A price range, in steps" />

## Usage

```gts
import { array } from '@ember/helper'
import { Slider } from '@ember-joinery/primitives/slider'

<template>
  <Slider @defaultValue={{array 25 75}} @step={{5}} as |s|>
    <s.Track>
      <s.Range />
    </s.Track>
    {{#each s.thumbs as |thumb|}}
      <s.Thumb @index={{thumb.index}} />
    {{/each}}
  </Slider>
</template>
```

- **The value** is an array, one number per thumb, controlled (`@value`, `@onValueChange`) or
  not (`@defaultValue`); a number works too, and `@onValueChange` then hears a number.
  `@onValueCommit` hears it when a drag ends, or a key has moved it.
- **The thumbs** are `role="slider"` elements in the tab order. Render one per value with
  `{{#each s.thumbs}}`: the list keeps the same objects as the values change, so the DOM stays.
  `<s.Thumb>` takes a block, shown inside it (a tooltip with its value, say).
- **Discrete values.** Give `@step` an array, `@step={{array 0 10 20 50}}`, and the slider snaps
  to those values, evenly spaced along the track, as ember-primitives' does. `s.tickValues`
  yields them, sorted.
- **Placing.** The range and each thumb place themselves with an inline position, along logical
  edges (`inset-inline-start`, or `bottom` when vertical), so right to left flips them without
  a script. Make the root `position: relative` and the range `position: absolute`; the thumbs
  place themselves. A thumb
  is kept inside the track: it touches the start at the min and the end at the max, as in
  Radix.
- **The pointer.** Pressing the root moves the nearest thumb there, and dragging slides it; a
  thumb dragged past another swaps with it (`@minStepsBetweenThumbs` keeps them apart).
- **Forms.** With `@fieldName`, each thumb has a hidden input with its value (`name[]` for
  several), and an `input` event tells the form when it changes.

`defaultSliderThumbLabel(index, count, context?)` is the default name of a thumb, in the words of
the context's [translator](/getting-started/i18n.md) (English without one), and
`sliderPercent(value, min, max)` where a value sits, for parts of your own.

## API

| Argument                 | Type                                                    | Default                   | What it does                                                 |
| ------------------------ | ------------------------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| `@defaultValue`          | `number[] \| number`                                    | `[min]`                   | The first value, uncontrolled                                |
| `@value`                 | `number[] \| number`                                    |                           | The value, controlled                                        |
| `@onValueChange`         | `(value) => void`                                       |                           | Called with each new value, in the shape it was given        |
| `@onValueCommit`         | `(value) => void`                                       |                           | Called when a drag ends, or a key has moved it               |
| `@min`, `@max`           | `number`                                                | `0`, `100`                | The bounds (with a `@step` array, its first and last values) |
| `@step`                  | `number \| number[]`                                    | `1`                       | How far a step moves, or the values it snaps to              |
| `@minStepsBetweenThumbs` | `number`                                                | `0`                       | The fewest steps thumbs keep between them                    |
| `@orientation`           | `"horizontal" \| "vertical"`                            | `"horizontal"`            | Which way it runs                                            |
| `@disabled`              | `boolean`                                               | `false`                   | Whether it can't be moved                                    |
| `@inverted`              | `boolean`                                               | `false`                   | Run the values the other way                                 |
| `@dir`                   | `"ltr" \| "rtl"`                                        | the document's            | The text direction                                           |
| `@getThumbLabel`         | `(index: number, count: number) => string \| undefined` | `defaultSliderThumbLabel` | Each thumb's name                                            |
| `@fieldName`, `@form`    | `string`                                                |                           | The form field, and the form's `id`                          |
| `@as`                    | tag name                                                | `span`                    | The root's tag                                               |
| `@name`                  | `string`                                                |                           | Its name, for `SliderHarness` (`data-test-jn-name`)          |

It yields:

| Yield                           | What it is                                                                        |
| ------------------------------- | --------------------------------------------------------------------------------- |
| `s.Track`                       | The rail: a `<span>` with `data-orientation` and `data-disabled`                  |
| `s.Range`                       | The filled part, placed between the start (or the first thumb) and the last thumb |
| `s.Thumb`                       | A thumb: `@index` (default 0), `@fieldName` for its own field name, and `@as`     |
| `s.thumbs`                      | One `{ index, value, percent }` per value, the same objects as they change        |
| `s.values`                      | The values, as numbers                                                            |
| `s.tickValues`                  | The `@step` array's values, sorted, or `null`                                     |
| `s.min`, `s.max`, `s.step`      | The bounds and the step                                                           |
| `s.orientation`, `s.isDisabled` | As given                                                                          |

The root carries `data-orientation`, `data-disabled` and `aria-disabled`, and takes
attributes; so does each part.

## Accessibility

Each thumb has `aria-valuemin`, `aria-valuenow`, `aria-valuemax` and `aria-orientation`, and a
name: `Value`, `Minimum` and `Maximum`, or `Value 2 of 3`, unless `@getThumbLabel`, or an
`aria-label` or `aria-labelledby` on the thumb, gives another. The keys are the APG slider
pattern's (see the [styled Slider](/components/slider.md#keyboard-interactions)).

## Testing

```ts
import { SliderHarness } from '@ember-joinery/test-support'

const price = new SliderHarness()
await price.press('ArrowRight', { thumb: 0 })
assert.deepEqual(price.value, [50, 100])
```

See the styled [Slider](/components/slider.md#testing) for every member.
