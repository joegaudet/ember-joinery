# Breadcrumb

Displays the path to the current resource using a hierarchy of links.

<Example @name="breadcrumb-demo" @title="Breadcrumb" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Breadcrumb } from '@ember-joinery/ember'
```

## Usage

```gts
<Breadcrumb as |b|>
  <b.List>
    <b.Item>
      <b.Link href="/">Home</b.Link>
    </b.Item>
    <b.Separator />
    <b.Item>
      <b.Link href="/components">Components</b.Link>
    </b.Item>
    <b.Separator />
    <b.Item>
      <b.Page>Breadcrumb</b.Page>
    </b.Item>
  </b.List>
</Breadcrumb>
```

## Composition

Use the following composition to build a `Breadcrumb`:

```text
Breadcrumb
└── b.List
    ├── b.Item
    │   └── b.Link
    ├── b.Separator
    ├── b.Item
    │   └── b.Link
    ├── b.Separator
    └── b.Item
        └── b.Page
```

## Basic

A basic breadcrumb with a home link and a components link.

<Example @name="breadcrumb-basic" @title="Basic" />

## Custom separator

Give `<b.Separator>` a block to show something of your own in place of its chevron, such as
lucide's `Dot`. To swap only the icon, pass it as `@icon`.

<Example @name="breadcrumb-separator" @title="Custom separator" />

## Dropdown

You can compose `<b.Item>` with a [`<DropdownMenu />`](/components/dropdown-menu.md) to create
a dropdown in the breadcrumb.

<Example @name="breadcrumb-dropdown" @title="Dropdown" />

## Collapsed

We provide `<b.Ellipsis>` to show a collapsed state when the breadcrumb is too long.

<Example @name="breadcrumb-ellipsis" @title="Collapsed" />

## Link component

Upstream's `asChild` makes a routing library's link a crumb's link. In Joinery, put the
`b.link` modifier on your own link, or on `LinkTo`; `<b.Link @as="…">` renders another tag.

```gts
<b.Item>
  <LinkTo @route="index" {{b.link}}>Home</LinkTo>
</b.Item>
```

<Example @name="breadcrumb-link" @title="Link component" />

## RTL

Joinery's styles use logical properties, so a breadcrumb lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)), and its chevrons
point left.

<Example @name="breadcrumb-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Breadcrumb

The root navigation element that wraps all breadcrumb parts.

| Argument | Type     | Default        | What it does                                            |
| -------- | -------- | -------------- | ------------------------------------------------------- |
| `@label` | `string` | `"breadcrumb"` | What the navigation is called (`aria-label`)            |
| `@name`  | `string` |                | Its name, for `BreadcrumbHarness` (`data-test-jn-name`) |

It renders a `<nav>` and takes attributes on it. It yields its parts, each a component and a
modifier for an element of your own (`<LinkTo {{b.link}}>`), and each part takes `@as`, a tag
to render instead:

| Part          | Modifier      | Element | What it is                                                    |
| ------------- | ------------- | ------- | ------------------------------------------------------------- |
| `b.List`      | `b.list`      | `ol`    | The ordered list of crumbs                                    |
| `b.Item`      | `b.item`      | `li`    | One crumb                                                     |
| `b.Link`      | `b.link`      | `a`     | A link to a page above this one                               |
| `b.Page`      | `b.page`      | `span`  | The current page, which goes nowhere                          |
| `b.Separator` | `b.separator` | `li`    | A separator between two crumbs, which assistive tech skips    |
| `b.Ellipsis`  | `b.ellipsis`  | `span`  | Crumbs collapsed into an ellipsis, which assistive tech skips |

The modifiers on `Separator` and `Ellipsis` add their classes and ARIA; what they show is
yours.

### b.Separator

| Argument | Type            | Default                 | What it does                                              |
| -------- | --------------- | ----------------------- | --------------------------------------------------------- |
| `@icon`  | a `lucide` icon | lucide's `ChevronRight` | The icon it shows without a block, mirrored right to left |

A block replaces the icon (upstream's `children`).

### b.Ellipsis

| Argument | Type            | Default             | What it does                               |
| -------- | --------------- | ------------------- | ------------------------------------------ |
| `@icon`  | a `lucide` icon | lucide's `Ellipsis` | The icon (upstream's `MoreHorizontalIcon`) |
| `@label` | `string`        | `"More"`            | Its hidden text                            |

### Data attributes

| Attribute           | On                          | Value                                                                                                                                   |
| ------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `class`             | the root                    | `jn-breadcrumb`                                                                                                                         |
| `class`             | each part                   | `jn-<data-slot>`, as `jn-breadcrumb-link`                                                                                               |
| `data-slot`         | each                        | `breadcrumb`, `breadcrumb-list`, `breadcrumb-item`, `breadcrumb-link`, `breadcrumb-page`, `breadcrumb-separator`, `breadcrumb-ellipsis` |
| `aria-current`      | `b.Page`                    | `page`, with `role="link"` and `aria-disabled="true"`                                                                                   |
| `role`              | `b.Separator`, `b.Ellipsis` | `presentation`, with `aria-hidden="true"`                                                                                               |
| `data-test-jn`      | the root                    | `breadcrumb`                                                                                                                            |
| `data-test-jn-name` | the root                    | its `@name`                                                                                                                             |
| `data-test-jn-part` | each part                   | `list`, `item`, `link`, `page`, `separator`, `ellipsis`                                                                                 |

## Keyboard interactions

| Key   | What it does                                                            |
| ----- | ----------------------------------------------------------------------- |
| `Tab` | Moves focus to each link in turn; the page and the separators take none |

That is the [APG breadcrumb pattern](https://www.w3.org/WAI/ARIA/apg/patterns/breadcrumb/): its
links are native links, which activate on `Enter`.

## Accessibility

- The `nav` is a landmark named `breadcrumb` (give `@label` in your page's language), so a
  screen reader user can jump to it. A page with two breadcrumbs names each differently.
- The current page is marked `aria-current="page"`, as the APG pattern asks.
- The separators and the ellipsis are hidden from assistive technology, so a screen reader reads
  only the crumbs.

## Testing

`BreadcrumbHarness` from `@ember-joinery/test-support` reads a breadcrumb as a screen reader
does, through its list's items and `aria-current`:

```ts
import { BreadcrumbHarness } from '@ember-joinery/test-support'

const path = new BreadcrumbHarness()
assert.deepEqual(path.items, ['Home', 'Components', 'Breadcrumb'])
assert.strictEqual(path.current, 'Breadcrumb')
await path.clickLink('Components')
```

| Member            | What it is                                         |
| ----------------- | -------------------------------------------------- |
| `label`           | Its accessible name, the `nav`'s `aria-label`      |
| `list`            | Its list                                           |
| `items`           | Each crumb's text; a collapsed crumb reads as `''` |
| `itemElements`    | Each crumb's `li`                                  |
| `links`           | Each link's text                                   |
| `current`         | The current page's text, or `null`                 |
| `separators`      | The separators                                     |
| `isCollapsed`     | Whether some crumbs are collapsed into an ellipsis |
| `link(name)`      | The link whose text is `name`                      |
| `clickLink(name)` | Clicks it                                          |

It drives the headless [Breadcrumb](/primitives/breadcrumb.md) too.

## Upstream

shadcn/ui's [Breadcrumb](https://ui.shadcn.com/docs/components/radix/breadcrumb), from
`apps/v4/registry/bases/radix/ui/breadcrumb.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
and ember-primitives' `Breadcrumb` (0.64.2).
