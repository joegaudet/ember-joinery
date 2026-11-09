# Switch

A control that turns something on and off, as Radix's `Switch`: a `<button role="switch">`
with `aria-checked` and `data-state`, controlled or not, which yields its thumb for you to
render, style and fill. It covers ember-primitives' `Switch` too. It has no styles; the styled
[Switch](/components/switch.md) is built on it.

<Example @name="switch-headless" @title="A switch of your own" />

## Usage

```gts
import { Switch } from '@ember-joinery/primitives/switch'

<template>
  <Switch
    id="wifi"
    @checked={{this.wifi}}
    @onCheckedChange={{this.setWifi}}
    class="my-switch"
    as |control|
  >
    <control.Thumb class="my-thumb">{{if control.isChecked "on" "off"}}</control.Thumb>
  </Switch>
  <label for="wifi">Wi-Fi</label>
</template>
```

- **State.** Pass `@checked` with `@onCheckedChange` to control it, or start it with
  `@defaultChecked`. A click, Space or Enter turns it on or off.
- **The thumb.** `control.Thumb` is a `<span>` with the switch's `data-state` and
  `data-disabled`, so CSS can slide it; render it where you like, put anything inside it, or
  leave it out.
- **Forms.** In a form, it renders a hidden native checkbox beside it, as Radix's does, which
  repeats the `name`, `value` (default `on`) and `form` attributes you give the switch, so the
  form submits it, checks `@required`, and hears `input` and `change`.

## From ember-primitives

ember-primitives' `Switch` wraps a native checkbox and a label:
`<Switch @checked={{x}} @onChange={{fn}} as |s|><s.Control /><s.Label>Wi-Fi</s.Label></Switch>`.
Joinery's is Radix's, which every style sheet styles, and covers the same: `isChecked` is
yielded under the same name; the switch itself is the control; tie a label to it with `id` and
`for` (or put it inside one) where ember-primitives wires `s.Label`; `@checked` with
`@onCheckedChange` (or `@defaultChecked`) does what `@checked` with `@onChange` did; and in a
form it submits a native checkbox's value, as ember-primitives' does.

## API

| Argument           | Type                | Default  | What it does                                        |
| ------------------ | ------------------- | -------- | --------------------------------------------------- |
| `@checked`         | `boolean`           |          | The state, controlled                               |
| `@defaultChecked`  | `boolean`           | `false`  | The first state, uncontrolled                       |
| `@onCheckedChange` | `(checked) => void` |          | Called with each state the user asks for            |
| `@disabled`        | `boolean`           | `false`  | Whether it can't be changed                         |
| `@required`        | `boolean`           | `false`  | Whether a form needs it on                          |
| `@as`              | tag name            | `button` | The tag to render                                   |
| `@name`            | `string`            |          | Its name, for `SwitchHarness` (`data-test-jn-name`) |

It yields `{ Thumb, isChecked }`; `Thumb` takes `@as`. The root renders `role="switch"`,
`aria-checked`, `aria-required`, `data-state`, `data-disabled` and `data-test-jn="switch"`; the
thumb, `data-state`, `data-disabled` and `data-test-jn-part="thumb"`.

## Accessibility

Name it with a label (`for`, or around it), `aria-label` or `aria-labelledby`. Keep it a
`<button>`: that is what takes focus and turns Space (and Enter) into a click. With `@as`
another tag, give it `tabindex="0"` and handle those keys yourself.

## Testing

```ts
import { SwitchHarness } from '@ember-joinery/test-support'

const wifi = new SwitchHarness()
await wifi.toggle()
assert.true(wifi.isChecked)
```

The [Switch](/components/switch.md#testing) page lists its members.
