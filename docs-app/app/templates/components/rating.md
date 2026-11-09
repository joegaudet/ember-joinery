# Rating

Shows a score out of a number of stars, and lets the user pick one, by halves if you like.

shadcn/ui has no Rating: this is ember-primitives' Rating, drawn in shadcn's terms. Its stars
are lucide's `Star`, outlined in `--muted-foreground` and filled with `--primary` up to the
rating.

<Example @name="rating-demo" @title="Rating" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Rating } from '@ember-joinery/ember'
```

## Usage

```gts
<Rating @defaultValue={{3}} @onValueChange={{this.rate}}>
  <:label>Rate this recipe</:label>
</Rating>
```

Each star is a native radio, so the keyboard works as in any radio group, and a form submits
the rating under `@formName`. Picking the rating it already has clears it. Name it with the
`<:label>` block, which renders a `<legend>`, or with `aria-label`.

## Half ratings

`@step={{0.5}}` gives each half of a star an item of its own, so the user can pick 3.5. The
first example above is one.

## Display only

`@interactive={{false}}` only shows `@value`, and says it for assistive technology ("Rated 4
out of 5"); with a `<:label>` block it shows that instead. `@readonly={{true}}` keeps a rating
the user can see and reach but not change.

<Example @name="rating-display" @title="Display only" />

## Icon

`@icon` takes any lucide icon in place of the star, and `@itemLabel` names each item to match.

<Example @name="rating-icon" @title="Icon" />

## RTL

It lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)): the first star is on the right, and each half star
shows its own side.

## API Reference

| Argument         | Type                           | Default             | What it does                                            |
| ---------------- | ------------------------------ | ------------------- | ------------------------------------------------------- |
| `@value`         | `number`                       |                     | The rating, controlled; `0` is none                     |
| `@defaultValue`  | `number`                       | `0`                 | The first rating, uncontrolled                          |
| `@onValueChange` | `(value: number) => void`      |                     | Called with each rating picked, `0` when one is cleared |
| `@max`           | `number`                       | `5`                 | The highest rating                                      |
| `@step`          | `number`                       | `1`                 | What each item adds; `0.5` for half ratings             |
| `@readonly`      | `boolean`                      | `false`             | Whether it can't be changed                             |
| `@interactive`   | `boolean`                      | `true`              | Whether it is a control at all                          |
| `@disabled`      | `boolean`                      | `false`             | Whether it is disabled                                  |
| `@size`          | `"sm" \| "default" \| "lg"`    | `default`           | 16, 20 or 24px stars                                    |
| `@icon`          | a `lucide` icon                | lucide's `Star`     | What each item draws                                    |
| `@itemLabel`     | `(value: number) => string`    | `1 star`, `2 stars` | Each item's name for assistive technology               |
| `@summary`       | `({ value, total }) => string` | `Rated 3 out of 5`  | What a display-only rating says                         |
| `@formName`      | `string`                       | one of its own      | The form field it submits as                            |
| `@name`          | `string`                       |                     | Its name, for `RatingHarness` (`data-test-jn-name`)     |

Its `<:label>` block gets `{ value, total }`. It takes attributes on its
`<fieldset role="radiogroup">`, such as `aria-label`. It is the primitives'
[Rating](/primitives/rating.md) with Joinery's styles.

### Data attributes

| Part  | Attribute               | Value                                  |
| ----- | ----------------------- | -------------------------------------- |
| root  | `class`                 | `jn-rating`                            |
| root  | `data-slot`             | `rating`                               |
| root  | `data-size`             | its `@size`                            |
| root  | `data-value`            | the rating                             |
| root  | `data-total`            | how many items it has                  |
| root  | `data-readonly`         | present while it can't be changed      |
| root  | `data-disabled`         | present while `@disabled`              |
| root  | `data-test-jn`          | `rating`                               |
| label | `class`                 | `jn-rating-label`                      |
| items | `class`                 | `jn-rating-items`                      |
| item  | `class`                 | `jn-rating-item`                       |
| item  | `data-number`           | its value                              |
| item  | `data-selected`         | present while the rating reaches it    |
| item  | `data-percent-selected` | how much of it the rating fills, 0–100 |
| item  | `data-half`             | `start` or `end`, in a half rating     |
| item  | `data-test-jn-part`     | `item`                                 |
| item  | `data-test-jn-value`    | its value                              |

Each item's star is an `<svg class="jn-rating-icon">`, hidden from assistive technology.

## Keyboard interactions

| Key                       | What it does                                                 |
| ------------------------- | ------------------------------------------------------------ |
| `Tab`                     | Moves focus to the picked star's radio (or the first)        |
| `ArrowRight`, `ArrowDown` | Moves to the next star and picks it, going round at the end  |
| `ArrowLeft`, `ArrowUp`    | Moves to the previous star and picks it                      |
| `Space`                   | Picks the focused star; on the picked one, clears the rating |

The browser does all of this, as for any group of native radios. Right to left, the left and
right arrows swap. A readonly rating keeps its value.

## Accessibility

- It is a `<fieldset role="radiogroup">` of native radios, each named by its value (`3 stars`);
  name the group with the `<:label>` block or `aria-label`.
- The stars are drawn inside each radio's label and hidden from assistive technology.
- A readonly rating has `aria-readonly="true"`, and a display-only one says its rating ("Rated
  4 out of 5"), as `@summary` words it.
- While a radio has focus, the stars show Nova's focus ring.

## Testing

`RatingHarness` from `@ember-joinery/test-support` drives a rating, styled or headless:

```ts
import { RatingHarness } from '@ember-joinery/test-support'

const recipe = new RatingHarness('recipe') // <Rating @name="recipe">
await recipe.select(4)
assert.strictEqual(recipe.value, 4)
assert.strictEqual(recipe.stars, '★ ★ ★ ★ ☆')
```

| Member             | What it is                                                             |
| ------------------ | ---------------------------------------------------------------------- |
| `value`            | The rating, `0` for none                                               |
| `total`            | How many items it has                                                  |
| `options`          | Each item's value                                                      |
| `stars`            | Each item as `★` while the rating reaches it, `☆` otherwise            |
| `label`            | The group's name: its legend, `aria-label` or `aria-labelledby`        |
| `summary`          | What a display-only rating says, or `''`                               |
| `labelOf(value)`   | The name of the item worth `value`                                     |
| `percentOf(value)` | How much of that item the rating fills, 0–100                          |
| `item(value)`      | That item's element                                                    |
| `input(value)`     | That item's radio                                                      |
| `items`            | Each item's element                                                    |
| `isReadonly`       | `aria-readonly="true"`                                                 |
| `isDisabled`       | Whether it is disabled                                                 |
| `focused`          | The value of the item whose radio has focus, or `null`                 |
| `select(value)`    | Picks it with a click (or, between items, on its range input)          |
| `focus()`          | Focuses the picked radio, or the first                                 |
| `press(key)`       | Presses a key on the focused radio, doing what the browser does for it |

## Upstream

ember-primitives' [Rating](https://github.com/universal-ember/ember-primitives/blob/9584c783bae34e6f0b628ec09a1e1f3cbdb4107e/ember-primitives/src/components/rating/rating.gts), from
`ember-primitives/src/components/rating` at universal-ember/ember-primitives@9584c78
(0.64.2). Its `@onChange` is Joinery's `@onValueChange`, and its `@value` is controlled.
