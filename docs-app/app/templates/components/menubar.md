# Menubar

A visually persistent menu common in desktop applications that provides quick access to a
consistent set of commands.

<Example @name="menubar-demo" @title="Menubar" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Menubar } from '@ember-joinery/ember'
```

## Usage

`<Menubar>` yields its menus, and each menu yields its parts:

```gts
import { Menubar } from '@ember-joinery/ember'

<template>
  <Menubar as |bar|>
    <bar.Menu as |m|>
      <m.Trigger>File</m.Trigger>
      <m.Content>
        <m.Group>
          <m.Item>
            New Tab
            <m.Shortcut>⌘T</m.Shortcut>
          </m.Item>
          <m.Item>New Window</m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item>Share</m.Item>
          <m.Item>Print</m.Item>
        </m.Group>
      </m.Content>
    </bar.Menu>
  </Menubar>
</template>
```

Each menu's content, items, checkbox and radio items, labels, separators, shortcuts and
submenus are a [Dropdown Menu's](/components/dropdown-menu.md), with `menubar` in their classes
and `data-slot`s. Which menu is open is the menubar's `@value` (a menu's own `@value`, or `''`
for none), its own or yours with `@onValueChange`.

## Composition

Use the following composition to build a `Menubar`:

```text
Menubar (as |bar|)
├── bar.Menu (as |m|)
│   ├── m.Trigger
│   └── m.Content
│       ├── m.Group
│       │   ├── m.Label
│       │   ├── m.Item
│       │   └── m.Item
│       ├── m.Separator
│       ├── m.Group
│       │   ├── m.Label
│       │   ├── m.CheckboxItem
│       │   └── m.CheckboxItem
│       ├── m.Separator
│       ├── m.Group
│       │   ├── m.Label
│       │   └── m.RadioGroup (as |g|)
│       │       ├── g.Item
│       │       └── g.Item
│       └── m.Sub (as |s|)
│           ├── s.Trigger
│           └── s.Content
│               └── m.Group
│                   ├── m.Label
│                   ├── m.Item
│                   └── m.Item
└── bar.Menu (as |m|)
    ├── m.Trigger
    └── m.Content
        └── m.Group
            ├── m.Label
            ├── m.Item
            └── m.Item
