# Pagination

Pagination with page navigation, next and previous links.

<Example @name="pagination-demo" @title="Pagination" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Pagination } from '@ember-joinery/ember'
```

## Usage

```gts
<Pagination as |p|>
  <p.Content>
    <p.Item>
      <p.Previous href="#" />
    </p.Item>
    <p.Item>
      <p.Link href="#">1</p.Link>
    </p.Item>
    <p.Item>
      <p.Link href="#" @isActive={{true}}>
        2
      </p.Link>
    </p.Item>
    <p.Item>
      <p.Link href="#">3</p.Link>
    </p.Item>
    <p.Item>
      <p.Ellipsis />
    </p.Item>
    <p.Item>
      <p.Next href="#" />
    </p.Item>
  </p.Content>
</Pagination>
```

## Composition

Use the following composition to build a `Pagination`:

```text
Pagination
└── p.Content
    ├── p.Item
    │   └── p.Previous
    ├── p.Item
    │   └── p.Link
    ├── p.Item
    │   └── p.Ellipsis
    └── p.Item
        └── p.Next
```

## Simple

A simple pagination with only page numbers.

<Example @name="pagination-simple" @title="Simple" />

## Icons Only

Use just the previous and next buttons without page numbers. This is useful for data tables with
a rows per page selector.

<Example @name="pagination-icons-only" @title="Icons Only" />

## Router links

Upstream's links are `<a>` tags, and its Next.js section edits the component to use Next's
`Link`. Joinery's parts are modifiers too, so a router's link becomes one where you use it:

```gts
<p.Item>
  <LinkTo @route="results" @query={{hash page=2}} {{p.link isActive=true}}>2</LinkTo>
</p.Item>
<p.Item>
  <LinkTo @route="results" @query={{hash page=3}} {{p.next}}>Next</LinkTo>
