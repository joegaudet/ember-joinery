# Navigation Menu

A site's navigation, as Radix's `NavigationMenu`: a `<nav>` of links, some of them triggers that
open a panel of more links, shown in one viewport that takes the open panel's size. It has no
styles; the styled [Navigation Menu](/components/navigation-menu.md) is built on it.

<Example @name="navigation-menu-headless" @title="A navigation menu of your own" />

## Usage

```gts
import { NavigationMenu } from '@ember-joinery/primitives/navigation-menu'

<template>
  <NavigationMenu class="my-nav" as |n|>
    <n.List class="my-list">
      <n.Item @value="learn" as |item|>
        <item.Trigger class="my-trigger">Learn</item.Trigger>
        <item.Content class="my-panel">
          <n.Link href="/guides">Guides</n.Link>
        </item.Content>
      </n.Item>
      <n.Item><n.Link href="/blog" @active={{true}}>Blog</n.Link></n.Item>
    </n.List>
    <n.Indicator class="my-arrow" />
    <n.Viewport class="my-viewport" />
  </NavigationMenu>
</template>
```

- **State.** Which content is open is `@value` (its item's `@value`, or `''` for none), yours with
  `@onValueChange`, or its own from `@defaultValue`. An item without `@value` gets an id of its
  own.
- **Opening.** A click on a trigger opens its content, and another closes it. The pointer resting
  on a trigger opens it after `@delayDuration` (200ms), or at once within `@skipDelayDuration`
  (300ms) of another closing; leaving the trigger and its content closes it after 150ms, unless
  the pointer reaches the content (or the viewport) first.
- **Viewport.** With a `Viewport`, every content shows in it, and it sets
  `--radix-navigation-menu-viewport-width` and `-height` to the open content's size, so it can
  animate as one gives way to another. Each content's `data-motion` says which way it moves:
  `from-start` or `from-end` coming in, `to-start` or `to-end` going out, by where its trigger is
  (left and right are the screen's, right to left too). Without one, each content shows in its
  own item, with `data-state`.
- **Indicator.** Rendered beside the list (in its track), as wide as the open trigger and moved
  along to it with `left`, `width` and `transform`; `data-state` is `visible` or `hidden`.
- **Focus.** Tab goes from an open trigger into its content (through a focus proxy after the
  trigger), through its links, and out to the next trigger; Shift+Tab comes back in at the end.
  ArrowDown (ArrowRight in a vertical menu, ArrowLeft right to left) on an open trigger enters
  it. The arrows, Home and End move between the triggers and links of the list, and of a
  content. Escape closes the content and brings focus back to its trigger.
- **Links.** Selecting one closes the content it is in, unless its `@onSelect` prevents it.
  `@active` marks the current page. `{{n.link}}` makes your own element a link.

## API

| Argument             | Type                         | Default      | What it does                                        |
| -------------------- | ---------------------------- | ------------ | --------------------------------------------------- |
| `@value`             | `string`                     |              | The open item's `@value`, or `''`: controlled       |
| `@defaultValue`      | `string`                     | `''`         | The item open at first                              |
| `@onValueChange`     | `(value: string) => void`    |              | Called with each change                             |
| `@delayDuration`     | `number`                     | `200`        | How long the pointer rests before a content opens   |
| `@skipDelayDuration` | `number`                     | `300`        | How long after one closes the next opens at once    |
| `@orientation`       | `"horizontal" \| "vertical"` | `horizontal` | Which way the list runs                             |
| `@dir`               | `"ltr" \| "rtl"`             |              | The direction, when the document's shouldn't decide |
| `@name`              | `string`                     |              | Its name, for `NavigationMenuHarness`               |
| `@as`                | `string`                     | `nav`        | The tag to render                                   |

It yields `{ List, Item, Link, Indicator, Viewport, link, navigationMenu, value, isOpen, setValue
}`; an item yields `{ Trigger, Content, trigger, value, isOpen }`. Radix's nested
`NavigationMenu.Sub` isn't ported: shadcn's component has no part for it.

## Testing

```ts
import { NavigationMenuHarness } from '@ember-joinery/test-support'

const nav = new NavigationMenuHarness()
await nav.item('Learn').open()
assert.deepEqual(nav.item('Learn').links, ['Guides'])
```

The [Navigation Menu](/components/navigation-menu.md#testing) page lists its members.
