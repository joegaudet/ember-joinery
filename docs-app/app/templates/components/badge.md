# Badge

Displays a badge or a component that looks like a badge.

<Example @name="badge-demo" @title="Badge" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Badge } from '@ember-joinery/ember'
```

## Usage

```gts
<Badge @variant="default | outline | secondary | destructive">Badge</Badge>
```

## Variants

Use `@variant` to change the variant of the badge.

<Example @name="badge-variants" @title="Variants" />

## With Icon

You can render an icon inside the badge. Use `data-icon="inline-start"` to render the icon on
the left and `data-icon="inline-end"` to render the icon on the right (on the right and the
left, right to left).

<Example @name="badge-icon" @title="With Icon" />

## With Spinner

You can render a [`<Spinner />`](/components/spinner.md) inside the badge. Remember to add
`data-icon="inline-start"` or `data-icon="inline-end"` to the spinner.

<Example @name="badge-spinner" @title="With Spinner" />

## Link

Upstream's `asChild` renders a link as a badge. In Joinery, put the `asBadge` modifier on your
own link or component, such as `LinkTo`, or give `@as` a tag:

```gts
import { Badge, asBadge } from '@ember-joinery/ember'

<template>
  <a href="#link" {{asBadge}}>Open Link</a>
  <LinkTo @route="inbox" {{asBadge variant="secondary"}}>3 new</LinkTo>
  <Badge @as="a" href="#link">Open Link</Badge>
</template>
```

<Example @name="badge-link" @title="Link" />

## Custom Colors

You can customize the colors of a badge by adding custom classes such as
`bg-green-50 dark:bg-green-800` to the `Badge` component. In a Tailwind app, a utility class
on the badge wins over its style, as here; without Tailwind, set the colours in your own CSS,
which wins too (Joinery's rules are in the `joinery` layer, below your own).

<Example @name="badge-colors" @title="Custom Colors" />

## RTL

Joinery's styles use logical properties, so a badge lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): an icon marked
`data-icon="inline-end"` moves to the left, and the narrower padding moves with it.

<Example @name="badge-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Badge

| Argument   | Type                                                                          | Default     | What it does                                       |
| ---------- | ----------------------------------------------------------------------------- | ----------- | -------------------------------------------------- |
| `@variant` | `"default" \| "secondary" \| "destructive" \| "outline" \| "ghost" \| "link"` | `"default"` | How it looks                                       |
| `@as`      | tag name                                                                      | `span`      | The tag to render (upstream's `asChild`, for tags) |
| `@name`    | `string`                                                                      |             | Its name, for `BadgeHarness` (`data-test-jn-name`) |

It yields nothing but its block, and takes attributes on its element.

### The `asBadge` modifier

`{{asBadge variant=… name=…}}` makes any element or component a badge: it adds the classes and
attributes below, and keeps them current as its arguments change. `badgeClasses(options)` and
`badgeAttributes(options)` return the same, for code of your own.

### Data attributes

| Attribute           | Value                                                    |
| ------------------- | -------------------------------------------------------- |
| `class`             | `jn-badge jn-badge-variant-<variant>`, and `group/badge` |
| `data-slot`         | `badge`                                                  |
| `data-variant`      | its `@variant`                                           |
| `data-test-jn`      | `badge`                                                  |
| `data-test-jn-name` | its `@name`                                              |

An icon or spinner inside takes `data-icon="inline-start"` or `"inline-end"` for its spacing.

## Keyboard interactions

A badge is a `<span>`: it takes no focus and has no keys. A link badge (`@as="a"` with an
`href`, or the modifier on a link) is a link, in the tab order, and `Enter` follows it.

## Accessibility

- A badge is text, read where it stands. Its icons are hidden from assistive technology; give a
  badge that is only an icon a name with `aria-label`.
- Colour alone doesn't carry meaning to everyone: keep the text (`Destructive`, `Verified`)
  that says what the colour means.
- For a count or status that changes while the page is open, put the badge in a live region
  (`role="status"`) of your own.
- Upstream's destructive badge sets `--destructive` on its own 10% tint: about 4:1 in the light
  themes, under the 4.5:1 WCAG AA asks of its 12px text (the dark themes pass). Joinery keeps
  upstream's colours. To meet AA, darken the text in your CSS, which wins over Joinery's:

  ```css
  .jn-badge-variant-destructive:not(.dark *) {
    color: color-mix(in oklab, var(--destructive), black 15%);
  }
  ```

## Testing

`BadgeHarness` from `@ember-joinery/test-support` drives a `<Badge>`, or any element with the
`asBadge` modifier:

```ts
import { BadgeHarness } from '@ember-joinery/test-support'

const status = new BadgeHarness('status') // <Badge @name="status">
assert.strictEqual(status.text, 'Verified')
assert.strictEqual(status.variant, 'secondary')
```

| Member      | What it is                                   |
| ----------- | -------------------------------------------- |
| `text`      | The text it shows                            |
| `variant`   | Its `@variant`                               |
| `isLink`    | Whether it is a link (`<a href>`)            |
| `href`      | Where a link badge goes, or `null`           |
| `isFocused` | Whether it has focus                         |
| `click()`   | Clicks it                                    |
| `focus()`   | Focuses it, as tabbing to a link badge would |
| `blur()`    | Moves focus away                             |

## Upstream

shadcn/ui's [Badge](https://ui.shadcn.com/docs/components/radix/badge), from
`apps/v4/registry/bases/radix/ui/badge.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
