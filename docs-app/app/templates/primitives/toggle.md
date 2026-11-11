# Toggle

A two-state button that can be either on or off. It is Radix's `Toggle`, and covers
ember-primitives' too. It has no styles; the styled [Toggle](/components/toggle.md) is built on
it.

<Example @name="toggle-headless" @title="A toggle of your own" />

## Usage

```gts
import { Toggle } from '@ember-joinery/primitives/toggle'

<template>
  <Toggle @pressed={{this.bold}} @onPressedChange={{this.setBold}} aria-label="Bold" as |pressed|>
    B
  </Toggle>
</template>
```

It renders a `<button type="button">` with `aria-pressed` and `data-state` (`on` or `off`),
which a click, `Enter` or `Space` flips. The state is controlled (`@pressed`,
`@onPressedChange`) or not (`@defaultPressed`), and the block is given it. ember-primitives'
`@onChange(value, pressed)` is `@onPressedChange(pressed)` here; for a set of toggles sharing a
value, use [Toggle Group](/primitives/toggle-group.md).

For an element of your own, `toggleSpec({ pressed, disabled, onPressedChange })` is what a
toggle puts on its element, for a `part()` modifier, and `toggleStateAttributes()` its ARIA
and data attributes:

```ts
import { part } from '@ember-joinery/primitives/part'
import { toggleSpec, type ToggleOptions } from '@ember-joinery/primitives/toggle'

const asToggle = part((options: ToggleOptions) => toggleSpec(options))
```

The styled package exports that modifier, with the styles, as `asToggle`.

## API

| Argument           | Type                         | Default  | What it does                                        |
| ------------------ | ---------------------------- | -------- | --------------------------------------------------- |
| `@defaultPressed`  | `boolean`                    | `false`  | Whether it starts pressed, uncontrolled             |
| `@pressed`         | `boolean`                    |          | Whether it is pressed, controlled                   |
| `@onPressedChange` | `(pressed: boolean) => void` |          | Called with each new state a press asks for         |
| `@disabled`        | `boolean`                    | `false`  | Whether it can't be pressed (`data-disabled` too)   |
| `@as`              | tag name                     | `button` | The tag to render                                   |
| `@name`            | `string`                     |          | Its name, for `ToggleHarness` (`data-test-jn-name`) |

It yields whether it is pressed. A listener of yours that calls `preventDefault()` on the click
keeps it as it is.

## Testing

```ts
import { ToggleHarness } from '@ember-joinery/test-support'

const toggle = new ToggleHarness()
await toggle.toggle()
assert.strictEqual(toggle.state, 'on')
```

See the styled [Toggle](/components/toggle.md#testing) for every member.
