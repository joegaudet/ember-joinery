# Toggle

A two-state button that can be either on or off.

<Example @name="toggle-demo" @title="Toggle" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Toggle } from '@ember-joinery/ember'
```

## Usage

```gts
<Toggle>Toggle</Toggle>
```

It renders a `<button type="button">` with `aria-pressed` and `data-state` (`on` or `off`).
Leave its state to it, starting from `@defaultPressed`, or own it with `@pressed` and
`@onPressedChange`:

```gts
<Toggle @pressed={{this.bold}} @onPressedChange={{this.setBold}} aria-label="Toggle bold">
  <Icon @icon={{Bold}} />
</Toggle>
```

It yields whether it is pressed, and an icon inside can style itself by it with the
`group/toggle` marker (`group-data-[state=on]/toggle:fill-foreground`), as in the first example.

## Outline

Use `@variant="outline"` for an outline style.

<Example @name="toggle-outline" @title="Outline" />

## With Text

<Example @name="toggle-text" @title="With Text" />

## Size

Use `@size` to change the size of the toggle.

<Example @name="toggle-sizes" @title="Size" />

## Disabled

<Example @name="toggle-disabled" @title="Disabled" />

## RTL

Joinery's styles use logical properties, so a toggle lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): an icon marked
`data-icon="inline-start"` moves to the right, and the narrower padding with it.

<Example @name="toggle-rtl" @title="RTL" @dir="rtl" />

## As Child

Upstream's `asChild` makes another component a toggle. In Joinery, give `@as` a tag, or put the
`asToggle` modifier on your own element or component. The modifier's state is yours: pass it
back as `pressed`.

```gts
import { asToggle } from '@ember-joinery/ember'

<template>
  <button
    type="button"
    {{asToggle pressed=this.bold onPressedChange=this.setBold variant="outline"}}
  >Bold</button>
</template>
```

## API Reference

### Toggle

| Argument           | Type                         | Default     | What it does                                        |
| ------------------ | ---------------------------- | ----------- | --------------------------------------------------- |
| `@variant`         | `"default" \| "outline"`     | `"default"` | How it looks                                        |
| `@size`            | `"default" \| "sm" \| "lg"`  | `"default"` | How big it is                                       |
| `@defaultPressed`  | `boolean`                    | `false`     | Whether it starts pressed, uncontrolled             |
| `@pressed`         | `boolean`                    |             | Whether it is pressed, controlled                   |
| `@onPressedChange` | `(pressed: boolean) => void` |             | Called with each new state a press asks for         |
| `@disabled`        | `boolean`                    | `false`     | Whether it can't be pressed                         |
| `@as`              | tag name                     | `button`    | The tag to render                                   |
| `@name`            | `string`                     |             | Its name, for `ToggleHarness` (`data-test-jn-name`) |

It yields whether it is pressed, and takes attributes on its element.

### The `asToggle` modifier

`{{asToggle pressed=… onPressedChange=… disabled=… variant=… size=… name=…}}` makes any element
or component a toggle, with the classes and attributes below, and keeps them current.
`toggleClasses(options)` and `toggleAttributes(options)` return the look, for code of your own.

### Data attributes

| Attribute           | Value                                                                             |
| ------------------- | --------------------------------------------------------------------------------- |
| `class`             | `jn-toggle jn-toggle-variant-<variant> jn-toggle-size-<size>`, and `group/toggle` |
| `data-slot`         | `toggle`                                                                          |
| `data-variant`      | its `@variant`                                                                    |
| `data-size`         | its `@size`                                                                       |
| `data-state`        | `on` or `off`                                                                     |
| `data-disabled`     | present while it is disabled                                                      |
| `data-test-jn`      | `toggle`                                                                          |
| `data-test-jn-name` | its `@name`                                                                       |

## Keyboard interactions

| Key              | What it does                           |
| ---------------- | -------------------------------------- |
| `Tab`            | Moves focus to the toggle, and past it |
| `Enter`, `Space` | Presses it: on, or off again           |

That is the [APG button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/) for a
toggle button, which a native `<button>` has built in.

## Accessibility

- It is a toggle button: `aria-pressed` says whether it is on.
- An icon-only toggle needs `aria-label`. Keep the label the same when it is pressed: the state
  is `aria-pressed`'s to say.

## Testing

`ToggleHarness` from `@ember-joinery/test-support` drives a `<Toggle>`, or an element with
`asToggle`. It is a [`ButtonHarness`](/components/button.md#testing), so every member of that
works too.

```ts
import { ToggleHarness } from '@ember-joinery/test-support'

const bold = new ToggleHarness('bold') // <Toggle @name="bold">
await bold.toggle()
assert.true(bold.isPressed)
```

| Member       | What it is                                    |
| ------------ | --------------------------------------------- |
| `isPressed`  | Whether it is pressed (`aria-pressed="true"`) |
| `state`      | `on` or `off` (`data-state`)                  |
| `variant`    | Its `@variant`                                |
| `size`       | Its `@size`                                   |
| `label`      | Its accessible name                           |
| `isDisabled` | Whether it can't be pressed                   |
| `toggle()`   | Presses it, as a click does                   |

## Upstream

shadcn/ui's [Toggle](https://ui.shadcn.com/docs/components/radix/toggle), from
`apps/v4/registry/bases/radix/ui/toggle.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
