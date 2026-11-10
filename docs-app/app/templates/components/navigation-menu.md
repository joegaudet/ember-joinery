# Navigation Menu

A collection of links for navigating websites.

<Example @name="navigation-menu-demo" @title="Navigation Menu" @previewClass="h-96" @overflow="visible" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { NavigationMenu } from '@ember-joinery/ember'
```

## Usage

`<NavigationMenu>` yields its parts, and an item yields its trigger and content:

```gts
import { NavigationMenu } from '@ember-joinery/ember'

<template>
  <NavigationMenu as |n|>
    <n.List>
      <n.Item as |item|>
        <item.Trigger>Item One</item.Trigger>
        <item.Content>
          <n.Link href="/docs">Link</n.Link>
        </item.Content>
      </n.Item>
    </n.List>
  </NavigationMenu>
</template>
```

A trigger opens its content on a click, or when the pointer rests on it for a moment (at once
when another has just been open), and the content closes when the pointer has left both. The
contents show in one viewport below the list, which takes the open one's size and animates as
one content gives way to another, sliding in from the side of the trigger it replaces;
`@viewport={{false}}` puts each content below its own trigger instead. Which content is open is
`@value` (its item's `@value`, or `''` for none), its own or yours with `@onValueChange`.

## Composition

Use the following composition to build a `NavigationMenu`:

```text
NavigationMenu (as |n|)
├── n.List
│   ├── n.Item (as |item|)
│   │   ├── item.Trigger
│   │   └── item.Content
│   │       ├── n.Link
│   │       └── n.Link
│   └── n.Item
│       └── n.Link
├── n.Indicator
└── n.Viewport (with @viewport={{false}})
```

## Link Component

Upstream composes a custom link component, such as Next.js's `Link`, with `asChild`. In Ember,
`n.Link` is an `<a>` already (give it `href`), and `{{n.link}}` makes your own element a link,
such as `LinkTo`. `navigationMenuTriggerStyle()` gives one the trigger's look:

```gts
import { LinkTo } from '@ember/routing'
import { NavigationMenu, navigationMenuTriggerStyle } from '@ember-joinery/ember'

<template>
  <NavigationMenu as |n|>
    <n.List>
      <n.Item>
        <LinkTo @route="docs" class={{(navigationMenuTriggerStyle)}} {{n.link}}>
          Documentation
        </LinkTo>
      </n.Item>
    </n.List>
  </NavigationMenu>
