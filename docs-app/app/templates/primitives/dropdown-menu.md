# Dropdown Menu

A menu opened by a button, as Radix's `DropdownMenu`: its content is a `role="menu"` in the
browser's top layer, placed against its trigger, with the arrow keys, Home, End and typeahead
between its items, submenus that open on hover or the arrow pointing into them, and Escape or a
press outside closing it. It covers ember-primitives' `Menu`, which it is also exported as. It
has no styles; the styled [Dropdown Menu](/components/dropdown-menu.md) is built on it, and
[Context Menu](/primitives/context-menu.md) shares its content and items.

<Example @name="dropdown-menu-headless" @title="ember-primitives' Menu" />

## Usage

```gts
import { DropdownMenu } from '@ember-joinery/primitives/dropdown-menu'

<template>
  <DropdownMenu as |m|>
    <m.Trigger class="my-button">Options</m.Trigger>
    <m.Content @align="start" @sideOffset={{4}} class="my-menu">
      <m.Label>My Account</m.Label>
      <m.Item @onSelect={{this.profile}}>Profile</m.Item>
      <m.CheckboxItem @checked={{this.compact}} @onCheckedChange={{this.setCompact}} as |item|>
        <item.Indicator>✓</item.Indicator>
        Compact
      </m.CheckboxItem>
      <m.RadioGroup @value={{this.theme}} @onValueChange={{this.setTheme}} as |g|>
        <g.Item @value="light" as |item|><item.Indicator>●</item.Indicator> Light</g.Item>
        <g.Item @value="dark" as |item|><item.Indicator>●</item.Indicator> Dark</g.Item>
      </m.RadioGroup>
      <m.Separator />
      <m.Sub as |s|>
        <s.Trigger>Invite users</s.Trigger>
        <s.Content class="my-menu"><m.Item>Email</m.Item></s.Content>
      </m.Sub>
    </m.Content>
  </DropdownMenu>
</template>
```

- **State.** Pass `@open` with `@onOpenChange` to control it, or start it with `@defaultOpen`.
  It yields `isOpen`, `open`, `close`, `toggle` and `setOpen`. A submenu's state works the same
  way, and as Radix's, a submenu closes (`@onOpenChange(false)`) when the menu it is in closes and
  when it goes away, so one your state holds open isn't open again the next time its menu opens.
  A checkbox item's (`@checked`, `@onCheckedChange`) and a radio group's (`@value`,
  `@onValueChange`) are yours, as Radix's are.
- **Items.** Selecting one (a click, Enter or Space, or a press on the trigger let go over it)
  calls `@onSelect` with a cancelable event, then closes the menu unless you prevented it. A
  disabled item can't be focused and the keys and typeahead pass over it; `@textValue` is the
  text typeahead matches. An item belongs to the menu content it is rendered in, so `m.Item`
  works in a submenu too.
- **Your own elements.** `{{m.trigger}}`, `{{m.item}}`, `{{m.checkboxItem}}`, `{{m.group}}`,
  `{{m.label}}`, `{{m.separator}}` and `{{m.arrow}}`; a radio group yields `{{g.item value=…}}`
  and a submenu `{{s.trigger}}`. Each part also takes `@as`.
- **Placement.** The content takes Radix's Popper arguments, with Radix's defaults: below the
  trigger, centred, touching it. A submenu goes beside its trigger on the side the text reads
  towards, aligned with its top. CSS anchor positioning places them where the browser has it,
  and Floating UI otherwise (see [Anchor](/primitives/anchor.md)).
- **Focus.** Opened from the keyboard, focus goes to the first item; by the pointer, to the
  content. Tab stays in the menu, and closing it brings focus back to the trigger.
- **The pointer.** An item takes focus when the pointer rests on it. A submenu opens 100ms after
  the pointer reaches its trigger, and on its way there the pointer may cross other items without
  closing it: Radix's grace area, the triangle from where it left the trigger to the submenu.
- **Modal.** By default, as Radix's, the menu is modal: the rest of the page ignores the pointer,
  is inert (see [`inertOthers`](/primitives/hide-others.md)) and doesn't scroll
  ([`scrollLock`](/primitives/scroll-lock.md)). `@modal={{false}}` leaves the page alone, and
  focus going outside then closes the menu.
- **Styles.** The contents are popovers in the top layer, so the browser's own popover styles
  apply: style over them. They get Radix's custom properties,
  `--radix-dropdown-menu-content-transform-origin`, `-available-width`, `-available-height`,
  and `--radix-dropdown-menu-trigger-width` and `-height`. Items get `data-highlighted` while
  focused, and `data-disabled`; checkbox and radio items, `data-state`.

## From ember-primitives

ember-primitives' `Menu` is this component: `import { Menu } from
'@ember-joinery/primitives/dropdown-menu'`. Its `Trigger` and `trigger` modifier take
`@stopPropagation` and `@preventDefault` for the click; its `Content` yields `Item` (with
`@onSelect`), `LinkItem` (with `@href`, `@includeActiveQueryParams` and `@activeOnSubPaths`) and
`Separator`; its root takes `@placement`, `@offsetOptions`, `@flipOptions`, `@shiftOptions`,
`@middleware` and `@strategy`; and it yields `arrow` and `isOpen`. Joinery's opens on a press
(the pointer going down) rather than a click, as Radix's does, moves between items with
ArrowUp and ArrowDown only (a vertical menu, where ember-primitives' tabster mover takes all four
arrows), and adds what Radix's has: checkbox and radio items, labels, groups, submenus and
typeahead.

## API

| Argument                                                                                    | Type                      | Default | What it does                                              |
| ------------------------------------------------------------------------------------------- | ------------------------- | ------- | --------------------------------------------------------- |
| `@open`                                                                                     | `boolean`                 |         | Whether it is open, controlled                            |
| `@defaultOpen`                                                                              | `boolean`                 | `false` | Whether it starts open                                    |
| `@onOpenChange`                                                                             | `(open: boolean) => void` |         | Called with each state the user asks for                  |
| `@modal`                                                                                    | `boolean`                 | `true`  | Keep the pointer and focus in the menu, the page inert    |
| `@dir`                                                                                      | `"ltr" \| "rtl"`          |         | The direction, for the arrow keys and submenus' side      |
| `@placement`, `@offsetOptions`, `@flipOptions`, `@shiftOptions`, `@middleware`, `@strategy` |                           |         | ember-primitives' positioning, for its Content            |
| `@name`                                                                                     | `string`                  |         | Its name, for `DropdownMenuHarness` (`data-test-jn-name`) |

It yields `{ Trigger, Content, Portal, Group, Label, Item, LinkItem, CheckboxItem, RadioGroup,
Separator, Sub, Arrow, trigger, item, checkboxItem, group, label, separator, arrow, menu, isOpen,
open, close, toggle, setOpen }`. The Content also takes `@loop`, `@forceMount`, `@as`, and
Radix's `@onCloseAutoFocus`, `@onEscapeKeyDown`, `@onPointerDownOutside`, `@onFocusOutside` and
`@onInteractOutside`. A styled layer makes its own item modifiers with `menuItemPart(m.menu,
look)` and `menuCheckboxItemPart(m.menu, look)`, as the styled Dropdown Menu does.

## Testing

```ts
import { DropdownMenuHarness } from '@ember-joinery/test-support'

const menu = new DropdownMenuHarness()
await menu.openWithKeyboard()
assert.strictEqual(menu.highlighted, 'Item 1')
```

The [Dropdown Menu](/components/dropdown-menu.md#testing) page lists its members.
