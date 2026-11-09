# Progress

Displays an indicator showing the completion progress of a task, typically displayed as a
progress bar.

<Example @name="progress-demo" @title="Progress" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Progress } from '@ember-joinery/ember'
```

## Usage

```gts
<Progress @value={{33}} aria-label="Upload" />
```

Give it a name, as the example does: `aria-label`, or `aria-labelledby` naming the element
that labels it.

## Label

Use a `Field` component to add a label to the progress bar. Upstream's example comes with
Field.

## Controlled

A progress bar that can be controlled by a slider.

<Example @name="progress-controlled" @title="Controlled" />

`@value` is the value: pass a tracked value, and the bar follows it. The example keeps the
[Slider](/components/slider.md)'s value, an array, and gives the bar its first number.

## RTL

Like upstream's, the bar fills from the left in both directions: upstream's right-to-left
copy of the component moves its indicator the same way, and its example mirrors it with
`rtl:rotate-180`. Do the same in a Tailwind app, or with `rotate: 180deg` in a `[dir="rtl"]`
rule of your own. Upstream's right-to-left example has a Field, so it comes with Field.

## API Reference

### Progress

| Argument         | Type                                     | Default | What it does                                                                                     |
| ---------------- | ---------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| `@value`         | `number \| null`                         |         | How far along it is, from 0 to `@max`; clamped into that range. Without one, it is indeterminate |
| `@max`           | `number`                                 | `100`   | The value it completes at                                                                        |
| `@getValueLabel` | `(value: number, max: number) => string` | `66%`   | What assistive technology announces for the value (`aria-valuetext`)                             |
| `@name`          | `string`                                 |         | Its name, for `ProgressHarness` (`data-test-jn-name`)                                            |

It renders a `div` with the `progressbar` role, on the headless
[Progress](/primitives/progress.md), and takes attributes on it; size it with a class
(`w-[60%]`) or CSS of your own. Upstream's takes Radix's props; these are Radix's `value`,
`max` and `getValueLabel`.

### Data attributes

| Attribute                                                           | On            | Value                                                    |
| ------------------------------------------------------------------- | ------------- | -------------------------------------------------------- |
| `class`                                                             | the root      | `jn-progress`                                            |
| `class`                                                             | the indicator | `jn-progress-indicator`                                  |
| `data-slot`                                                         | each          | `progress`, `progress-indicator`                         |
| `data-state`                                                        | each          | `indeterminate`, `loading` or `complete`, as Radix's     |
| `data-value`, `data-max`                                            | each          | the value (left off while indeterminate) and the max     |
| `data-percent`                                                      | each          | how far along it is, from 0 to 100, as ember-primitives' |
| `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-valuetext` | the root      | its value, 0, its max, and what `@getValueLabel` says    |
| `data-test-jn`                                                      | the root      | `progress`                                               |
| `data-test-jn-name`                                                 | the root      | its `@name`                                              |
| `data-test-jn-part`                                                 | the indicator | `indicator`                                              |

## Accessibility

- It has the `progressbar` role, with its value, max and value text in ARIA. Upstream's leaves
  its value off the Radix root, so a screen reader hears it as indeterminate; Joinery's
  announces it.
- Name it, with `aria-label` or `aria-labelledby`: a `<label for>` doesn't name a progress bar,
  which isn't a form control.
- A value that changes isn't announced as it changes (a progress bar isn't a live region); a
  screen reader reads it when the user reaches it.

## Testing

`ProgressHarness` from `@ember-joinery/test-support` reads a progress bar through its ARIA:

```ts
import { ProgressHarness } from '@ember-joinery/test-support'

const upload = new ProgressHarness('upload') // <Progress @name="upload">
assert.strictEqual(upload.value, 66)
assert.strictEqual(upload.valueText, '66%')
assert.false(upload.isComplete)
```

| Member            | What it is                                                       |
| ----------------- | ---------------------------------------------------------------- |
| `value`           | `aria-valuenow`, or `null` while it is indeterminate             |
| `max`             | `aria-valuemax`                                                  |
| `min`             | `aria-valuemin`, 0                                               |
| `valueText`       | `aria-valuetext`                                                 |
| `percent`         | How far along it is, from 0 to 100, or `null`                    |
| `state`           | `data-state`: `indeterminate`, `loading` or `complete`           |
| `isIndeterminate` | Whether it has no value                                          |
| `isComplete`      | Whether its value is its max                                     |
| `label`           | Its accessible name: `aria-label`, else `aria-labelledby`'s text |
| `indicator`       | The bar                                                          |

## Upstream

shadcn/ui's [Progress](https://ui.shadcn.com/docs/components/radix/progress), from
`apps/v4/registry/bases/radix/ui/progress.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Progress](https://www.radix-ui.com/docs/primitives/components/progress) and
ember-primitives' `Progress` (0.64.2).
