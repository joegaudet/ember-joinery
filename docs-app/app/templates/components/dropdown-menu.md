# Dropdown Menu

Displays a menu to the user — such as a set of actions or functions — triggered by a button.

<Example @name="dropdown-menu-demo" @title="Dropdown Menu" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { DropdownMenu } from '@ember-joinery/ember'
```

## Usage

`<DropdownMenu>` yields its parts. Upstream's `asChild` trigger is the yielded `trigger`
modifier on your own [Button](/components/button.md):

```gts
import { Button, DropdownMenu } from '@ember-joinery/ember'

<template>
  <DropdownMenu as |m|>
    <Button @variant="outline" {{m.trigger}}>Open</Button>
    <m.Content>
      <m.Group>
        <m.Label>My Account</m.Label>
        <m.Item>Profile</m.Item>
        <m.Item>Billing</m.Item>
      </m.Group>
      <m.Separator />
      <m.Group>
        <m.Item>Team</m.Item>
        <m.Item>Subscription</m.Item>
      </m.Group>
    </m.Content>
  </DropdownMenu>
</template>
```

Its state is its own, or yours: pass `@open` with `@onOpenChange` to control it, or
`@defaultOpen` to start it open.

## Composition

Use the following composition to build a `DropdownMenu`:

```text
DropdownMenu
├── m.Trigger (or {{m.trigger}} on your own element)
└── m.Content
    ├── m.Group
    │   ├── m.Label
    │   ├── m.Item
    │   └── m.Item
    ├── m.Separator
    ├── m.Group
    │   ├── m.Label
    │   ├── m.CheckboxItem
    │   └── m.CheckboxItem
    ├── m.Separator
    ├── m.Group
    │   ├── m.Label
    │   └── m.RadioGroup (as |g|)
    │       ├── g.Item
    │       └── g.Item
    └── m.Sub (as |s|)
        ├── s.Trigger
        └── s.Content
            └── m.Group
                ├── m.Label
                ├── m.Item
                └── m.Item
