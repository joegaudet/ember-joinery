# Radio Group

A set of choices of which one, at most, is chosen, as Radix's `RadioGroup`: a
`role="radiogroup"` whose items are `<button role="radio">`s sharing one tab stop through
[Roving Focus](/primitives/roving-focus.md). It has no styles; the styled
[Radio Group](/components/radio-group.md) is built on it.

<Example @name="radio-group-headless" @title="A radio group of your own" />

## Usage

```gts
import { RadioGroup } from '@ember-joinery/primitives/radio-group'

<template>
  <RadioGroup @value={{this.drink}} @onValueChange={{this.setDrink}} aria-label="Drink" as |group|>
    <group.Item @value="coffee" id="coffee" as |item|>
      <item.Indicator class="my-dot" />
    </group.Item>
    <label for="coffee">Coffee</label>
    <group.Item @value="tea" id="tea" as |item|>
      <item.Indicator class="my-dot" />
    </group.Item>
    <label for="tea">Tea</label>
  </RadioGroup>
</template>
```

- **Value.** `@value` is the chosen item's `@value`, or `null` for none. Pass it with
  `@onValueChange` to control it, or start it with `@defaultValue`. A click on an item, or
  Space while it has focus, chooses it; a chosen item stays chosen.
- **Keys.** Tab enters the group on the chosen item (or the item focused last, or the first).
  The arrow keys move focus to the previous or next item and choose it, going round at the
  ends unless `@loop={{false}}`; `@orientation` narrows them to left and right or up and down,
  and right to left (from the document, or `@dir`) left and right swap. Home and End move
  focus without choosing, and Enter does nothing, as in Radix. Disabled items are passed over.
- **The mark.** `item.Indicator` renders a `<span>` while its item is chosen, and stays
  through an exit animation keyed on its `data-state`.
- **Forms.** In a form, each item renders a hidden native radio beside it, as Radix's does,
  named by the group's `@formName`, so the form submits the choice, checks `@required`, and
  hears `input` and `change` from the radio chosen.

## API

### RadioGroup

| Argument         | Type                         | Default        | What it does                                            |
| ---------------- | ---------------------------- | -------------- | ------------------------------------------------------- |
| `@value`         | `string \| null`             |                | The chosen value, controlled                            |
| `@defaultValue`  | `string`                     | none           | The first value, uncontrolled                           |
| `@onValueChange` | `(value: string) => void`    |                | Called with each value the user chooses                 |
| `@disabled`      | `boolean`                    | `false`        | Disables every item                                     |
| `@required`      | `boolean`                    | `false`        | Whether a form needs a choice                           |
| `@orientation`   | `"horizontal" \| "vertical"` | both           | Which arrow keys move                                   |
| `@dir`           | `"ltr" \| "rtl"`             | the document's | The direction, for the arrow keys                       |
| `@loop`          | `boolean`                    | `true`         | Whether the arrows go round                             |
| `@formName`      | `string`                     |                | The form field its choice submits as                    |
| `@as`            | tag name                     | `div`          | The tag to render                                       |
| `@name`          | `string`                     |                | Its name, for `RadioGroupHarness` (`data-test-jn-name`) |

It yields `{ Item, value }`, and renders `role="radiogroup"`, `aria-required`,
`aria-orientation`, `data-orientation`, `data-disabled`, `dir` (with `@dir`) and
`data-test-jn="radio-group"`.

### group.Item

| Argument    | Type      | Default  | What it does                               |
| ----------- | --------- | -------- | ------------------------------------------ |
| `@value`    | `string`  |          | What choosing it sets the group's value to |
| `@disabled` | `boolean` | `false`  | Whether it can't be chosen                 |
| `@as`       | tag name  | `button` | The tag to render                          |

It yields `{ Indicator, isChecked }`, and renders `role="radio"`, `aria-checked`,
`data-state`, `data-disabled`, `data-test-jn-part="item"` and `data-test-jn-value`.

## Accessibility

Name the group with `aria-label` or `aria-labelledby`, and each item with a label. The arrow
keys follow the [APG radio group pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/).
Keep the items `<button>`s, which turn Space into a click; an item `@as` another tag needs its
own key handling.

## Testing

```ts
import { RadioGroupHarness } from '@ember-joinery/test-support'

const drink = new RadioGroupHarness()
await drink.focus('tea')
await drink.press('ArrowDown')
assert.strictEqual(drink.value, 'water')
```

The [Radio Group](/components/radio-group.md#testing) page lists its members.
