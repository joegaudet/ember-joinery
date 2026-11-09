# Checkbox

A control the user checks and unchecks, as Radix's `Checkbox`: a `<button role="checkbox">`
with `aria-checked` and `data-state`, controlled or not, with an indeterminate state and a mark
that renders while it is checked. It has no styles; the styled
[Checkbox](/components/checkbox.md) is built on it.

<Example @name="checkbox-headless" @title="A checkbox of your own" />

## Usage

```gts
import { Checkbox } from '@ember-joinery/primitives/checkbox'

<template>
  <Checkbox
    id="terms"
    @checked={{this.terms}}
    @onCheckedChange={{this.setTerms}}
    class="my-checkbox"
    as |checkbox|
  >
    <checkbox.Indicator class="my-mark">
      {{if checkbox.isIndeterminate "–" "✓"}}
    </checkbox.Indicator>
  </Checkbox>
  <label for="terms">Accept terms and conditions</label>
</template>
```

- **State.** `@checked` is `true`, `false` or `'indeterminate'`. Pass it with
  `@onCheckedChange` to control it, or start it with `@defaultChecked` and let it keep its
  own. A click (or Space, which the browser turns into a click on a button) toggles it, and
  an indeterminate checkbox becomes checked. Enter does nothing, as on a native checkbox.
- **The mark.** `checkbox.Indicator` renders a `<span>` while it is checked or indeterminate,
  with the same `data-state`, and stays through an exit animation keyed on it, as Radix's
  `Presence` does. `@forceMount` keeps it rendered to animate it yourself.
- **Forms.** In a form, it renders a hidden native checkbox beside it, as Radix's does. That
  input repeats the `name`, `value` (default `on`) and `form` attributes you give the
  checkbox, so the form submits it, checks `@required`, and hears `input` and `change` when it
  changes; a form reset puts the checkbox back to its first state.
- A listener of your own that calls `event.preventDefault()` on `click` keeps it as it is.

## API

| Argument           | Type                         | Default  | What it does                                          |
| ------------------ | ---------------------------- | -------- | ----------------------------------------------------- |
| `@checked`         | `boolean \| "indeterminate"` |          | The state, controlled                                 |
| `@defaultChecked`  | `boolean \| "indeterminate"` | `false`  | The first state, uncontrolled                         |
| `@onCheckedChange` | `(checked) => void`          |          | Called with each state the user asks for              |
| `@disabled`        | `boolean`                    | `false`  | Whether it can't be changed                           |
| `@required`        | `boolean`                    | `false`  | Whether a form needs it checked                       |
| `@as`              | tag name                     | `button` | The tag to render                                     |
| `@name`            | `string`                     |          | Its name, for `CheckboxHarness` (`data-test-jn-name`) |

It yields `{ Indicator, checked, isChecked, isIndeterminate }`. `Indicator` takes `@as` and
`@forceMount`. The root renders `role="checkbox"`, `aria-checked` (`mixed` while
indeterminate), `aria-required`, `data-state` (`checked`, `unchecked` or `indeterminate`),
`data-disabled` and `data-test-jn="checkbox"`; the mark, `data-state`, `data-disabled` and
`data-test-jn-part="indicator"`. `CheckedState` is the type of its state.

## Accessibility

Name it with a label (`for`, or around it), `aria-label` or `aria-labelledby`. Keep it a
`<button>`: that is what takes focus and turns Space into a click. With `@as`
another tag, give it `tabindex="0"` and handle Space yourself.

## Testing

```ts
import { CheckboxHarness } from '@ember-joinery/test-support'

const terms = new CheckboxHarness()
await terms.check()
assert.true(terms.isChecked)
```

The [Checkbox](/components/checkbox.md#testing) page lists its members.