```

A submenu's items are the menu's own parts (`m.Item`), at any depth: an item belongs to the
menu content it is rendered in.

## Basic

A basic dropdown menu with labels and separators.

<Example @name="dropdown-menu-basic" @title="Basic" />

## Submenu

Use `m.Sub` to nest secondary actions. It yields its `Trigger` and `Content`; `m.Portal`, as
upstream's markup has it, renders its block in place, since the top layer needs no portal.

<Example @name="dropdown-menu-submenu" @title="Submenu" />

## Shortcuts

Add `m.Shortcut` to show keyboard hints.

<Example @name="dropdown-menu-shortcuts" @title="Shortcuts" />

## Icons

Combine icons with labels for quick scanning.

<Example @name="dropdown-menu-icons" @title="Icons" />

## Checkboxes

Use `m.CheckboxItem` for toggles.

<Example @name="dropdown-menu-checkboxes" @title="Checkboxes" />

## Checkboxes Icons

Add icons to checkbox items.

<Example @name="dropdown-menu-checkboxes-icons" @title="Checkboxes Icons" />

## Radio Group

Use `m.RadioGroup` for exclusive choices.

<Example @name="dropdown-menu-radio-group" @title="Radio Group" />

## Radio Icons

Show radio options with icons.

<Example @name="dropdown-menu-radio-icons" @title="Radio Icons" />

## Destructive

Use `@variant="destructive"` for irreversible actions.

<Example @name="dropdown-menu-destructive" @title="Destructive" />

## Avatar

An account switcher dropdown triggered by an avatar. Upstream's example, `dropdown-menu-avatar`,
comes with Avatar.

## Complex

A richer example combining groups, icons, and submenus.

<Example @name="dropdown-menu-complex" @title="Complex" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): right to left, `@align="start"` lines the content up
with the trigger's right edge, submenus open to the left, their chevrons point left, and
ArrowLeft opens a submenu while ArrowRight closes it.

<Example @name="dropdown-menu-rtl" @title="RTL" @dir="rtl" />

## API Reference

### DropdownMenu

| Argument        | Type                      | Default | What it does                                                         |
| --------------- | ------------------------- | ------- | -------------------------------------------------------------------- |
| `@open`         | `boolean`                 |         | Whether it is open, controlled                                       |
| `@defaultOpen`  | `boolean`                 | `false` | Whether it starts open, uncontrolled                                 |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each state the user asks for                             |
| `@modal`        | `boolean`                 | `true`  | Keep focus and the pointer in the menu, and the page inert           |
| `@dir`          | `"ltr" \| "rtl"`          |         | The direction, when the document's (at the trigger) shouldn't decide |
| `@name`         | `string`                  |         | Its name, for `DropdownMenuHarness` (`data-test-jn-name`)            |

It renders an element with `display: contents` and yields `{ Trigger, Content, Portal, Group,
Label, Item, LinkItem, CheckboxItem, RadioGroup, Separator, Shortcut, Sub, Arrow, trigger, item,
checkboxItem, isOpen, open, close, toggle, setOpen }`. It also takes ember-primitives' Menu's
positioning arguments (`@placement`, `@offsetOptions`, `@flipOptions`, `@shiftOptions`,
`@middleware`, `@strategy`): see [the primitive](/primitives/dropdown-menu.md).

### m.Trigger

A `<button>` (`@as` for another tag) that opens and closes the menu: a press, Enter, Space or
ArrowDown. `@disabled` turns it off. For your own element or component, use `{{m.trigger}}`.

### m.Content

| Argument                                                         | Type                                     | Default    | What it does                                            |
| ---------------------------------------------------------------- | ---------------------------------------- | ---------- | ------------------------------------------------------- |
| `@side`                                                          | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"` | The side of the trigger it goes on                      |
| `@align`                                                         | `"start" \| "center" \| "end"`           | `"start"`  | Where along that side                                   |
| `@sideOffset`                                                    | `number`                                 | `4`        | Its distance from the trigger, in pixels                |
| `@alignOffset`                                                   | `number`                                 | `0`        | Its shift from the start or end, in pixels              |
| `@avoidCollisions`                                               | `boolean`                                | `true`     | Flip and shift to stay in view                          |
| `@collisionPadding`                                              | `number` or per side                     | `0`        | How far from the viewport's edges to stay               |
| `@sticky`                                                        | `"partial" \| "always"`                  | `partial`  | Whether it may shift off its trigger                    |
| `@hideWhenDetached`                                              | `boolean`                                | `false`    | Hide it while its trigger is scrolled out of view       |
| `@loop`                                                          | `boolean`                                | `false`    | The arrow keys go round from the last item to the first |
| `@forceMount`                                                    | `boolean`                                | `false`    | Keep it rendered while closed, to animate it yourself   |
| `@onCloseAutoFocus`                                              | `(event) => void`                        |            | Before focus goes back; `preventDefault()` to stop it   |
| `@onEscapeKeyDown`                                               | `(event) => void`                        |            | `preventDefault()` keeps it open                        |
| `@onPointerDownOutside`, `@onFocusOutside`, `@onInteractOutside` | `(event) => void`                        |            | `preventDefault()` keeps it open                        |
| `@as`                                                            | tag name                                 | `div`      | The tag to render                                       |

