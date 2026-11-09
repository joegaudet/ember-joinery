# Spinner

An indicator that can be used to show a loading state.

Upstream's first example shows a spinner in an Item, which hasn't landed in Joinery yet; it
comes with Item. The examples below show a spinner on its own and in a Button.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Spinner } from '@ember-joinery/ember'
```

## Usage

```gts
<Spinner />
```

## Customization

Upstream's Spinner is copied into your app, so you replace its icon by editing it. Joinery's
comes from the package, so give it the icon to turn instead, with `@icon`: any `lucide` icon,
imported one at a time.

<Example @name="spinner-custom" @title="Customization" />

```gts
import { Loader } from 'lucide'
import { Spinner } from '@ember-joinery/ember'

<template><Spinner @icon={{Loader}} /></template>
```

## Size

Use the `size-*` utility class to change the size of the spinner. Without Tailwind, set its
`width` and `height` in your own CSS, which wins over Joinery's (its rules are in the `joinery`
layer).

<Example @name="spinner-size" @title="Size" />

## Button

Add a spinner to a button to indicate a loading state. Place the `<Spinner />` before the label
with `data-icon="inline-start"` for a start position, or after the label with
`data-icon="inline-end"` for an end position.

<Example @name="spinner-button" @title="Button" />

## Badge

Add a spinner to a [badge](/components/badge.md) to indicate a loading state, with
`data-icon="inline-start"` or `data-icon="inline-end"` as in a button. In a badge it is drawn at
the badge's icon size (`size-3`), as upstream's.

<Example @name="spinner-badge" @title="Badge" />

## Input Group

A spinner in an input group's addon. Upstream's example comes with Input Group.

## Empty

A spinner as an [empty state](/components/empty.md)'s media, on its icon tile.

<Example @name="spinner-empty" @title="Empty" />

## RTL

A spinner turns the same way in both directions, and in a Button its `data-icon` side follows
the text (see [Direction](/primitives/direction.md)). Upstream's right-to-left example, a
spinner in an Item, comes with Item.

## API Reference

### Spinner

| Argument | Type            | Default                 | What it does                                         |
| -------- | --------------- | ----------------------- | ---------------------------------------------------- |
| `@icon`  | a `lucide` icon | lucide's `LoaderCircle` | The icon it turns (upstream's `Loader2Icon`)         |
| `@label` | `string`        | `"Loading"`             | What it announces                                    |
| `@name`  | `string`        |                         | Its name, for `SpinnerHarness` (`data-test-jn-name`) |

It renders an `<svg>` (an [Icon](/components/icon.md)) and takes attributes on it, such as
`class` and `data-icon`.

### Data attributes

| Attribute           | Value                         |
| ------------------- | ----------------------------- |
| `class`             | `lucide jn-spinner jn-size-4` |
| `data-slot`         | `spinner`                     |
| `role`              | `status`                      |
| `aria-label`        | its `@label`                  |
| `data-test-jn`      | `spinner`                     |
| `data-test-jn-name` | its `@name`                   |

`jn-size-4` styles nothing: it stands for upstream's `size-4` class, which the style sheets'
rules for icons look for (`svg:not([class*='size-'])`), so a small button's icon size leaves the
spinner at its own, as upstream's.

## Accessibility

- It has the `status` role and an `aria-label`, `Loading` unless you give `@label`, so a screen
  reader announces it. Give the label in your page's language.
- In a button, disable the button while it loads (`disabled`), as the examples do.
- The animation is CSS (`animate-spin`); add your own `prefers-reduced-motion` rule to stop it.

## Testing

`SpinnerHarness` from `@ember-joinery/test-support` finds a spinner (`data-test-jn="spinner"`):

```ts
import { ButtonHarness, SpinnerHarness } from '@ember-joinery/test-support'

const save = new ButtonHarness('save')
assert.strictEqual(save.find(SpinnerHarness).label, 'Loading')
```

| Member  | What it is                                    |
| ------- | --------------------------------------------- |
| `label` | What it announces: `Loading`, or its `@label` |
| `role`  | Its role, `status`                            |

## Upstream

shadcn/ui's [Spinner](https://ui.shadcn.com/docs/components/radix/spinner), from
`apps/v4/registry/bases/radix/ui/spinner.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
