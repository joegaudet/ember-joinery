# Switch

A control that allows the user to toggle between checked and not checked.

<Example @name="switch-demo" @title="Switch" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Switch } from '@ember-joinery/ember'
```

## Usage

```gts
<Switch />
```

It renders a `<button role="switch">`, as Radix's does, so name it with a label: tie one to it
with `id` and `for`, or put it inside one. Its state is controlled with `@checked` and
`@onCheckedChange`, or uncontrolled from `@defaultChecked`.

## Description

Upstream's example puts a description beside the switch with Field, and comes with it.

## Choice Card

Card-style selection where `FieldLabel` wraps the entire `Field` for a clickable card pattern.
Upstream's example comes with Field.

## Disabled

Add `@disabled` to the `Switch` component to disable the switch. Add the `data-disabled` prop
to the `Field` component for styling. Upstream's example comes with Field.

## Invalid

Add the `aria-invalid` attribute to the `Switch` component to indicate an invalid state. Add
the `data-invalid` prop to the `Field` component for styling. Upstream's example comes with
Field.

## Size

Use `@size` to change the size of the switch: `default` or `sm`. Upstream's example lays its
two switches out with Field, and comes with it.

```gts
<Switch @size="sm" id="switch-size-sm" />
<Switch @size="default" id="switch-size-default" />
```

## Thumb

The switch's block renders inside its thumb, with the switch's state, so the thumb can show an
icon. Upstream's thumb is empty; this example is Joinery's own:

<Example @name="switch-thumb" @title="Thumb" />

```gts
import { Moon, Sun } from 'lucide'
import { Icon, Switch } from '@ember-joinery/ember'

<template>
  <Switch id="dark-mode" as |thumb|>
    <Icon @icon={{if thumb.isChecked Moon Sun}} class="m-0.5 size-3" />
  </Switch>
</template>
```

To style the thumb itself, select `[data-slot="switch-thumb"]` in your CSS (or
`[&_[data-slot=switch-thumb]]:…` on the switch, in a Tailwind app). The headless
[Switch](/primitives/switch.md) leaves the thumb to you entirely.

## RTL

The switch lays itself out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)): its thumb starts on the right and slides left.
Upstream's right-to-left example comes with Field.

## API Reference

### Switch

| Argument           | Type                | Default     | What it does                                        |
| ------------------ | ------------------- | ----------- | --------------------------------------------------- |
| `@checked`         | `boolean`           |             | The state, controlled                               |
| `@defaultChecked`  | `boolean`           | `false`     | The first state, uncontrolled                       |
| `@onCheckedChange` | `(checked) => void` |             | Called with each state the user asks for            |
| `@size`            | `"default" \| "sm"` | `"default"` | How big it is                                       |
| `@disabled`        | `boolean`           | `false`     | Whether it can't be changed                         |
| `@required`        | `boolean`           | `false`     | Whether a form needs it on                          |
| `@as`              | tag name            | `button`    | The tag to render                                   |
| `@name`            | `string`            |             | Its name, for `SwitchHarness` (`data-test-jn-name`) |

Its block renders inside the thumb, with `{ isChecked }`. It takes attributes on its
`<button>`: `id`, `aria-invalid`, `aria-label`, and, in a form, `name`, `value` (default `on`)
and `form`, which a hidden native checkbox beside it repeats, as Radix's does, so the form
submits it and checks `@required`. It is the primitives' [Switch](/primitives/switch.md) with
Joinery's styles.

### Data attributes

| Part   | Attribute           | Value                         |
| ------ | ------------------- | ----------------------------- |
| switch | `class`             | `jn-switch peer group/switch` |
| switch | `data-slot`         | `switch`                      |
| switch | `data-size`         | its `@size`                   |
| switch | `data-state`        | `checked` or `unchecked`      |
| switch | `data-disabled`     | present while `@disabled`     |
| switch | `data-test-jn`      | `switch`                      |
| switch | `data-test-jn-name` | its `@name`                   |
| thumb  | `class`             | `jn-switch-thumb`             |
| thumb  | `data-slot`         | `switch-thumb`                |
| thumb  | `data-state`        | the switch's                  |
| thumb  | `data-test-jn-part` | `thumb`                       |

## Keyboard interactions

| Key              | What it does              |
| ---------------- | ------------------------- |
| `Tab`            | Moves focus to the switch |
| `Space`, `Enter` | Turns it on or off        |

That is the [APG switch pattern](https://www.w3.org/WAI/ARIA/apg/patterns/switch/), which
its native `<button>` has built in. A disabled switch leaves the tab order.

## Accessibility

- It has the `switch` role and `aria-checked`.
- Name it with a label (`for`, or around it), `aria-label` or `aria-labelledby`. An icon in
  its thumb is decoration: keep it hidden, as `<Icon>` is without `@label`.
- `aria-invalid="true"` marks an error; `@required` sets `aria-required`.

## Testing

`SwitchHarness` from `@ember-joinery/test-support` drives a switch (`data-test-jn="switch"`),
styled or headless:

```ts
import { SwitchHarness } from '@ember-joinery/test-support'

const airplane = new SwitchHarness('airplane-mode') // <Switch @name="airplane-mode">
await airplane.toggle()
assert.true(airplane.isChecked)
```

| Member       | What it is                                                         |
| ------------ | ------------------------------------------------------------------ |
| `isChecked`  | Whether it is on                                                   |
| `label`      | Its accessible name: `aria-label`, `aria-labelledby` or its label  |
| `size`       | Its `@size`, or `null` for the headless switch                     |
| `isDisabled` | Whether it can't be changed                                        |
| `isRequired` | `aria-required`                                                    |
| `isInvalid`  | `aria-invalid`                                                     |
| `isFocused`  | Whether it has focus                                               |
| `thumb`      | The thumb, or `null`                                               |
| `input`      | The hidden native checkbox it submits through in a form, or `null` |
| `click()`    | Clicks it                                                          |
| `toggle()`   | Clicks it                                                          |
| `check()`    | Clicks it unless it is on                                          |
| `uncheck()`  | Clicks it if it is on                                              |
| `focus()`    | Focuses it                                                         |
| `blur()`     | Moves focus away                                                   |

## Upstream

shadcn/ui's [Switch](https://ui.shadcn.com/docs/components/radix/switch), from
`apps/v4/registry/bases/radix/ui/switch.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's `Switch`.