</p.Item>
```

`p.link` takes `isActive` and `size`; `p.previous` and `p.next` take `size` and `label`, and
leave the arrow and text to you. `<p.Link @as="…">` renders another tag.

## RTL

Joinery's styles use logical properties, so a pagination lays itself out right to left inside
any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): previous is on the
right, and both arrows point the other way. Give the previous and next links' text with
`@text`, and their names with `@label`, in your page's language.

<Example @name="pagination-rtl" @title="RTL" @dir="rtl" />

## Changelog

### RTL Support

Upstream's changelog tells you to add a `text` prop to `PaginationPrevious` and
`PaginationNext`, so a right-to-left page can translate them. Joinery's `p.Previous` and
`p.Next` have had it from the start, as `@text`.

## API Reference

### Pagination

| Argument | Type     | Default        | What it does                                            |
| -------- | -------- | -------------- | ------------------------------------------------------- |
| `@label` | `string` | `"pagination"` | What the navigation is called (`aria-label`)            |
| `@name`  | `string` |                | Its name, for `PaginationHarness` (`data-test-jn-name`) |

It renders a `<nav>` and takes attributes on it. It yields its parts, each a component and a
modifier for an element of your own, and each part takes `@as`, a tag to render instead:

| Part         | Modifier     | Element | What it is                                       |
| ------------ | ------------ | ------- | ------------------------------------------------ |
| `p.Content`  | `p.content`  | `ul`    | The list of links                                |
| `p.Item`     | `p.item`     | `li`    | One link's place in the list                     |
| `p.Link`     | `p.link`     | `a`     | A page's link                                    |
| `p.Previous` | `p.previous` | `a`     | The previous page's link                         |
| `p.Next`     | `p.next`     | `a`     | The next page's link                             |
| `p.Ellipsis` | `p.ellipsis` | `span`  | Pages left out, which assistive technology skips |

### p.Link

| Argument    | Type                                   | Default  | What it does                                                        |
| ----------- | -------------------------------------- | -------- | ------------------------------------------------------------------- |
| `@isActive` | `boolean`                              | `false`  | Whether it is the current page: outlined, and `aria-current="page"` |
| `@size`     | a [Button](/components/button.md) size | `"icon"` | How big it is                                                       |

A page's link looks like a [Button](/components/button.md): ghost, or outline for the current
page. `paginationLinkClasses(kind, options)` and `paginationLinkAttributes(kind, options)`
return what it renders (`kind` is `link`, `previous` or `next`), for code of your own.

### p.Previous and p.Next

| Argument    | Type            | Default                                      | What it does                            |
| ----------- | --------------- | -------------------------------------------- | --------------------------------------- |
| `@text`     | `string`        | `"Previous"`, `"Next"`                       | The text beside the arrow, from `sm` up |
| `@label`    | `string`        | `"Go to previous page"`, `"Go to next page"` | What it is called (`aria-label`)        |
| `@icon`     | a `lucide` icon | `ChevronLeft`, `ChevronRight`                | The arrow, mirrored right to left       |
| `@size`     | a Button size   | `"default"`                                  | How big it is                           |
| `@isActive` | `boolean`       | `false`                                      | As on `p.Link`                          |

Below the `sm` breakpoint (640px), only the arrow shows.

### p.Ellipsis

| Argument | Type            | Default             | What it does                               |
| -------- | --------------- | ------------------- | ------------------------------------------ |
| `@icon`  | a `lucide` icon | lucide's `Ellipsis` | The icon (upstream's `MoreHorizontalIcon`) |
| `@label` | `string`        | `"More pages"`      | Its hidden text                            |

### Data attributes

| Attribute           | On        | Value                                                                                           |
| ------------------- | --------- | ----------------------------------------------------------------------------------------------- |
| `class`             | the root  | `jn-pagination`                                                                                 |
| `class`             | a link    | a Button's classes, `jn-pagination-link`, and `jn-pagination-previous` or `jn-pagination-next`  |
| `data-slot`         | each      | `pagination`, `pagination-content`, `pagination-item`, `pagination-link`, `pagination-ellipsis` |
| `data-active`       | a link    | its `@isActive`, when given                                                                     |
| `data-variant`      | a link    | `ghost`, or `outline` for the current page                                                      |
| `data-size`         | a link    | its `@size`                                                                                     |
| `aria-current`      | a link    | `page`, for the current page                                                                    |
| `data-test-jn`      | the root  | `pagination`                                                                                    |
| `data-test-jn-name` | the root  | its `@name`                                                                                     |
| `data-test-jn-part` | each part | `content`, `item`, `link`, `previous`, `next`, `ellipsis`                                       |

## Keyboard interactions

| Key     | What it does                                              |
| ------- | --------------------------------------------------------- |
| `Tab`   | Moves focus to each link in turn; the ellipsis takes none |
| `Enter` | Follows the focused link                                  |

## Accessibility

- The `nav` is a landmark named `pagination` (give `@label` in your page's language). A page
  with two paginations names each differently.
- The current page's link is marked `aria-current="page"`.
- The previous and next links are named by `@label`, which should contain the text they show
  (WCAG's label in name): the defaults, `Go to previous page` and `Go to next page`, contain
  `Previous` and `Next`.
- The ellipsis is hidden from assistive technology.

## Testing

`PaginationHarness` from `@ember-joinery/test-support` reads the page links and the current
page through `aria-current`:

```ts
import { PaginationHarness } from '@ember-joinery/test-support'

const pages = new PaginationHarness()
assert.deepEqual(pages.pages, ['1', '2', '3'])
assert.strictEqual(pages.current, '2')
await pages.goTo('3')
await pages.goToNext()
```

| Member            | What it is                                    |
| ----------------- | --------------------------------------------- |
| `label`           | Its accessible name, the `nav`'s `aria-label` |
| `pages`           | Each page link's text                         |
| `pageElements`    | The page links                                |
| `current`         | The current page's text, or `null`            |
| `previous`        | The previous page's link                      |
| `next`            | The next page's link                          |
| `hasEllipsis`     | Whether some pages are left out               |
| `page(page)`      | The link to the page whose text is `page`     |
| `isCurrent(page)` | Whether that page is the current one          |
| `goTo(page)`      | Clicks that page's link                       |
| `goToPrevious()`  | Clicks the previous page's link               |
| `goToNext()`      | Clicks the next page's link                   |

## Upstream

shadcn/ui's [Pagination](https://ui.shadcn.com/docs/components/radix/pagination), from
`apps/v4/registry/bases/radix/ui/pagination.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
