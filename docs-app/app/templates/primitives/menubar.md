# Menubar

A row of menus, as Radix's `Menubar` and a desktop app's menu bar: a `role="menubar"` whose
triggers share one tab stop, each menu a [Dropdown Menu's](/primitives/dropdown-menu.md)
content and items. It has no styles; the styled [Menubar](/components/menubar.md) is built on
it.

<Example @name="menubar-headless" @title="A menubar of your own" />

## Usage

```gts
import { Menubar } from '@ember-joinery/primitives/menubar'

<template>
  <Menubar @value={{this.open}} @onValueChange={{this.setOpen}} class="my-bar" as |bar|>
    <bar.Menu @value="file" as |m|>
      <m.Trigger class="my-trigger">File</m.Trigger>
      <m.Content @align="start" @sideOffset={{4}} class="my-menu">
        <m.Item @onSelect={{this.newTab}}>New Tab</m.Item>
        <m.Separator />
        <m.Sub as |s|>
          <s.Trigger>Share</s.Trigger>
          <s.Content class="my-menu"><m.Item>Email link</m.Item></s.Content>
        </m.Sub>
      </m.Content>
    </bar.Menu>
    <bar.Menu @value="edit" as |m|>
      <m.Trigger class="my-trigger">Edit</m.Trigger>
      <m.Content class="my-menu"><m.Item>Undo</m.Item></m.Content>
    </bar.Menu>
  </Menubar>
</template>
```

- **State.** Which menu is open is `@value` (the menu's `@value`, or `''` for none), yours with
  `@onValueChange`, or its own from `@defaultValue`. A menu without `@value` gets an id of its
  own. It yields `value` and `close`, and each menu `value`, `isOpen`, `open` and `close`.
- **Triggers.** Each is a `<button>`, a `role="menuitem"` with `aria-haspopup="menu"`; they share
  one tab stop, and the arrow keys, Home and End move between them (round, unless `@loop` is
  `false`; flipped right to left). A press, Enter, Space or ArrowDown opens a menu.
- **Menus.** Each content is a Dropdown Menu's, not modal: its items, checkbox and radio items,
  groups, labels, separators and submenus, with the same arguments and modifiers. While one is
  open, ArrowLeft and ArrowRight open the menu beside it (the arrow pointing into a submenu, on
  its trigger, opens that instead), and the pointer resting on another trigger opens that one.
- **Focus.** A menu its trigger's keys opened moves focus to its first item; one the pointer or
  the arrows opened keeps focus on the menu itself, as Radix's. Escape closes it and brings focus
  back to its trigger; a press or focus outside closes it and leaves focus where it went.
- **Placement.** Below its trigger, at its start, touching it: Radix's defaults, which the
  content's Popper arguments change.
- **Styles.** Its custom properties are `--radix-menubar-content-transform-origin` and the rest,
  as a dropdown menu's with `menubar` in their names.

## API

| Argument         | Type                      | Default | What it does                                         |
| ---------------- | ------------------------- | ------- | ---------------------------------------------------- |
| `@value`         | `string`                  |         | The open menu's `@value`, or `''`: controlled        |
| `@defaultValue`  | `string`                  | `''`    | The menu open at first                               |
| `@onValueChange` | `(value: string) => void` |         | Called with each change                              |
| `@loop`          | `boolean`                 | `true`  | The arrow keys go round                              |
| `@dir`           | `"ltr" \| "rtl"`          |         | The direction, when the document's shouldn't decide  |
| `@name`          | `string`                  |         | Its name, for `MenubarHarness` (`data-test-jn-name`) |
| `@as`            | `string`                  | `div`   | The tag to render                                    |

It yields `{ Menu, value, close }`. A menu yields `{ Trigger, Content, Portal, Group, Label,
Item, LinkItem, CheckboxItem, RadioGroup, Separator, Sub, Arrow, trigger, item, checkboxItem,
group, label, separator, arrow, menu, value, isOpen, open, close }`; `{{m.trigger}}` makes your
own element its trigger.

## Testing

```ts
import { MenubarHarness } from '@ember-joinery/test-support'

const menubar = new MenubarHarness()
await menubar.menu('File').openWithKeyboard()
assert.strictEqual(menubar.openMenu, 'File')
```

The [Menubar](/components/menubar.md#testing) page lists its members.
