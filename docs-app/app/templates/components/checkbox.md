# Checkbox

A control that allows the user to toggle between checked and not checked.

<Example @name="checkbox-demo" @title="Checkbox" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Checkbox } from '@ember-joinery/ember'
```

## Usage

```gts
<Checkbox />
```

It renders a `<button role="checkbox">`, as Radix's does, so name it with a label: tie one to
it with `id` and `for`, or put it inside one. [Label](/components/label.md) is Joinery's.

```gts
<Checkbox id="terms" />
<Label for="terms">Accept terms and conditions</Label>
```

## Checked State

Use `@defaultChecked` for uncontrolled checkboxes, or `@checked` and `@onCheckedChange` to
control the state.

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Checkbox } from '@ember-joinery/ember'

export default class Example extends Component {
  @tracked checked = false

  setChecked = (checked: boolean | 'indeterminate') => (this.checked = checked === true)

  <template><Checkbox @checked={{this.checked}} @onCheckedChange={{this.setChecked}} /></template>
}
```

## Indeterminate

Upstream's Radix Checkbox has a third state, `'indeterminate'`, for a checkbox that stands for
a group of which only some are checked. Pass it as `@checked` (or `@defaultChecked`): the
checkbox reads as `aria-checked="mixed"`, and a click checks it. Upstream's shows its check
mark then too; give `@indeterminateIcon` to show another, such as lucide's `Minus`. This
example is Joinery's own:

<Example @name="checkbox-indeterminate" @title="Indeterminate" />

```gts
import { Minus } from 'lucide'

<template>
  <Checkbox
    @checked={{this.all}}
    @onCheckedChange={{this.selectAll}}
    @indeterminateIcon={{Minus}}
  />
</template>
```

## Invalid State

Set `aria-invalid="true"` on the checkbox and `@invalid={{true}}` on the
[Field](/components/field.md) around it to show the invalid styles.

<Example @name="checkbox-invalid" @title="Invalid State" />

## Basic

Pair the checkbox with `Field` and `FieldLabel` for proper layout and labeling.

<Example @name="checkbox-basic" @title="Basic" />

## Description

Use `FieldContent` and `FieldDescription` for helper text.

<Example @name="checkbox-description" @title="Description" />

## Disabled

Use `@disabled` to prevent interaction and give the `<Field>` `@disabled={{true}}` (upstream's
`data-disabled`) for disabled styles.

<Example @name="checkbox-disabled" @title="Disabled" />

## Group

Use multiple fields to create a checkbox list.

<Example @name="checkbox-group" @title="Group" />

## Table

<Example @name="checkbox-table" @title="Table" />

## RTL

The checkbox lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)).

<Example @name="checkbox-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Checkbox

| Argument             | Type                         | Default          | What it does                                          |
| -------------------- | ---------------------------- | ---------------- | ----------------------------------------------------- |
| `@checked`           | `boolean \| "indeterminate"` |                  | The state, controlled                                 |
| `@defaultChecked`    | `boolean \| "indeterminate"` | `false`          | The first state, uncontrolled                         |
| `@onCheckedChange`   | `(checked) => void`          |                  | Called with each state the user asks for              |
| `@disabled`          | `boolean`                    | `false`          | Whether it can't be changed                           |
| `@required`          | `boolean`                    | `false`          | Whether a form needs it checked                       |
| `@icon`              | a `lucide` icon              | lucide's `Check` | The mark while checked (upstream's `CheckIcon`)       |
| `@indeterminateIcon` | a `lucide` icon              | `@icon`          | The mark while indeterminate                          |
| `@as`                | tag name                     | `button`         | The tag to render                                     |
| `@name`              | `string`                     |                  | Its name, for `CheckboxHarness` (`data-test-jn-name`) |

It takes attributes on its `<button>`: `id`, `aria-invalid`, `aria-label`, and, in a form,
`name`, `value` (default `on`) and `form`. There, a hidden native checkbox beside it repeats
them, as Radix's does, so the form submits it, checks `@required`, hears its `change`, and a
reset puts it back to its first state. It is the primitives'
[Checkbox](/primitives/checkbox.md) with Joinery's styles.

There is no `asCheckbox` modifier: a checkbox's behaviour lives on its own element, so give
`@as` a tag instead.

### Data attributes

| Attribute           | Value                                     |
| ------------------- | ----------------------------------------- |
| `class`             | `jn-checkbox peer`                        |
| `data-slot`         | `checkbox`                                |
| `data-state`        | `checked`, `unchecked` or `indeterminate` |
| `data-disabled`     | present while `@disabled`                 |
| `data-test-jn`      | `checkbox`                                |
| `data-test-jn-name` | its `@name`                               |

Its mark is a `<span class="jn-checkbox-indicator" data-slot="checkbox-indicator">` with the
same `data-state`, rendered while it is checked or indeterminate
(`data-test-jn-part="indicator"`).

## Keyboard interactions

| Key     | What it does                       |
| ------- | ---------------------------------- |
| `Tab`   | Moves focus to the checkbox        |
| `Space` | Checks or unchecks it              |
| `Enter` | Nothing, as with a native checkbox |

That is the [APG checkbox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/). A
disabled checkbox leaves the tab order.

## Accessibility

- It has the `checkbox` role and `aria-checked`, `mixed` while indeterminate.
- Name it with a label (`for`, or around it), `aria-label` or `aria-labelledby`. Its check mark
  is hidden from assistive technology.
- `aria-invalid="true"` marks an error; `@required` sets `aria-required`.

## Testing

`CheckboxHarness` from `@ember-joinery/test-support` drives a checkbox
(`data-test-jn="checkbox"`), styled or headless:

```ts
import { CheckboxHarness } from '@ember-joinery/test-support'

const terms = new CheckboxHarness('terms') // <Checkbox @name="terms">
await terms.check()
assert.true(terms.isChecked)
assert.strictEqual(terms.label, 'Accept terms and conditions')
```

| Member            | What it is                                                         |
| ----------------- | ------------------------------------------------------------------ |
| `state`           | `checked`, `unchecked` or `indeterminate`, from `aria-checked`     |
| `isChecked`       | Whether it is checked (an indeterminate one isn't)                 |
| `isIndeterminate` | Whether it is indeterminate                                        |
| `label`           | Its accessible name: `aria-label`, `aria-labelledby` or its label  |
| `isDisabled`      | Whether it can't be changed                                        |
| `isRequired`      | `aria-required`                                                    |
| `isInvalid`       | `aria-invalid`                                                     |
| `isFocused`       | Whether it has focus                                               |
| `indicator`       | Its mark, while it shows, or `null`                                |
| `input`           | The hidden native checkbox it submits through in a form, or `null` |
| `click()`         | Clicks it                                                          |
| `toggle()`        | Clicks it                                                          |
| `check()`         | Clicks it unless it is checked                                     |
| `uncheck()`       | Clicks it until it is unchecked (twice from indeterminate)         |
| `focus()`         | Focuses it                                                         |
| `blur()`          | Moves focus away                                                   |

## Upstream

shadcn/ui's [Checkbox](https://ui.shadcn.com/docs/components/radix/checkbox), from
`apps/v4/registry/bases/radix/ui/checkbox.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's `Checkbox`.