Its width is its trigger's (`--radix-dropdown-menu-trigger-width`), but never less than 8rem
(the style's `min-w-32`): a long item doesn't widen it. Its height is at most the
room below it (`--radix-dropdown-menu-content-available-height`). Both are upstream's. Give the
Content a `class` with a width of its own to change it, as upstream's examples do (`w-40`).

### Items

| Part             | Arguments                                                                                                         |
| ---------------- | ----------------------------------------------------------------------------------------------------------------- |
| `m.Item`         | `@onSelect`, `@variant` (`"default"` or `"destructive"`), `@inset`, `@disabled`, `@textValue`, `@as`              |
| `m.LinkItem`     | `@href`, `@includeActiveQueryParams`, `@activeOnSubPaths`, and the Item's                                         |
| `m.CheckboxItem` | `@checked` (`true`, `false` or `"indeterminate"`), `@onCheckedChange`, `@inset`, `@disabled`, `@icon`             |
| `m.RadioGroup`   | `@value`, `@onValueChange`; yields `{ Item, value }`, whose `Item` takes `@value`, `@inset`, `@disabled`, `@icon` |
| `m.Label`        | `@inset`                                                                                                          |
| `m.Shortcut`     | `@as` (default `span`)                                                                                            |
| `m.Sub`          | `@open`, `@defaultOpen`, `@onOpenChange`; yields `{ Trigger, Content, trigger, isOpen, setOpen }`                 |
| `s.Trigger`      | `@inset`, `@disabled`, `@icon` (its chevron)                                                                      |
| `s.Content`      | the Content's, but `@side` and `@align`: it goes beside its trigger, aligned with its top                         |

Selecting an item calls `@onSelect` with a cancelable event and closes the menu;
`event.preventDefault()` keeps it open. A checkbox or radio item's state is yours, as Radix's
is: the menu's content is gone while it is closed, so it has nowhere to keep one of its own.
`m.Group` is a `role="group"`, `m.Separator` a horizontal `role="separator"`, and `m.Shortcut` a
`<span>` at the item's end (`@as` renders another tag). A submenu closes, calling
`@onOpenChange(false)`, when the menu it is in closes, as Radix's does, so one your state holds
open isn't open again the next time the menu opens.

`{{m.item}}` makes your own element or component an item, styled as one (`variant`, `inset`
and the Item's other arguments are its named arguments): `<LinkTo @route="profile" {{m.item}}>`.
`{{m.checkboxItem}}` does the same for a checkbox item, whose check mark is then yours.

### Data attributes

| Part                       | Attributes                                                                                                                                                                                                             |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root                       | `data-test-jn="dropdown-menu"`, `data-test-jn-name`                                                                                                                                                                    |
| trigger                    | `aria-haspopup="menu"`, `aria-expanded`, `aria-controls`, `data-state`, `data-disabled`, `data-test-jn-part="trigger"`                                                                                                 |
| content                    | `class="jn-dropdown-menu-content jn-menu-target"`, `data-slot="dropdown-menu-content"`, `role="menu"`, `aria-labelledby`, `data-state`, `data-side`, `data-align`, `data-test-jn-part="content"`, `data-test-jn-owner` |
| item                       | `class="jn-dropdown-menu-item"`, `data-slot`, `role="menuitem"`, `data-variant`, `data-inset`, `data-highlighted`, `data-disabled`, `aria-disabled`, `data-test-jn-part="item"`                                        |
| checkbox and radio items   | `role="menuitemcheckbox"` (`menuitemradio`), `aria-checked`, `data-state` (`checked`, `unchecked`, `indeterminate`), `data-test-jn-part="checkbox-item"` (`radio-item`, with `data-test-jn-value`)                     |
| sub-trigger                | `role="menuitem"`, `aria-haspopup="menu"`, `aria-expanded`, `aria-controls`, `data-state`, `data-test-jn-part="sub-trigger"`                                                                                           |
| sub-content                | `role="menu"`, `aria-labelledby` (its trigger), `data-state`, `data-side`, `data-test-jn-part="sub-content"`                                                                                                           |
| label, separator, shortcut | `class="jn-dropdown-menu-label"` (`-separator`, `-shortcut`), `data-slot`, `data-test-jn-part`                                                                                                                         |

A Button of your own keeps its own `data-slot="button"`, as upstream's `asChild` does; the
Trigger part renders `data-slot="dropdown-menu-trigger"`. Upstream also gives the content
`cn-menu-translucent`, which shadcn's default menu colour takes away; add
`class="jn-menu-translucent"` to a Content for its translucent menus.

## Keyboard interactions

| Key                                      | What it does                                                             |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| `Space`, `Enter`                         | On the trigger, opens the menu on its first item; on an item, selects it |
| `ArrowDown`                              | On the trigger, opens the menu; in it, moves to the next item            |
| `ArrowUp`                                | Moves to the previous item                                               |
| `Home`, `PageUp`                         | Moves to the first item                                                  |
| `End`, `PageDown`                        | Moves to the last item                                                   |
| `ArrowRight` (`ArrowLeft` right to left) | On a submenu's trigger, opens it on its first item                       |
| `ArrowLeft` (`ArrowRight` right to left) | In a submenu, closes it and goes back to its trigger                     |
| A letter or digit                        | Moves to the next item whose text starts with what has been typed        |
| `Esc`                                    | Closes the menu, and moves focus back to the trigger                     |

## Accessibility

- It follows the [Menu Button](https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/) pattern:
  the trigger has `aria-haspopup="menu"` and `aria-expanded`, and the content is a `role="menu"`
  named by its trigger, whose items are `menuitem`, `menuitemcheckbox` and `menuitemradio`.
- Opened from the keyboard, focus goes to the first item; opened by the pointer, it goes to the
  menu itself, and the arrow keys start from there. Closing it brings focus back to the trigger.
- A submenu opens when the pointer rests on its trigger, and stays open while the pointer crosses
  other items on its way there (Radix's grace area).
- Modal, the default, it keeps focus in the menu and the pointer off the page, which it makes
  inert and stops scrolling until it closes. Radix hides the page with `aria-hidden` instead,
  which leaves its buttons focusable but hidden; `inert` is what a modal dialog does.
- It is in the browser's top layer while open, so no ancestor's `overflow` clips it.

## Testing

`DropdownMenuHarness` from `@ember-joinery/test-support` drives a dropdown menu, finding items by
their text (their shortcut left out):

```ts
import { DropdownMenuHarness } from '@ember-joinery/test-support'

const menu = new DropdownMenuHarness()
await menu.open()
assert.deepEqual(menu.items, ['Profile', 'Billing', 'Log out'])
const invite = menu.sub('Invite users')
await invite.open()
await invite.select('Email')
assert.false(menu.isOpen)
```

| Member                                                                          | What it is                                                                                       |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `trigger`, `content`                                                            | Its trigger, and its content (or `null` while closed)                                            |
| `isOpen`, `isShown`                                                             | The trigger's `aria-expanded`; whether the content is in the top layer                           |
| `label`, `text`, `side`, `align`                                                | The content's name and text, and where it went                                                   |
| `items`, `itemElements`, `labels`, `separators`                                 | Its items' text and elements, its labels' text, how many separators                              |
| `highlighted`                                                                   | The focused item's text, or `null`                                                               |
| `item(label)`                                                                   | The item with that text                                                                          |
| `isDisabled()`, `isChecked()`, `checked()`, `role()`, `shortcut()`, `variant()` | An item's state, by its text                                                                     |
| `open()`, `close()`, `toggle()`                                                 | A press on the trigger                                                                           |
| `openWithKeyboard(key)`                                                         | Focus on the trigger and Enter (Space or ArrowDown)                                              |
| `select(label)`, `hover(label)`                                                 | A click on an item, or the pointer resting on it                                                 |
| `sub(label)`                                                                    | A submenu: the same members, with `trigger`, `isOpen`, `open()` (hover) and `openWithKeyboard()` |
| `pressEscape()`, `pressOutside()`                                               | Escape, or a press outside it                                                                    |

## Upstream

shadcn/ui's [Dropdown Menu](https://ui.shadcn.com/docs/components/radix/dropdown-menu), from
`apps/v4/registry/bases/radix/ui/dropdown-menu.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
on Radix's [Dropdown Menu](https://www.radix-ui.com/docs/primitives/components/dropdown-menu).
