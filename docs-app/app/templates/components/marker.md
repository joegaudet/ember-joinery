# Marker

Displays an inline status, system note, bordered row, or labeled separator in a conversation.

<Example @name="marker-demo" @title="Marker" />

The `Marker` component displays inline conversation markers such as status updates, system
notes, bordered rows, and labeled separators. Compose it with
[`Message`](/components/message.md) in a conversation thread.

ui.shadcn.com shows these examples in the Rhea style; pick Rhea in an example's style switcher to
see them as there.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Marker } from '@ember-joinery/ember'
```

## Usage

```gts
<Marker as |m|>
  <m.Icon>
    <Icon @icon={{Check}} />
  </m.Icon>
  <m.Content>Explored 4 files</m.Content>
</Marker>
```

## Composition

Use the following composition to build a marker:

```text
Marker
├── m.Icon
└── m.Content
```

## Features

- Inline marker, bordered row, and labeled separator variants
- Decorative icon slot that is hidden from assistive tech
- A link or button marker, through `@as` or the `asMarker` modifier
- Pairs with shadcn's `shimmer` utility for streaming status text
- Customizable styling through `class` on every part

## Variants

Use `@variant` to switch between an inline marker, bordered row, and labeled separator.

<Example @name="marker-variants" @title="Variants" />

| `@variant`  | Description                                          |
| ----------- | ---------------------------------------------------- |
| `default`   | An inline marker for status, notes, and actions.     |
| `border`    | A default marker with a bottom border under the row. |
| `separator` | A centered label with divider lines on each side.    |

## Status

Set `role="status"` and include a [`Spinner`](/components/spinner.md) for streaming or
in-progress markers so updates are announced.

<Example @name="marker-status" @title="Status" />

## Shimmer

Add shadcn's `shimmer` utility class to the `Content` part for an animated streaming-text effect.
It ships with the `shadcn` package's `tailwind.css`, which a Tailwind app imports; the guide
compiles it for its examples. Under `prefers-reduced-motion`, the text stays still.

<Example @name="marker-shimmer" @title="Shimmer" />

## Separator

Use the `separator` variant for labeled dividers, such as dates or section breaks, in a
conversation. Upstream's Checkpoint, in its AI Elements, is a separator with a button that
restores the thread to that point.

<Example @name="marker-separator" @title="Separator" />

## Border

Use the `border` variant for status rows that should keep the default marker alignment while
separating the next row.

<Example @name="marker-border" @title="Border" />

## With Icon

Use the `Icon` part to render an icon alongside the content. Use `flex-col` to stack the icon
above the content.

<Example @name="marker-icon" @title="With Icon" />

## Links and Buttons

Upstream's `asChild` on `Marker` turns a marker into a link or button. In Joinery, give it `@as`,
or put the `asMarker` modifier on your own element or component, such as `LinkTo`.

<Example @name="marker-link-button" @title="Links and Buttons" />

```gts
<Marker @as="a" href="#" as |m|>
  <m.Content>View the pull request</m.Content>
</Marker>
```

With `asMarker`, the parts aren't yielded, so use the ones the module exports, the same
components:

```gts
import { MarkerContent, asMarker } from '@ember-joinery/ember'

<template>
  <LinkTo @route="pull" {{asMarker}}>
    <MarkerContent>View the pull request</MarkerContent>
  </LinkTo>
