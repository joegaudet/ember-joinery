# Item

A versatile component for displaying content with media, title, description, and actions.

<Example @name="item-demo" @title="Item" />

The `Item` component is a straightforward flex container that can house nearly any type of
content. Use it to display a title, description, and actions. Group it with the `ItemGroup`
component to create a list of items.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Item, ItemGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<Item as |i|>
  <i.Media @variant="icon">
    <Icon @icon={{Inbox}} />
  </i.Media>
  <i.Content>
    <i.Title>Title</i.Title>
    <i.Description>Description</i.Description>
  </i.Content>
  <i.Actions>
    <Button>Action</Button>
  </i.Actions>
</Item>
```

## Composition

Use the following composition to build an `Item`:

```text
ItemGroup
└── Item
    ├── i.Header
    ├── i.Media
    ├── i.Content
    │   ├── i.Title
    │   └── i.Description
    ├── i.Actions
    └── i.Footer
```

## Item vs Field

Use `Field` if you need to display a form input such as a checkbox, input, radio, or select.

If you only need to display content such as a title, description, and actions, use `Item`.

## Variant

Use `@variant` to change the visual style of the item.

<Example @name="item-variant" @title="Variant" />

## Size

Use `@size` to change the size of the item. Available sizes are `default`, `sm`, and `xs`.

<Example @name="item-size" @title="Size" />

## Icon

Use the `Media` part with `@variant="icon"` to display an icon.

<Example @name="item-icon" @title="Icon" />

## Avatar

You can use the `Media` part to display an [avatar](/components/avatar.md).

<Example @name="item-avatar" @title="Avatar" />

## Image

Use the `Media` part with `@variant="image"` to display an image.

<Example @name="item-image" @title="Image" />

## Group

Use `ItemGroup` to group related items together. It is a list, so give each item
`role="listitem"`; upstream's group example leaves it off, and Joinery's adds it, so it passes
the accessibility audit every example runs.

<Example @name="item-group" @title="Group" />

## Header

Use the `Header` part to add a header above the item content.

<Example @name="item-header" @title="Header" />

## Link

Upstream's `asChild` renders the item as a link. In Joinery, give `@as` a tag, or put the
`asItem` modifier on your own element or component, such as `LinkTo`. The hover and focus
states will be applied to the anchor element.

<Example @name="item-link" @title="Link" />

```gts
<Item @as="a" href="/dashboard" as |i|>
  <i.Media @variant="icon">
    <Icon @icon={{House}} />
  </i.Media>
  <i.Content>
    <i.Title>Dashboard</i.Title>
    <i.Description>Overview of your account and activity.</i.Description>
  </i.Content>
</Item>
```

With `asItem`, the parts aren't yielded, so use the ones the module exports, the same
components:

```gts
import { ItemContent, ItemDescription, ItemTitle, asItem } from '@ember-joinery/ember'

<template>
  <LinkTo @route="dashboard" {{asItem variant="outline"}}>
    <ItemContent>
      <ItemTitle>Dashboard</ItemTitle>
      <ItemDescription>Overview of your account and activity.</ItemDescription>
    </ItemContent>
  </LinkTo>
</template>
```

## Dropdown

<Example @name="item-dropdown" @title="Dropdown" />

Each [Dropdown Menu](/components/dropdown-menu.md) item holds an `Item`, so the menu's arrow
keys and typeahead move between the people, and each item's text is its username and email.

## RTL

Joinery's styles use logical properties, so an item lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the media moves to the
right, the actions to the left, and the description starts on the right.

<Example @name="item-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Item

The main component for displaying content with media, title, description, and actions.

| Argument   | Type                                | Default     | What it does                                       |
| ---------- | ----------------------------------- | ----------- | -------------------------------------------------- |
| `@variant` | `"default" \| "outline" \| "muted"` | `"default"` | How it looks                                       |
| `@size`    | `"default" \| "sm" \| "xs"`         | `"default"` | How roomy it is                                    |
| `@as`      | tag name                            | `div`       | The tag to render (upstream's `asChild`, for tags) |
| `@name`    | `string`                            |             | Its name, for `ItemHarness` (`data-test-jn-name`)  |

It yields its parts, each as a component (`i.Title`) and as a modifier for your own element
(`<LinkTo {{i.title}}>`): `Media`, `Content`, `Title`, `Description`, `Actions`, `Header` and
`Footer`. The module exports the same components as `ItemMedia`, `ItemContent`, `ItemTitle`,
`ItemDescription`, `ItemActions`, `ItemHeader` and `ItemFooter`, for use inside `asItem`. Each
takes `@as`, and attributes.

### The `asItem` modifier

`{{asItem variant=… size=… name=…}}` makes any element or component an item: it adds the
classes and attributes below, and keeps them current as its arguments change.
`itemClasses(options)` and `itemAttributes(options)` return the same, for code of your own.

### ItemGroup

A container that groups related items together with consistent styling: a list (`role="list"`),
which yields `Separator`, a line between items, and its modifier, `separator`. It takes `@as`
and `@name`, for `ItemGroupHarness`. The module exports the separator too, as `ItemSeparator`.

```gts
<ItemGroup as |g|>
  <Item role="listitem" as |i|>…</Item>
  <g.Separator />
  <Item role="listitem" as |i|>…</Item>