```

## Checkbox

Use `m.CheckboxItem` for toggleable options.

<Example @name="menubar-checkbox" @title="Checkbox" />

As on ui.shadcn.com, the items keep the state they start with: a checkbox item's state is only
ever `@checked`, which `@onCheckedChange` asks you to change. To make one toggle, keep its state
in a `@tracked` field of your own, as the
[Dropdown Menu's checkboxes](/components/dropdown-menu.md#checkboxes) do.

## Radio

Use `m.RadioGroup` and its items for single-select options.

<Example @name="menubar-radio" @title="Radio" />

## Submenu

Use `m.Sub`, its `s.Trigger` and `s.Content` for nested menus.

<Example @name="menubar-submenu" @title="Submenu" />

## With Icons

<Example @name="menubar-icons" @title="With Icons" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): right to left, ArrowLeft moves to the next menu and
ArrowRight to the previous one, submenus open to the left, their chevrons point left, and each
menu lines up with its trigger's right edge.

<Example @name="menubar-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Menubar

| Argument         | Type                      | Default | What it does                                                  |
| ---------------- | ------------------------- | ------- | ------------------------------------------------------------- |
| `@value`         | `string`                  |         | The open menu's `@value`, or `''`: controlled                 |
| `@defaultValue`  | `string`                  | `''`    | The menu open at first, uncontrolled                          |
| `@onValueChange` | `(value: string) => void` |         | Called with each menu the user opens, and `''` when it closes |
| `@loop`          | `boolean`                 | `true`  | The arrow keys go round from the last menu to the first       |
| `@dir`           | `"ltr" \| "rtl"`          |         | The direction, when the document's shouldn't decide           |
| `@name`          | `string`                  |         | Its name, for `MenubarHarness` (`data-test-jn-name`)          |
| `@as`            | `string`                  | `div`   | The tag to render                                             |

It renders a `role="menubar"` and yields `{ Menu, value, close }`.

### bar.Menu

`@value` names it for the menubar's `@value` (an id of its own without it). It renders nothing
of its own and yields `{ Trigger, Content, Portal, Group, Label, Item, LinkItem, CheckboxItem,
RadioGroup, Separator, Shortcut, Sub, Arrow, trigger, item, checkboxItem, value, isOpen, open,
close }`.

### m.Trigger

A `<button>` in the bar (`@as` for another tag), a `role="menuitem"` that opens its menu;
`@disabled` keeps it shut, and the arrow keys pass over it. `{{m.trigger}}` makes your own
element the trigger, with the Trigger's classes and attributes: `<button {{m.trigger}}>`.

### m.Content

It goes below its trigger, lined up with its start, 4px before it (`@alignOffset={{-4}}`) and
8px off (`@sideOffset={{8}}`), as upstream's, flipping to stay in view. It takes Radix's Popper
arguments and handlers, as a [Dropdown Menu's content](/components/dropdown-menu.md#mcontent)
does, but isn't modal: the page around it stays as it is.

### Items

The items, groups, labels, separators, shortcuts and submenus are the
[Dropdown Menu's](/components/dropdown-menu.md#items), with `menubar` in their classes and
`data-slot`s, and so are their modifiers (`{{m.item}}`, `{{m.checkboxItem}}`, a radio group's
`{{g.item}}` and a submenu's `{{s.trigger}}`).

### Data attributes

| Part        | Attributes                                                                                                                                                                                                               |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| root        | `class="jn-menubar"`, `data-slot="menubar"`, `role="menubar"`, `data-orientation="horizontal"`, `data-test-jn="menubar"`, `data-test-jn-name`                                                                            |
| trigger     | `class="jn-menubar-trigger"`, `data-slot="menubar-trigger"`, `role="menuitem"`, `aria-haspopup`, `aria-expanded`, `data-state`, `data-highlighted`, `data-disabled`, `data-test-jn-part="trigger"`, `data-test-jn-value` |
| content     | `class="jn-menubar-content jn-menu-target"`, `data-slot="menubar-content"`, `role="menu"`, `data-state`, `data-side`, `data-align`, `data-test-jn-part="content"`, `data-test-jn-owner`                                  |
| items, etc. | as a Dropdown Menu's, with `menubar` for `dropdown-menu`; a checkbox or radio item's indicator `<span>` has no `data-slot`, as upstream's, and a class of its own (`jn-menubar-checkbox-item-indicator`)                 |

## Keyboard interactions

| Key                                      | What it does                                                                    |
| ---------------------------------------- | ------------------------------------------------------------------------------- |
| `Tab`                                    | Moves focus into the menubar, to the trigger last focused (the first, at first) |
| `ArrowRight` (`ArrowLeft` right to left) | On a trigger, moves to the next; in an open menu, opens the next one            |
| `ArrowLeft` (`ArrowRight` right to left) | On a trigger, moves to the previous; in an open menu, opens the previous one    |
| `Home`, `End`                            | On a trigger, moves to the first or last                                        |
| `Space`, `Enter`, `ArrowDown`            | On a trigger, opens its menu on its first item                                  |
| `ArrowDown`, `ArrowUp`                   | In a menu, moves to the next or previous item                                   |
| `Space`, `Enter`                         | On an item, selects it                                                          |
| `ArrowRight` (`ArrowLeft` right to left) | On a submenu's trigger, opens the submenu instead of the next menu              |
| `ArrowLeft` (`ArrowRight` right to left) | In a submenu, closes it and goes back to its trigger                            |
| A letter or digit                        | Moves to the next item whose text starts with what has been typed               |
| `Esc`                                    | Closes the menu, and moves focus back to its trigger                            |

## Accessibility

- It follows the [Menubar](https://www.w3.org/WAI/ARIA/apg/patterns/menubar/) pattern: a
  `role="menubar"` whose triggers are `menuitem`s with `aria-haspopup="menu"` and
  `aria-expanded`, and one tab stop between them (a roving tabindex). Each menu is a
  `role="menu"` named by its trigger.
- Opened from its trigger's keys, a menu moves focus to its first item; opened by the pointer,
  or by ArrowLeft and ArrowRight from another menu, focus goes to the menu itself, and the arrow
  keys start from there, as Radix's. Closing it brings focus back to its trigger.
- While a menu is open, the pointer resting on another trigger opens that one.
- Its menus aren't modal, as Radix's: the page stays as it is, and focus or a press outside
  closes the menu.

## Testing

`MenubarHarness` from `@ember-joinery/test-support` drives a menubar, finding its menus by their
triggers' text:

```ts
import { MenubarHarness, pressKey } from '@ember-joinery/test-support'

const menubar = new MenubarHarness()
assert.deepEqual(menubar.menus, ['File', 'Edit', 'View'])
const file = menubar.menu('File')
await file.openWithKeyboard()
assert.strictEqual(file.highlighted, 'New Tab')
await pressKey('ArrowRight')
assert.strictEqual(menubar.openMenu, 'Edit')
await menubar.menu('Edit').select('Undo')
```

| Member                            | What it is                                           |
| --------------------------------- | ---------------------------------------------------- |
| `triggers`, `menus`               | Its triggers, and their text                         |
| `trigger(label)`                  | The trigger with that text                           |
| `menu(label)`                     | A menu (below)                                       |
| `openMenu`, `isOpen`              | The open menu's name, or `null`; whether one is open |
| `focusedTrigger`, `tabStop`       | The trigger that has focus, and the one Tab lands on |
| `pressEscape()`, `pressOutside()` | Escape, or a press outside it                        |

A menu has a [Dropdown Menu harness's](/components/dropdown-menu.md#testing) members for its
content and items (`items`, `highlighted`, `isChecked()`, `select()`, `sub()`…), with these:

| Member                          | What it is                                                         |
| ------------------------------- | ------------------------------------------------------------------ |
| `trigger`, `isOpen`             | Its trigger, and its `aria-expanded`                               |
| `isTriggerDisabled`             | Whether its trigger is disabled                                    |
| `open()`, `close()`, `toggle()` | A press on its trigger                                             |
| `openWithKeyboard(key)`         | Focus on its trigger and Enter (Space or ArrowDown)                |
| `hoverTrigger()`                | The pointer resting on its trigger: it opens while another is open |

## Upstream

shadcn/ui's [Menubar](https://ui.shadcn.com/docs/components/radix/menubar), from
`apps/v4/registry/bases/radix/ui/menubar.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Menubar](https://www.radix-ui.com/docs/primitives/components/menubar).
