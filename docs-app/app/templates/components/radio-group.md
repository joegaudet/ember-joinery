# Radio Group

A set of checkable buttons—known as radio buttons—where no more than one of the buttons can be
checked at a time.

Upstream's first example labels each item with Label, which hasn't landed in Joinery yet; it
comes with Label. Until then, Joinery's copy of it labels the items with native labels:

<Example @name="radio-group-native" @title="Radio Group" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { RadioGroup } from '@ember-joinery/ember'
```

## Usage

```gts
import { Label, RadioGroup } from '@ember-joinery/ember'

<template>
  <RadioGroup @defaultValue="option-one" as |group|>
    <div class="flex items-center gap-3">
      <group.Item @value="option-one" id="option-one" />
      <Label for="option-one">Option One</Label>
    </div>
    <div class="flex items-center gap-3">
      <group.Item @value="option-two" id="option-two" />
      <Label for="option-two">Option Two</Label>
    </div>
  </RadioGroup>
</template>
```

The group yields its items, as `group.Item` (upstream's `RadioGroupItem`). Its value is
controlled with `@value` and `@onValueChange`, or uncontrolled from `@defaultValue`.

## Composition

Use the following composition to build a `RadioGroup`:

```text
RadioGroup
├── group.Item
└── group.Item
```

## Description

Radio group items with a description using the `Field` component. Upstream's example comes
with Field.

## Choice Card

Use `FieldLabel` to wrap the entire `Field` for a clickable card-style selection. Upstream's
example comes with Field.

## Fieldset

Use `FieldSet` and `FieldLegend` to group radio items with a label and description.
Upstream's example comes with Field.

## Disabled

Use `@disabled` on `group.Item` to disable individual items, or on the group to disable them
all. The arrow keys pass over a disabled item. Upstream's example comes with Field.

## Invalid

Use `aria-invalid` on `group.Item` and `data-invalid` on `Field` to show validation errors.
Upstream's example comes with Field.

## RTL

The group lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)), or with `@dir="rtl"`, and its left and right arrow
keys swap. Upstream's right-to-left example comes with Field.

## API Reference

### RadioGroup

| Argument         | Type                         | Default        | What it does                                                |
| ---------------- | ---------------------------- | -------------- | ----------------------------------------------------------- |
| `@value`         | `string \| null`             |                | The chosen item's value, controlled                         |
| `@defaultValue`  | `string`                     | none           | The first value, uncontrolled                               |
| `@onValueChange` | `(value: string) => void`    |                | Called with each value the user chooses                     |
| `@disabled`      | `boolean`                    | `false`        | Disables every item                                         |
| `@required`      | `boolean`                    | `false`        | Whether a form needs a choice                               |
| `@orientation`   | `"horizontal" \| "vertical"` | both           | Which arrow keys move between items                         |
| `@dir`           | `"ltr" \| "rtl"`             | the document's | The direction, for the arrow keys                           |
| `@loop`          | `boolean`                    | `true`         | Whether the arrows go round from the last item to the first |
| `@formName`      | `string`                     |                | The form field its choice submits as (Radix's `name`)       |
| `@as`            | tag name                     | `div`          | The tag to render                                           |
| `@name`          | `string`                     |                | Its name, for `RadioGroupHarness` (`data-test-jn-name`)     |

It yields `{ Item, value }`, and takes attributes on its `role="radiogroup"` element, such as
`aria-label` or `aria-labelledby` to name the group. In a form, each item renders a hidden
native radio beside it under `@formName`, as Radix's does, so the form submits the choice and
checks `@required`. It is the primitives' [Radio Group](/primitives/radio-group.md) with
Joinery's styles.

### group.Item

| Argument    | Type      | Default  | What it does                               |
| ----------- | --------- | -------- | ------------------------------------------ |
| `@value`    | `string`  |          | What choosing it sets the group's value to |
| `@disabled` | `boolean` | `false`  | Whether it can't be chosen                 |
| `@as`       | tag name  | `button` | The tag to render                          |

It takes attributes on its `<button role="radio">`: `id`, `aria-invalid`, `aria-label`.

### Data attributes

| Part  | Attribute            | Value                                             |
| ----- | -------------------- | ------------------------------------------------- |
| group | `class`              | `jn-radio-group`                                  |
| group | `data-slot`          | `radio-group`                                     |
| group | `data-orientation`   | its `@orientation`                                |
| group | `data-disabled`      | present while `@disabled`                         |
| group | `data-test-jn`       | `radio-group`                                     |
| group | `data-test-jn-name`  | its `@name`                                       |
| item  | `class`              | `jn-radio-group-item group/radio-group-item peer` |
| item  | `data-slot`          | `radio-group-item`                                |
| item  | `data-state`         | `checked` or `unchecked`                          |
| item  | `data-disabled`      | present while disabled                            |
| item  | `data-test-jn-part`  | `item`                                            |
| item  | `data-test-jn-value` | its `@value`                                      |

The chosen item's dot is a `<span class="jn-radio-group-indicator"
data-slot="radio-group-indicator">` (`data-test-jn-part="indicator"`), holding a
`jn-radio-group-indicator-icon`.

## Keyboard interactions

| Key                       | What it does                                                        |
| ------------------------- | ------------------------------------------------------------------- |
| `Tab`                     | Moves focus into the group, onto the chosen item (or the first)     |
| `Space`                   | Chooses the focused item                                            |
| `ArrowDown`, `ArrowRight` | Moves focus to the next item and chooses it, going round at the end |
| `ArrowUp`, `ArrowLeft`    | Moves focus to the previous item and chooses it                     |
| `Home`, `End`             | Moves focus to the first or last item, without choosing it          |

That is the [APG radio group pattern](https://www.w3.org/WAI/ARIA/apg/patterns/radio/), as
Radix's RadioGroup does it: the items share one tab stop, right to left the left and right
arrows swap, and Enter does nothing.

## Accessibility

- The group has the `radiogroup` role; name it with `aria-label` or `aria-labelledby` (or a
  `FieldSet`'s legend, when Field lands).
- Each item has the `radio` role and `aria-checked`; name it with a label, as the examples do.
- `aria-invalid="true"` on an item marks an error; `@required` sets `aria-required` on the
  group.

## Testing

`RadioGroupHarness` from `@ember-joinery/test-support` drives a radio group
(`data-test-jn="radio-group"`), styled or headless, finding its items by `@value`:

```ts
import { RadioGroupHarness } from '@ember-joinery/test-support'

