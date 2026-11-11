# Select

A button that opens a list of options, as Radix's `Select`: the trigger is a `combobox`, the
list a `listbox` in the browser's top layer, over the trigger with the chosen option on its
value (`item-aligned`) or anchored below it (`popper`). It has no styles; the styled
[Select](/components/select.md) is built on it.

<Example @name="select-headless" @title="A select of your own" />

## Usage

```gts
import { Select } from '@ember-joinery/primitives/select'

<template>
  <Select @defaultValue="apple" as |s|>
    <s.Trigger aria-label="Fruit">
      <s.Value @placeholder="Pick a fruit" />
      <s.Icon />
    </s.Trigger>
    <s.Content>
      <s.ScrollUpButton>▲</s.ScrollUpButton>
      <s.Viewport>
        <s.Group>
          <s.Label>Fruits</s.Label>
          <s.Item @value="apple" as |item|>
            <item.ItemText>Apple</item.ItemText>
            <item.ItemIndicator>✓</item.ItemIndicator>
          </s.Item>
        </s.Group>
        <s.Separator />
      </s.Viewport>
      <s.ScrollDownButton>▼</s.ScrollDownButton>
    </s.Content>
  </Select>
</template>
```

- **State.** `@value` with `@onValueChange`, or `@defaultValue`; `@open` with `@onOpenChange`,
  or `@defaultOpen`. It yields `value`, `isOpen`, `setOpen` and `setValue`.
- **The value.** `s.Value` shows the chosen option's `ItemText` (a copy of its nodes, kept up to
  date) or `@placeholder`. While the select is closed its options still render, off the page,
  as Radix renders them into a fragment, so the value and the trigger's typeahead know them.
- **Positions.** `@position="item-aligned"` (the default) places the list over its trigger, the
  chosen option's text on the value, as tall as fits 10px inside the viewport, as a native
  select's menu opens. `@position="popper"` anchors it with Radix's Popper arguments
  (`@side`, `@align` (`start`), `@sideOffset`, `@collisionPadding` (10)…) and sets Radix's
  custom properties, `--radix-select-trigger-width` and the rest. `s.Arrow` points at the
  trigger, with `popper` only.
- **Scrolling.** `s.Viewport` scrolls the options, with no scrollbar. The scroll buttons render
  while it can scroll their way; hovering one scrolls an option's height every 50ms.
- **Focus.** The trigger opens it on a mouse press (and a release over an option chooses it, as
  a native select's does), a touch's click, or Space, Enter and the arrows. Focus goes to the
  chosen option, stays in the list, and goes back to the trigger when it closes. Typing a
  letter on the closed trigger chooses the next option starting with it.
- **Modal.** While it is open the rest of the page is inert and doesn't scroll, and Escape, a
  press outside, the window losing focus or resizing close it.
- **Forms.** Inside a `<form>` (or with `@form`), a hidden native `<select>` named `@formName`
  carries the value, tells the form when it changes, and takes the browser's autofill.

## From Radix

Radix's parts are yielded under their names (`Trigger`, `Value`, `Icon`, `Content`,
`Viewport`, `Group`, `Label`, `Item`, `Separator`, `ScrollUpButton`, `ScrollDownButton`,
`Arrow`); an Item yields its `ItemText` and `ItemIndicator`. Radix's `name` is `@formName`,
and `@name` names it for `SelectHarness`. `Select.Portal` has no counterpart: the list is in
the top layer, with no portal.
