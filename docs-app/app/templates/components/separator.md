# Separator

Visually or semantically separates content.

<Example @name="separator-demo" @title="Separator" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Separator } from '@ember-joinery/ember'
```

## Usage

```gts
<Separator />
```

Like upstream's, it is decorative unless you say otherwise: assistive technology skips it. For
a separator a screen reader should announce, between sections of a menu, say, pass
`@decorative={{false}}`.

## Vertical

Use `@orientation="vertical"` for a vertical separator. It is as tall as its row.

<Example @name="separator-vertical" @title="Vertical" />

## Menu

Vertical separators between menu items with descriptions.

<Example @name="separator-menu" @title="Menu" />

## List

Horizontal separators between list items.

<Example @name="separator-list" @title="List" />

## RTL

A separator is the same in both directions; the content around it lays itself out right to
left inside any element with `dir="rtl"` (see [Direction](/primitives/direction.md)).

<Example @name="separator-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Separator

| Argument       | Type                         | Default        | What it does                                           |
| -------------- | ---------------------------- | -------------- | ------------------------------------------------------ |
| `@orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | Which way it runs                                      |
| `@decorative`  | `boolean`                    | `true`         | Whether assistive technology skips it                  |
| `@as`          | tag name                     | `div`          | The tag to render, such as `li` in a list              |
| `@name`        | `string`                     |                | Its name, for `SeparatorHarness` (`data-test-jn-name`) |

It takes attributes, and a decorative one yields its block (upstream's shows nothing). It is
the primitives' [`Separator`](/primitives/separator.md) with Joinery's styles, as upstream's is
Radix's.

### The `asSeparator` modifier

`{{asSeparator orientation=… decorative=… name=…}}` makes any element or component a separator,
as upstream's `asChild` does: the class, ARIA and attributes below, kept current.
`separatorClasses()` and `separatorAttributes(options)` return them, for code of your own.

### Data attributes

| Attribute           | Value                                                      |
| ------------------- | ---------------------------------------------------------- |
| `class`             | `jn-separator`                                             |
| `data-slot`         | `separator`                                                |
| `data-orientation`  | `horizontal` or `vertical`                                 |
| `role`              | `none` when decorative, `separator` when not               |
| `aria-hidden`       | `true` when decorative                                     |
| `aria-orientation`  | `vertical`, for a vertical separator that isn't decorative |
| `data-test-jn`      | `separator`                                                |
| `data-test-jn-name` | its `@name`                                                |

Upstream's Separator has no semantic class of its own, so `jn-separator` carries its inline
utilities (`shrink-0 bg-border data-horizontal:h-px …`).

## Keyboard interactions

A separator takes no focus and has no keys. (A separator you drag, between resizable panels,
is the splitter in Resizable.)

## Accessibility

- A decorative separator (the default) has `role="none"`, as Radix's, and `aria-hidden`, as
  ember-primitives', so it isn't read.
- One that isn't decorative has the `separator` role, and `aria-orientation="vertical"` when it
  is vertical.
- Use a decorative one where the content on either side already says it is separate: headings,
  list items, menu groups with their own labels.

## Testing

`SeparatorHarness` from `@ember-joinery/test-support` finds a separator
(`data-test-jn="separator"`), styled or headless:

```ts
import { SeparatorHarness } from '@ember-joinery/test-support'

const [first] = SeparatorHarness.findAll()
assert.strictEqual(first.orientation, 'vertical')
assert.true(first.isDecorative)
```

| Member         | What it is                                                                    |
| -------------- | ----------------------------------------------------------------------------- |
| `orientation`  | `horizontal` or `vertical`, from its `aria-orientation` or `data-orientation` |
| `isDecorative` | Whether assistive technology skips it (`role="none"` or `aria-hidden="true"`) |
| `role`         | Its role: `separator` (an `<hr>`'s own, or `role`), or `none`                 |

## Upstream

shadcn/ui's [Separator](https://ui.shadcn.com/docs/components/radix/separator), from
`apps/v4/registry/bases/radix/ui/separator.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's `Separator`.
