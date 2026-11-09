# Rating

A rating, such as stars out of five, as ember-primitives' Rating: a
`<fieldset role="radiogroup">` of native radios, one per item, controlled or not, with half
ratings, a readonly and a display-only mode. It has no styles; the styled
[Rating](/components/rating.md) is built on it.

<Example @name="rating-headless" @title="A rating of your own" />

## Usage

```gts
import { Rating } from '@ember-joinery/primitives/rating'

<template>
  <Rating @defaultValue={{2}} @onValueChange={{this.rate}} @icon="★">
    <:label>Rate me</:label>
  </Rating>
</template>
```

- **State.** `@value` with `@onValueChange` controls it; `@defaultValue` starts it and lets it
  keep its own. Picking the rating it already has clears it to `0`.
- **Items.** `@max` (default 5) and `@step` (default 1) make the items: `@step={{0.5}}` gives an
  item to each half. Each is a `<span>` with `data-number`, `data-selected` while the rating
  reaches it and `data-percent-selected`, holding a `<label>` (its name, and the icon hidden
  from assistive technology) and its radio.
- **Icons.** `@icon` is a string (default `★`), or a component given `@value`, `@isSelected`,
  `@percentSelected` and `@readonly` (`RatingIconSignature`).
- **Your own layout.** With a block it yields `{ value, max, total, values, name, isReadonly,
isChangeable, needsSummary, summary, Stars, Item, Range }`: `<r.Stars @icon={{MyStar}} />`
  renders every item, `<r.Item @value={{n}} as |item|>` one, and `<r.Range />` a range input
  for finer values.
- **Readonly and display only.** `@readonly` cancels every pick, the arrow keys' included.
  `@interactive={{false}}` shows `@value` only, and summarises it for assistive technology
  with `@summary` (default "Rated 3 out of 5") unless the `<:label>` block shows it.
- **Forms.** Its radios share a name of their own, or `@formName`, so a form submits the
  rating.

## API

| Argument         | Type                           | Default             | What it does                    |
| ---------------- | ------------------------------ | ------------------- | ------------------------------- |
| `@value`         | `number`                       |                     | The rating, controlled          |
| `@defaultValue`  | `number`                       | `0`                 | The first rating, uncontrolled  |
| `@onValueChange` | `(value: number) => void`      |                     | Called with each rating picked  |
| `@max`           | `number`                       | `5`                 | The highest rating              |
| `@step`          | `number`                       | `1`                 | What each item adds             |
| `@readonly`      | `boolean`                      | `false`             | Whether it can't be changed     |
| `@interactive`   | `boolean`                      | `true`              | Whether it is a control at all  |
| `@disabled`      | `boolean`                      | `false`             | A `<fieldset disabled>`         |
| `@icon`          | `string` or a component        | `★`                 | What each item shows            |
| `@itemLabel`     | `(value: number) => string`    | `1 star`, `2 stars` | Each item's name                |
| `@summary`       | `({ value, total }) => string` | `Rated 3 out of 5`  | What a display-only rating says |
| `@formName`      | `string`                       | one of its own      | The radios' `name`              |
| `@name`          | `string`                       |                     | Its name, for `RatingHarness`   |

The root renders `role="radiogroup"`, `aria-readonly`, `data-value`, `data-total`,
`data-readonly`, `data-disabled` and `data-test-jn="rating"`. `ratingValues(max, step)` and
`ratingPercent(item, value, step)` are exported, for a layout of your own.

## Accessibility

Name it with the `<:label>` block (a `<legend>`) or `aria-label`; each radio is named by its
value. A `rating.Range` needs its own `aria-label`. The keyboard is the browser's, as for any
group of native radios.

## Testing

```ts
import { RatingHarness } from '@ember-joinery/test-support'

const rating = new RatingHarness()
await rating.select(3)
assert.strictEqual(rating.stars, '★ ★ ★ ☆ ☆')
```

The [Rating](/components/rating.md#testing) page lists its members.

## Upstream

ember-primitives' [Rating](https://github.com/universal-ember/ember-primitives/blob/9584c783bae34e6f0b628ec09a1e1f3cbdb4107e/ember-primitives/src/components/rating/rating.gts) at
universal-ember/ember-primitives@9584c78 (0.64.2). Its `@onChange` is `@onValueChange` here.