</template>
```

Upstream merges the two looks with tailwind-merge, so where they conflict the trigger's wins:
its padding over the link's (in Nova, 10px by 6px rather than 8px all round). Joinery's styles
do the same for an element with both classes.

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): right to left, ArrowLeft moves to the next trigger or
link, the viewport starts at the right, and the contents slide in from the side their triggers
are on.

<Example @name="navigation-menu-rtl" @title="RTL" @dir="rtl" @previewClass="h-96" @overflow="visible" />

## API Reference

### NavigationMenu

| Argument             | Type                         | Default      | What it does                                                       |
| -------------------- | ---------------------------- | ------------ | ------------------------------------------------------------------ |
| `@value`             | `string`                     |              | The open item's `@value`, or `''`: controlled                      |
| `@defaultValue`      | `string`                     | `''`         | The item open at first, uncontrolled                               |
| `@onValueChange`     | `(value: string) => void`    |              | Called with each item the user opens, and `''` when it closes      |
| `@viewport`          | `boolean`                    | `true`       | Show the contents in one viewport below the list                   |
| `@delayDuration`     | `number`                     | `200`        | How long the pointer rests on a trigger before it opens, in ms     |
| `@skipDelayDuration` | `number`                     | `300`        | How long after one closes that another opens without the delay, ms |
| `@orientation`       | `"horizontal" \| "vertical"` | `horizontal` | Which way the list runs (and which arrow enters a content)         |
| `@dir`               | `"ltr" \| "rtl"`             |              | The direction, when the document's shouldn't decide                |
| `@name`              | `string`                     |              | Its name, for `NavigationMenuHarness` (`data-test-jn-name`)        |
| `@as`                | `string`                     | `nav`        | The tag to render                                                  |

It renders a `<nav aria-label="Main">` (give it an `aria-label` of your own where a page has
more than one) and yields `{ List, Item, Link, Indicator, Viewport, link, value, isOpen,
setValue }`.

### n.List and n.Item

The list is a `<ul>` (in a `<div>` the indicator is placed in) and an item an `<li>`; `@value`
names an item for the menu's `@value` (an id of its own without it). An item yields `{ Trigger,
Content, trigger, value, isOpen }`.

### item.Trigger

A `<button>` (`@as` for another tag) with a chevron after its text that turns while its content
is open; `@icon` replaces it, and `@disabled` keeps it shut. `{{item.trigger}}` makes your own
element the trigger, with the Trigger's classes and attributes (the chevron is yours). While its
content is open, the item puts the focus proxy and the `aria-owns` after it, as the Trigger has
them: keep it the item's only element besides its content.

### item.Content

The content, in the viewport (or below its trigger, without one). It takes `@forceMount`, `@as`
and the handlers `@onEscapeKeyDown`, `@onPointerDownOutside`, `@onFocusOutside` and
`@onInteractOutside`, whose `preventDefault()` keeps it open.

### n.Link

An `<a>` (`@as` for another tag): `@active` marks the current page (`data-active`,
`aria-current="page"`), and `@onSelect` is called when it is selected, with a cancelable event:
`preventDefault()` keeps the content it is in open. `{{n.link}}` makes your own element a link,
styled as one: `<LinkTo @route="docs" {{n.link active=true}}>`.

### navigationMenuTriggerStyle

`navigationMenuTriggerStyle()` returns the trigger's classes, for a link with a trigger's look,
as upstream's function does.

### n.Indicator

A small arrow under the open trigger, as wide as it and moved along to it (`data-state` is
`visible` while a content is open); `@forceMount` keeps it rendered.

### n.Viewport

The panel the contents show in, below the list, sized to the open one. The menu renders one
itself; with `@viewport={{false}}`, `<n.Viewport />` places one where you put it, as upstream's
`NavigationMenuViewport`. `@forceMount` keeps it rendered while nothing is open.

### Data attributes

| Part      | Attributes                                                                                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root      | `class="jn-navigation-menu group/navigation-menu"`, `data-slot="navigation-menu"`, `data-viewport`, `data-orientation`, `data-test-jn="navigation-menu"`            |
| list      | `class="jn-navigation-menu-list group"`, `data-slot="navigation-menu-list"`, `data-orientation`, `data-test-jn-part="list"`                                         |
| item      | `class="jn-navigation-menu-item"`, `data-slot="navigation-menu-item"`, `data-test-jn-part="item"`, `data-test-jn-value`                                             |
| trigger   | `class="jn-navigation-menu-trigger …"`, `data-slot="navigation-menu-trigger"`, `aria-expanded`, `aria-controls`, `data-state`, `data-disabled`, `data-test-jn-part` |
| content   | `class="jn-navigation-menu-content"`, `data-slot="navigation-menu-content"`, `data-motion`, `data-orientation`, `data-state` (without a viewport)                   |
| viewport  | `class="jn-navigation-menu-viewport"`, `data-slot="navigation-menu-viewport"`, `data-state`, `--radix-navigation-menu-viewport-width` and `-height`                 |
| link      | `class="jn-navigation-menu-link"`, `data-slot="navigation-menu-link"`, `data-active`, `aria-current`, `data-test-jn-part="link"`                                    |
| indicator | `class="jn-navigation-menu-indicator"`, `data-slot="navigation-menu-indicator"`, `data-state`, `aria-hidden`                                                        |

`data-motion` is `from-start` or `from-end` on the content coming in, and `to-start` or `to-end`
on the one going out, as one replaces another.

## Keyboard interactions

| Key                       | What it does                                                                 |
| ------------------------- | ---------------------------------------------------------------------------- |
| `Space`, `Enter`          | On a trigger, opens its content, or closes it                                |
| `Tab`                     | From an open trigger into its content's links, and from the last on out      |
| `ArrowDown`               | On an open trigger, moves into its content (`ArrowRight` in a vertical menu) |
| `ArrowRight`, `ArrowLeft` | Moves to the next or previous trigger or link (swapped right to left)        |
| `ArrowDown`, `ArrowUp`    | Moves to the next or previous trigger or link, and between a content's links |
| `Home`, `End`             | Moves to the first or last trigger or link                                   |
| `Esc`                     | Closes the open content, and moves focus back to its trigger                 |

## Accessibility

- It is a `<nav>` landmark of links, as Radix's, not a menu: its triggers are buttons with
  `aria-expanded` and `aria-controls`, and each content is named by its trigger.
- With a viewport, the contents render after the list; an `aria-owns` after the open trigger
  puts its content there for assistive technology, and Tab goes from the trigger into it and,
  from its last link, on to the next trigger.
- Radix marks the focus proxy that sends Tab into the content `aria-hidden`, which axe reports
  (a focusable element hidden from assistive technology); Joinery leaves that off. The proxy is
  empty, and moves focus on as soon as it gets it.
- Escape, a press outside or focus leaving the menu closes the open content.

## Testing

`NavigationMenuHarness` from `@ember-joinery/test-support` drives a navigation menu, finding
items by their triggers' text and links by theirs:

```ts
import { NavigationMenuHarness, tab } from '@ember-joinery/test-support'

const nav = new NavigationMenuHarness()
const start = nav.item('Getting started')
await start.openWithKeyboard()
await tab()
assert.strictEqual(nav.focused, 'Introduction')
await start.select('Introduction')
assert.false(start.isOpen)
```

| Member                                  | What it is                                                |
| --------------------------------------- | --------------------------------------------------------- |
| `list`, `triggers`, `triggerLabels`     | Its list, its triggers, and their text                    |
| `listLinkElements`, `listLinks`         | The list's own links (not a content's), and their text    |
| `trigger(label)`, `listLink(label)`     | The trigger, or the list's link, with that text           |
| `item(label)`                           | An item (below)                                           |
| `openItem`, `isOpen`, `open`            | The open item's name, whether one is open, and the item   |
| `viewport`, `viewportSize`, `indicator` | The viewport, its size, and the indicator, while rendered |
| `focused`                               | The text of the trigger or link that has focus            |
| `pressEscape()`, `pressOutside()`       | Escape, or a press outside it                             |

An item has `trigger`, `value`, `isOpen`, `content`, `label`, `motion`, `links`,
`linkElements` and `link(label)` (a link by its text, or by the start of it, for a link with a
title and a description), and acts with `open()`, `close()`, `toggle()` (a click), `hover()`,
`unhover()`, `openWithKeyboard()` and `select(label)`.

## Upstream

shadcn/ui's [Navigation Menu](https://ui.shadcn.com/docs/components/radix/navigation-menu), from
`apps/v4/registry/bases/radix/ui/navigation-menu.tsx` at shadcn-ui/ui@8ab2771, in the Nova
style, on Radix's
[Navigation Menu](https://www.radix-ui.com/docs/primitives/components/navigation-menu).