</ItemGroup>
```

### Separator

A separator between items in a group (`g.Separator`, or `ItemSeparator`): upstream's
Separator, decorative (`role="none"` and `aria-hidden="true"`, from the primitives'
[`separatorAria()`](/primitives/separator.md)).

| Argument       | Type                         | Default        | What it does                                          |
| -------------- | ---------------------------- | -------------- | ----------------------------------------------------- |
| `@orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | Which way it runs                                     |
| `@decorative`  | `boolean`                    | `true`         | `false` gives it the `separator` role, outside a list |
| `@as`          | tag name                     | `div`          | The tag to render (an `<hr>` needs no `role`)         |

A list holds only its items, so keep a group's separators decorative unless you give the group
another role.

### Media

Use the `Media` part to display media content such as icons, images, or avatars. Beside a
description, it aligns with the title.

| Argument   | Type                             | Default     | What it does                                    |
| ---------- | -------------------------------- | ----------- | ----------------------------------------------- |
| `@variant` | `"default" \| "icon" \| "image"` | `"default"` | `icon` sizes an icon; `image` crops to a square |

```gts
<i.Media @variant="icon">
  <Icon @icon={{Inbox}} />
</i.Media>
```

```gts
<i.Media @variant="image">
  <img src="…" alt="…" />
</i.Media>
```

### Content

Wraps the title and description of the item. A second `Content` after it keeps to its own
width, as the duration does in the image example.

### Title

Displays the title of the item, on one line.

### Description

Displays the description of the item: a `<p>`, muted, on up to two lines. A link in it is
underlined.

### Actions

Container for action buttons or other interactive elements.

### Header

Displays a header above the item content, the item's full width.

### Footer

Displays a footer below the item content, the item's full width.

### Data attributes

| Part        | `class`                                                               | `data-slot`        | `data-test-jn-part`           |
| ----------- | --------------------------------------------------------------------- | ------------------ | ----------------------------- |
| Item        | `jn-item jn-item-variant-<variant> jn-item-size-<size>`, `group/item` | `item`             | (`data-test-jn="item"`)       |
| Media       | `jn-item-media jn-item-media-variant-<variant>`                       | `item-media`       | `media`                       |
| Content     | `jn-item-content`                                                     | `item-content`     | `content`                     |
| Title       | `jn-item-title`                                                       | `item-title`       | `title`                       |
| Description | `jn-item-description`                                                 | `item-description` | `description`                 |
| Actions     | `jn-item-actions`                                                     | `item-actions`     | `actions`                     |
| Header      | `jn-item-header`                                                      | `item-header`      | `header`                      |
| Footer      | `jn-item-footer`                                                      | `item-footer`      | `footer`                      |
| ItemGroup   | `jn-item-group`, `group/item-group`                                   | `item-group`       | (`data-test-jn="item-group"`) |
| Separator   | `jn-item-separator`                                                   | `item-separator`   | `separator`                   |

The item also has `data-variant` and `data-size`, the media `data-variant`, and the separator
`data-orientation`, with `role="none"` and `aria-hidden="true"` (or with `@decorative={{false}}`,
the `separator` role, and `aria-orientation="vertical"` when it is vertical).

## Keyboard interactions

An item isn't focusable; the controls inside it are, in the tab order. An item that is a link
(`@as="a"`, or `asItem` on a `LinkTo`) is in the tab order itself, and `Enter` follows it, as a
link does. It shows a focus ring when focused from the keyboard.

## Accessibility

- In an `ItemGroup`, which is a list, give each item `role="listitem"`.
- Give an image in the media `alt`, and an icon-only button in the actions `aria-label`.
- An item that is a link is read with all its text as the link's name; keep that text short, or
  name the link with `aria-label`.

## Testing

`ItemHarness` from `@ember-joinery/test-support` drives an `<Item>`, or any element with
`asItem`, and `ItemGroupHarness` an `<ItemGroup>`:

```ts
import { ButtonHarness, ItemHarness } from '@ember-joinery/test-support'

const alert = new ItemHarness('security') // <Item @name="security">
assert.strictEqual(alert.title, 'Security Alert')
await alert.find(ButtonHarness).click()
```

| `ItemHarness`                                     | What it is                                      |
| ------------------------------------------------- | ----------------------------------------------- |
| `text`                                            | All the text it shows                           |
| `title`                                           | Its title's text                                |
| `description`                                     | Its first description's text                    |
| `descriptions`                                    | Every description's text, in order              |
| `variant`                                         | Its `@variant`                                  |
| `size`                                            | Its `@size`                                     |
| `mediaVariant`                                    | The media's `@variant`, or `null` without media |
| `media`, `content`, `actions`, `header`, `footer` | Each part; throws without it                    |
| `isLink`                                          | Whether it is an `<a href>`                     |
| `href`                                            | Where it links to, or `null`                    |
| `isFocused`                                       | Whether it has focus                            |
| `click()`                                         | Clicks it                                       |
| `focus()`                                         | Focuses it                                      |

| `ItemGroupHarness` | What it is                               |
| ------------------ | ---------------------------------------- |
| `items`            | An `ItemHarness` for each item, in order |
| `separators`       | Its separators, in order                 |

## Upstream

shadcn/ui's [Item](https://ui.shadcn.com/docs/components/radix/item), from
`apps/v4/registry/bases/radix/ui/item.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