</template>
```

## API Reference

### Marker

The root marker element.

| Argument   | Type                                   | Default     | What it does                                        |
| ---------- | -------------------------------------- | ----------- | --------------------------------------------------- |
| `@variant` | `"default" \| "border" \| "separator"` | `"default"` | The marker layout                                   |
| `@as`      | tag name                               | `div`       | The tag to render (upstream's `asChild`, for tags)  |
| `@name`    | `string`                               |             | Its name, for `MarkerHarness` (`data-test-jn-name`) |

It yields its parts, each as a component (`m.Icon`) and as a modifier for your own element
(`<i {{m.icon}}>`): `Icon` and `Content`. The module exports the same components as `MarkerIcon`
and `MarkerContent`, for use inside `asMarker`. Each takes `@as`, and attributes.

### The `asMarker` modifier

`{{asMarker variant=… name=…}}` makes any element or component a marker: it adds the classes and
attributes below, and keeps them current as its arguments change. `markerClasses(options)` and
`markerAttributes(options)` return the same, for composing the marker styles into components of
your own (upstream's `markerVariants`).

### Icon

A decorative icon slot, a `span` hidden from assistive tech with `aria-hidden`. An icon in it is
16px unless it has a size of its own.

### Content

The marker text content, a `span`. In a separator, it sits centred between the lines.

### Data attributes

| Part    | `class`                                                 | `data-slot`      | `data-test-jn-part`       |
| ------- | ------------------------------------------------------- | ---------------- | ------------------------- |
| Marker  | `jn-marker jn-marker-variant-<variant>`, `group/marker` | `marker`         | (`data-test-jn="marker"`) |
| Icon    | `jn-marker-icon`                                        | `marker-icon`    | `icon`                    |
| Content | `jn-marker-content`                                     | `marker-content` | `content`                 |

The marker also has `data-variant`, and the icon `aria-hidden="true"`.

## Keyboard interactions

A marker isn't focusable. One that is a link or a button (`@as="a"`, `@as="button"`, or
`asMarker` on a `LinkTo`) is in the tab order: `Enter` follows a link, and `Enter` and `Space`
press a button, as native elements do.

## Accessibility

`Marker` is presentational by default. The correct semantics depend on how you use it, so choose
the role based on intent rather than relying on a single default.

### Status and Progress

For streaming or progress markers such as "Thinking..." or a running tool, set `role="status"`
so assistive tech announces the update as it appears. `Marker` passes `role` to its element.

```gts
<Marker role="status" as |m|>
  <m.Icon>
    <Spinner />
  </m.Icon>
  <m.Content>Compacting conversation</m.Content>
</Marker>
```

### Labeled Separators

A separator that carries text, such as a date or a section label, needs no role. The divider
lines are decorative CSS pseudo-elements, and the text is announced as ordinary content.

```gts
<Marker @variant="separator" as |m|>
  <m.Content>Today</m.Content>
</Marker>
```

**Note:** Do not add `role="separator"` to a labeled divider. A separator takes its accessible
name from `aria-label`, not from its text, and its contents are treated as presentational, so
the visible label would not be announced. Reserve `role="separator"` for a divider with no
meaningful text.

### Bordered Markers

A bordered marker keeps the same semantics as the default marker. The bottom border is
decorative, so choose `role="status"`, `@as`, or no role based on the marker's purpose.

```gts
<Marker @variant="border" as |m|>
  <m.Icon>
    <Icon @icon={{FileText}} />
  </m.Icon>
  <m.Content>Opened implementation notes</m.Content>
</Marker>
```

### Decorative Icons

The `Icon` part is decorative and hidden from assistive tech with `aria-hidden`, so the adjacent
`Content` carries the meaning. For an icon-only marker, provide an `aria-label` or visible text
so it is not announced as empty. A `div` without a role can't be named, so give an icon-only
marker one that can, such as `img` (or `status`, for a marker that reports progress); upstream's
own snippet leaves the role off.

```gts
<Marker role="img" aria-label="Synced" as |m|>
  <m.Icon>
    <Icon @icon={{Check}} />
  </m.Icon>
</Marker>
```

### Interactive Markers

When a marker links or triggers an action, render it as a real `<button>` or `<a>` (`@as`, or
`asMarker`) so it is focusable and exposes the correct role. The accessible name comes from the
marker text.

```gts
<Marker @as="a" href="/files" as |m|>
  <m.Icon>
    <Icon @icon={{FileText}} />
  </m.Icon>
  <m.Content>Explored 4 files</m.Content>
</Marker>
```

## Testing

`MarkerHarness` from `@ember-joinery/test-support` drives a `<Marker>`, or any element with
`asMarker`:

```ts
import { MarkerHarness } from '@ember-joinery/test-support'

const thinking = new MarkerHarness('thinking') // <Marker @name="thinking" role="status">
assert.true(thinking.isStatus)
assert.strictEqual(thinking.text, 'Thinking...')
```

| `MarkerHarness`      | What it is                                     |
| -------------------- | ---------------------------------------------- |
| `text`               | All the text it shows                          |
| `label`              | Its `aria-label`, else its text                |
| `variant`            | Its `@variant`                                 |
| `role`               | The role it was given, or `null`               |
| `isStatus`           | Whether it has `role="status"`                 |
| `icon`, `content`    | Each part; throws without it                   |
| `hasIcon`            | Whether it has an icon                         |
| `isLink`, `href`     | Whether it is an `<a href>`, and where it goes |
| `isButton`           | Whether it is a `<button>`                     |
| `isFocused`          | Whether it has focus                           |
| `click()`, `focus()` | Clicks it, and focuses it                      |

## Upstream

shadcn/ui's [Marker](https://ui.shadcn.com/docs/components/radix/marker), from
`apps/v4/registry/bases/radix/ui/marker.tsx` at shadcn-ui/ui@8ab2771, shown in the Rhea style.