const spacing = new RadioGroupHarness('spacing') // <RadioGroup @name="spacing">
await spacing.choose('compact')
assert.strictEqual(spacing.value, 'compact')
await spacing.press('ArrowUp')
assert.strictEqual(spacing.value, 'comfortable')
```

| Member                  | What it is                                           |
| ----------------------- | ---------------------------------------------------- |
| `value`                 | The chosen item's value, or `null`                   |
| `options`               | Each item's value, in order                          |
| `items`                 | Each item's element                                  |
| `item(value)`           | The item with that value                             |
| `isChecked(value)`      | Whether that item is chosen                          |
| `isItemDisabled(value)` | Whether that item can't be chosen                    |
| `isItemInvalid(value)`  | Whether that item has `aria-invalid`                 |
| `labelOf(value)`        | That item's accessible name                          |
| `label`                 | The group's accessible name                          |
| `isDisabled`            | Whether the whole group is disabled                  |
| `isRequired`            | `aria-required`                                      |
| `orientation`           | `aria-orientation`, or `null`                        |
| `focused`               | The value of the item with focus, or `null`          |
| `tabStop`               | The value of the item Tab enters on, or `null`       |
| `inputOf(value)`        | That item's hidden native radio in a form, or `null` |
| `choose(value)`         | Clicks that item                                     |
| `focus(value)`          | Focuses that item, without choosing it               |
| `press(key)`            | Presses a key on the focused item                    |

## Upstream

shadcn/ui's [Radio Group](https://ui.shadcn.com/docs/components/radix/radio-group), from
`apps/v4/registry/bases/radix/ui/radio-group.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
on Radix's `RadioGroup`.
