# Context Menu

A menu opened by a right click, as Radix's `ContextMenu`: a right click on its trigger (or a
long press by touch or pen) opens the content at the pointer, in place of the browser's own
menu. Its content, items and submenus are a [Dropdown Menu's](/primitives/dropdown-menu.md). It
has no styles; the styled [Context Menu](/components/context-menu.md) is built on it.

<Example @name="context-menu-headless" @title="A context menu of your own" />

## Usage

```gts
import { ContextMenu } from '@ember-joinery/primitives/context-menu'

<template>
  <ContextMenu @onOpenChange={{this.opened}} as |c|>
    <c.Trigger class="my-area">Right click here</c.Trigger>
    <c.Content class="my-menu">
      <c.Item @onSelect={{this.back}}>Back</c.Item>
      <c.Item @disabled={{true}}>Forward</c.Item>
    </c.Content>
  </ContextMenu>
</template>
```

- **State.** As Radix's, its state is its own: `@onOpenChange` tells you when it opens and
  closes, and it yields `isOpen` and `close`.
- **Opening.** A right click on the trigger opens it at the pointer; another while it is open
  moves it there. A touch or a pen held still for 700ms opens it too (moving first is a scroll,
  and cancels it). `@disabled` on the trigger leaves the browser's own menu alone.
- **Placement.** The content goes to the pointer's right, level with it, 2px off, flipping to
  stay in view: Radix's, which a context menu's content can't change.
- **Focus.** Opening it moves focus to the menu; closing it brings focus back where it was,
  unless the user went elsewhere.
- **Styles.** Its custom properties are `--radix-context-menu-content-transform-origin` and the
  rest, as a dropdown menu's with `context-menu` in their names.

## API

| Argument        | Type                      | Default | What it does                                             |
| --------------- | ------------------------- | ------- | -------------------------------------------------------- |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each state the user asks for                 |
| `@modal`        | `boolean`                 | `true`  | Keep the pointer and focus in the menu, the page inert   |
| `@dir`          | `"ltr" \| "rtl"`          |         | The direction, for the arrow keys and submenus' side     |
| `@name`         | `string`                  |         | Its name, for `ContextMenuHarness` (`data-test-jn-name`) |

It yields `{ Trigger, Content, Portal, Group, Label, Item, LinkItem, CheckboxItem, RadioGroup,
Separator, Sub, Arrow, trigger, item, checkboxItem, group, label, separator, menu, isOpen,
close }`. The trigger is a `<span>` (`@as` for another tag); its modifier, `{{c.trigger}}`,
makes your own element the area.

## Testing

```ts
import { ContextMenuHarness } from '@ember-joinery/test-support'

const menu = new ContextMenuHarness()
await menu.open({ x: 120, y: 80 })
await menu.longPress()
```

The [Context Menu](/components/context-menu.md#testing) page lists its members.
