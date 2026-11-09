# Button

Displays a button or a component that looks like a button.

<Example @name="button-demo" @title="Button" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Button } from '@ember-joinery/ember'
```

## Usage

```gts
<Button @variant="outline">Button</Button>
```

It renders a native `<button>`, so `type`, `disabled`, `aria-*` and listeners go on it as
attributes:

```gts
import { on } from '@ember/modifier'

<template>
  <Button @variant="outline" type="submit" {{on "click" this.save}}>Save</Button>
</template>
```

Like upstream's and the native element, it doesn't set `type`: in a form, it submits.

## Cursor

Tailwind v4 [switched](https://tailwindcss.com/docs/upgrade-guide#buttons-use-the-default-cursor)
from `cursor: pointer` to `cursor: default` for buttons, and shadcn's styles, Joinery's
included, follow it. To keep the pointer, add this to your CSS:

```css
button:not(:disabled),
[role='button']:not(:disabled) {
  cursor: pointer;
}
```

## Size

Use `@size` to change the size of the button.

<Example @name="button-size" @title="Size" @align="start" />

## Default

<Example @name="button-default" @title="Default" />

## Outline

<Example @name="button-outline" @title="Outline" />

## Secondary

<Example @name="button-secondary" @title="Secondary" />

## Ghost

<Example @name="button-ghost" @title="Ghost" />

## Destructive

<Example @name="button-destructive" @title="Destructive" />

## Link

<Example @name="button-link" @title="Link" />

## Icon

<Example @name="button-icon" @title="Icon" />

An icon-only button needs a name: give it `aria-label`. Upstream's example has none; Joinery's
adds one, so it passes the accessibility audit every example runs.

## With Icon

Remember to add `data-icon="inline-start"` or `data-icon="inline-end"` to the icon for the
correct spacing.

<Example @name="button-with-icon" @title="With Icon" />

## Rounded

Use the `rounded-full` class to make the button rounded. In a Tailwind app, a utility class on
the button wins over its style, as here; without Tailwind, set `border-radius` in your own CSS,
which wins too (Joinery's rules are in the `joinery` layer, below your own).

<Example @name="button-rounded" @title="Rounded" />

## Spinner

Render a `<Spinner />` inside the button to show a loading state. Remember to add
`data-icon="inline-start"` or `data-icon="inline-end"` to the spinner for the correct spacing.

<Example @name="button-spinner" @title="Spinner" />

## Button Group

To create a button group, use the `ButtonGroup` component. See the
[Button Group](/components/button-group.md) documentation for more details.

## As Child

Upstream's `asChild` makes another component look like a button. In Joinery, give `@as` a tag,
or put the `button` modifier on your own element or component, such as `LinkTo`:

```gts
import { Button, button } from '@ember-joinery/ember'

<template>
  <Button @as="a" href="/login">Login</Button>
  <LinkTo @route="login" {{button}}>Login</LinkTo>
  <LinkTo @route="docs" {{button variant="outline" size="sm"}}>Docs</LinkTo>
</template>
```

The modifier takes the same `variant`, `size` and `name` as the component, and keeps the
element's own classes and attributes. Here's a link that looks like a button:

<Example @name="button-aschild" @title="As Child" />

## RTL

Joinery's styles use logical properties, so a button lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)). An icon marked
`data-icon="inline-end"` moves to the left, and the narrower padding moves with it. Mirror an
arrow with `rtl:rotate-180` in a Tailwind app, or your own `[dir="rtl"]` rule.

<Example @name="button-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Button

| Argument   | Type                                                                                 | Default     | What it does                                        |
| ---------- | ------------------------------------------------------------------------------------ | ----------- | --------------------------------------------------- |
| `@variant` | `"default" \| "outline" \| "ghost" \| "destructive" \| "secondary" \| "link"`        | `"default"` | How it looks                                        |
| `@size`    | `"default" \| "xs" \| "sm" \| "lg" \| "icon" \| "icon-xs" \| "icon-sm" \| "icon-lg"` | `"default"` | How big it is; the `icon` sizes are square          |
| `@as`      | tag name                                                                             | `button`    | The tag to render (upstream's `asChild`, for tags)  |
| `@name`    | `string`                                                                             |             | Its name, for `ButtonHarness` (`data-test-jn-name`) |

It yields nothing but its block, and takes attributes on its element.

### The `button` modifier

`{{button variant=… size=… name=…}}` makes any element or component a button: it adds the
classes and attributes below, and keeps them current as its arguments change.
`buttonClasses(options)` and `buttonAttributes(options)` return the same, for code of your own.

### Data attributes

| Attribute           | Value                                                                             |
| ------------------- | --------------------------------------------------------------------------------- |
| `class`             | `jn-button jn-button-variant-<variant> jn-button-size-<size>`, and `group/button` |
| `data-slot`         | `button`                                                                          |
| `data-variant`      | its `@variant`                                                                    |
| `data-size`         | its `@size`                                                                       |
| `data-test-jn`      | `button`                                                                          |
| `data-test-jn-name` | its `@name`                                                                       |

An icon inside takes `data-icon="inline-start"` or `"inline-end"` for its spacing.

## Keyboard interactions

| Key              | What it does                           |
| ---------------- | -------------------------------------- |
| `Tab`            | Moves focus to the button, and past it |
| `Enter`, `Space` | Activates the button                   |

That is the [APG button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/), which a
native `<button>` has built in. With `@as` or the modifier on another element, choose one that
keeps it: a link (`<a href>`) activates on `Enter`, as links do. A disabled `<button>` leaves
the tab order.

## Accessibility

- An icon-only button needs `aria-label` (or `aria-labelledby`). Its `<Icon>` is hidden from
  assistive technology.
- `disabled` on a `<button>` disables it. On a link, use `aria-disabled="true"` and stop the
  navigation yourself; `ButtonHarness#isDisabled` reads either.
- A toggle button takes `aria-pressed`, which the harness reads as `isPressed`.

## Testing

`ButtonHarness` from `@ember-joinery/test-support` drives a `<Button>`, or any element with the
`button` modifier:

```ts
import { ButtonHarness } from '@ember-joinery/test-support'

const save = new ButtonHarness('save') // <Button @name="save">
await save.click()
assert.strictEqual(save.label, 'Save')
```

| Member       | What it is                                                                      |
| ------------ | ------------------------------------------------------------------------------- |
| `text`       | The text it shows                                                               |
| `label`      | Its accessible name: `aria-label`, else `aria-labelledby`'s text, else its text |
| `variant`    | Its `@variant`                                                                  |
| `size`       | Its `@size`                                                                     |
| `isDisabled` | `disabled`, or `aria-disabled="true"`                                           |
| `isPressed`  | `aria-pressed`, or `undefined` for a button that isn't a toggle                 |
| `isFocused`  | Whether it has focus                                                            |
| `click()`    | Clicks it                                                                       |
| `focus()`    | Focuses it, as tabbing to it would                                              |
| `blur()`     | Moves focus away                                                                |

## Upstream

shadcn/ui's [Button](https://ui.shadcn.com/docs/components/radix/button), from
`apps/v4/registry/bases/radix/ui/button.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
