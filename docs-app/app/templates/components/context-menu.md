# Context Menu

Displays a menu of actions triggered by a right click.

<Example @name="context-menu-demo" @title="Context Menu" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { ContextMenu } from '@ember-joinery/ember'
```

## Usage

`<ContextMenu>` yields its parts:

```gts
import { ContextMenu } from '@ember-joinery/ember'

<template>
  <ContextMenu as |c|>
    <c.Trigger>Right click here</c.Trigger>
    <c.Content>
      <c.Item>Profile</c.Item>
      <c.Item>Billing</c.Item>
      <c.Item>Team</c.Item>
      <c.Item>Subscription</c.Item>
    </c.Content>
  </ContextMenu>
</template>
```

A right click on the trigger opens the content where the pointer is, in place of the browser's
own menu; on a phone, so does a long press. As Radix's, its state is its own: `@onOpenChange`
tells you when it opens and closes.

## Composition

Use the following composition to build a `ContextMenu`:

```text
ContextMenu
├── c.Trigger (or {{c.trigger}} on your own element)
└── c.Content
    ├── c.Group
    │   ├── c.Label
    │   ├── c.Item
    │   └── c.Item
    ├── c.Separator
    ├── c.Group
    │   ├── c.Label
    │   ├── c.CheckboxItem
    │   └── c.CheckboxItem
    ├── c.Separator
    ├── c.Group
    │   ├── c.Label
    │   └── c.RadioGroup (as |g|)
    │       ├── g.Item
    │       └── g.Item
    └── c.Sub (as |s|)
        ├── s.Trigger
        └── s.Content
            └── c.Group
                ├── c.Item
                └── c.Item
```

## Basic

A simple context menu with a few actions.

<Example @name="context-menu-basic" @title="Basic" />

## Submenu

Use `c.Sub` to nest secondary actions.

<Example @name="context-menu-submenu" @title="Submenu" />

## Shortcuts

Add `c.Shortcut` to show keyboard hints.

<Example @name="context-menu-shortcuts" @title="Shortcuts" />

## Groups

Group related actions and separate them with dividers.

<Example @name="context-menu-groups" @title="Groups" />

## Icons

Combine icons with labels for quick scanning.

<Example @name="context-menu-icons" @title="Icons" />

## Checkboxes

Use `c.CheckboxItem` for toggles.

<Example @name="context-menu-checkboxes" @title="Checkboxes" />

Here the example parts from ui.shadcn.com's, on purpose. Upstream's passes `defaultChecked`,
which Radix's checkbox item doesn't take (its state is only ever `checked`), so on
ui.shadcn.com all three items open unchecked and don't toggle. This one keeps the state the
example means: Show Bookmarks Bar and Show Developer Tools start checked, and each item toggles,
with its state in the example's own `@tracked` fields, as a checkbox item's always is.

## Radio

Use `c.RadioGroup`'s items for exclusive choices.

<Example @name="context-menu-radio" @title="Radio" />

## Destructive

Use `@variant="destructive"` to style the menu item as destructive.

<Example @name="context-menu-destructive" @title="Destructive" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): right to left, submenus open to the left, their chevrons
point left, and ArrowLeft opens a submenu while ArrowRight closes it.

<Example @name="context-menu-rtl" @title="RTL" @dir="rtl" />

## API Reference

### ContextMenu

| Argument        | Type                      | Default | What it does                                               |
| --------------- | ------------------------- | ------- | ---------------------------------------------------------- |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each state the user asks for                   |
| `@modal`        | `boolean`                 | `true`  | Keep focus and the pointer in the menu, and the page inert |
| `@dir`          | `"ltr" \| "rtl"`          |         | The direction, when the document's shouldn't decide        |
| `@name`         | `string`                  |         | Its name, for `ContextMenuHarness` (`data-test-jn-name`)   |

It renders an element with `display: contents` and yields `{ Trigger, Content, Portal, Group,
Label, Item, LinkItem, CheckboxItem, RadioGroup, Separator, Shortcut, Sub, trigger, item,
checkboxItem, isOpen, close }`.

### c.Trigger

A `<span>` (`@as` for another tag) that a right click, or a long press by touch or pen, opens
the menu on. Its text isn't selectable (`select-none`). With `@disabled`, the browser's own menu
shows there instead.

### c.Content

It goes beside the pointer, to its right and level with it, 2px off, as Radix's, flipping to
stay in view; it takes `@alignOffset`, `@avoidCollisions`, `@collisionPadding`, `@sticky`,
`@hideWhenDetached`, `@loop`, `@forceMount`, `@as` and the handlers a
[Dropdown Menu's content](/components/dropdown-menu.md#mcontent) takes.

### Items

The items, groups, labels, separators, shortcuts and submenus are the
[Dropdown Menu's](/components/dropdown-menu.md#items), with `context-menu` in their classes and
`data-slot`s.

### Data attributes

| Part        | Attributes                                                                                                                                                                          |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root        | `data-test-jn="context-menu"`, `data-test-jn-name`                                                                                                                                  |
| trigger     | `class="jn-context-menu-trigger"`, `data-slot="context-menu-trigger"`, `data-state`, `data-disabled`, `data-test-jn-part="trigger"`                                                 |
| content     | `class="jn-context-menu-content jn-menu-target"`, `data-slot="context-menu-content"`, `role="menu"`, `data-state`, `data-side`, `data-test-jn-part="content"`, `data-test-jn-owner` |
| items, etc. | as a Dropdown Menu's, with `context-menu` for `dropdown-menu`; a checkbox or radio item's indicator `<span>` has no `data-slot`, as upstream's                                      |

## Keyboard interactions

Once it is open, its keys are a [Dropdown Menu's](/components/dropdown-menu.md#keyboard-interactions).
A right click needs no key of its own: the keyboard's context menu key (or Shift+F10) on a
focused trigger sends the same `contextmenu` event.

## Accessibility

- The content is a `role="menu"`, whose items are `menuitem`, `menuitemcheckbox` and
  `menuitemradio`. Nothing names it, as in Radix; give the Content an `aria-label` to name it.
- Opening it moves focus to the menu, and the arrow keys start from there; closing it brings
  focus back where it was, unless the user went elsewhere.
- Modal, the default, it keeps focus in the menu and the pointer off the page, which it makes
  inert and stops scrolling until it closes.
- The trigger keeps iOS Safari's callout (`-webkit-touch-callout: none`) from covering the menu on
  a long press.

## Testing

`ContextMenuHarness` from `@ember-joinery/test-support` drives a context menu:

```ts
import { ContextMenuHarness } from '@ember-joinery/test-support'

const menu = new ContextMenuHarness()
await menu.open({ x: 120, y: 80 }) // a right click there
assert.deepEqual(menu.items, ['Back', 'Forward', 'Reload'])
await menu.select('Reload')
```

It has a [Dropdown Menu harness's](/components/dropdown-menu.md#testing) members for the content
and its items, with these for opening it:

| Member              | What it is                                                |
| ------------------- | --------------------------------------------------------- |
| `isOpen`            | The trigger's `data-state`                                |
| `open(point?)`      | A right click on the trigger, at `point` or its centre    |
| `longPress(point?)` | A touch (or `{ pointerType: 'pen' }`) held until it opens |
| `close()`           | Escape                                                    |

## Upstream

shadcn/ui's [Context Menu](https://ui.shadcn.com/docs/components/radix/context-menu), from
`apps/v4/registry/bases/radix/ui/context-menu.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
on Radix's [Context Menu](https://www.radix-ui.com/docs/primitives/components/context-menu).
