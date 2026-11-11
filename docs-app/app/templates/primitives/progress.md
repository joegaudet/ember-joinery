# Progress

Shows how far along a task is. It is ember-primitives' and Radix's `Progress`: a `div` with the
`progressbar` role, its value in ARIA and data attributes, and an `Indicator` to draw. It has no
styles; the styled [Progress](/components/progress.md) is built on it.

<Example @name="progress-headless" @title="Seven of twelve files" />

## Usage

```gts
import { Progress } from '@ember-joinery/primitives/progress'

<template>
  <Progress @value={{this.uploaded}} aria-label="Upload" as |p|>
    <p.Indicator style={{this.widthOf p.percent}} />
  </Progress>
</template>
```

Without a value (or with `null`) it is indeterminate, as Radix's: no `aria-valuenow`, and
`data-state="indeterminate"`. A value outside `[0, @max]` is clamped into it, as
ember-primitives' is, and a value that isn't a finite number is 0. A `@max` that isn't a number
above 0 is 100.

`resolveProgress(value, max)` returns what it renders (the value, max, percent, decimal and
state), `progressState(value, max)` the state, and `defaultProgressLabel(value, max)` its
default value text, for an element of your own.

## API

| Argument         | Type                                     | Default | What it does                                          |
| ---------------- | ---------------------------------------- | ------- | ----------------------------------------------------- |
| `@value`         | `number \| null`                         |         | How far along it is; without one, it is indeterminate |
| `@max`           | `number`                                 | `100`   | The value it completes at                             |
| `@getValueLabel` | `(value: number, max: number) => string` | `33%`   | Its `aria-valuetext`                                  |
| `@name`          | `string`                                 |         | Its name, for `ProgressHarness` (`data-test-jn-name`) |

It yields:

| Yield         | What it is                                                                               |
| ------------- | ---------------------------------------------------------------------------------------- |
| `p.Indicator` | The bar: a `div` with the same `data-state`, `data-value`, `data-max` and `data-percent` |
| `p.value`     | The value, clamped, or `null` while it is indeterminate                                  |
| `p.max`       | The max                                                                                  |
| `p.percent`   | How far along it is, from 0 to 100, rounded to two places                                |
| `p.decimal`   | How far along it is, from 0 to 1                                                         |
| `p.state`     | `indeterminate`, `loading` or `complete`                                                 |

The root carries `aria-valuemin="0"`, `aria-valuemax`, `aria-valuenow`, `aria-valuetext`,
`data-state`, `data-value`, `data-max`, `data-min="0"` and `data-percent`, and takes
attributes.

## Accessibility

Name it, with `aria-label` or `aria-labelledby`: a `<label for>` doesn't name a progress bar,
which isn't a form control. Give `@getValueLabel` when a percentage isn't what the value means
(`7 of 12 files`).

## Testing

```ts
import { ProgressHarness } from '@ember-joinery/test-support'

const upload = new ProgressHarness()
upload.value // 7
upload.valueText // '7 of 12 files'
upload.state // 'loading'
```

See the styled [Progress](/components/progress.md#testing) for every member.
