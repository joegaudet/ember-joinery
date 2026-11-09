# Popover

Rich content in a layer, opened by a button, as Radix's `Popover`: the content is in the
browser's top layer while open, placed against its trigger and flipped to stay in view, Escape
or a press outside closes it, and focus moves in and back. It covers ember-primitives'
`Popover` too. It has no styles; the styled [Popover](/components/popover.md) is built on it.

<Example @name="popover-headless" @title="A popover of your own" />

## Usage

```gts
import { Popover } from '@ember-joinery/primitives/popover'

<template>
  <Popover as |p|>
    <p.Trigger class="my-button">Details</p.Trigger>
    <p.Content @side="bottom" @align="start" @sideOffset={{4}} class="my-popover">
      <p.Title>Dimensions</p.Title>
      <p.Description>Set the dimensions for the layer.</p.Description>
      <p.Close>Done</p.Close>
      <p.Arrow />
    </p.Content>
  </Popover>
</template>
```

- **State.** Pass `@open` with `@onOpenChange` to control it, or start it with `@defaultOpen`.
  It yields `isOpen`, `open`, `toggle` and `setOpen`.
- **Your own elements.** Each part has a modifier: `{{p.trigger}}`, `{{p.anchor}}`,
  `{{p.close}}`, `{{p.title}}`, `{{p.description}}` and `{{p.arrow}}`.
- **Placement.** The content takes Radix's Popper arguments (`@side`, `@align`, `@sideOffset`,
  `@alignOffset`, `@avoidCollisions`, `@collisionPadding`, `@sticky`, `@hideWhenDetached`,
  `@arrowPadding`), with Radix's defaults: below, centred, touching the trigger. An Anchor
  places it against something else. CSS anchor positioning places it where the browser has it,
  and Floating UI otherwise (see [Anchor](/primitives/anchor.md)).
- **Focus.** Opening it moves focus to its first focusable element that isn't a link (or the
  content itself), Tab goes round inside it, and closing it brings focus back to the trigger,
  unless the user pressed elsewhere. `@modal` keeps focus inside and, until it closes, the
  pointer off the rest of the page, which is also hidden from assistive technology
  ([`hideOthers`](/primitives/hide-others.md)) and kept from scrolling
  ([`scrollLock`](/primitives/scroll-lock.md)), as Radix's is.
- **Its name.** The content has the `dialog` role, and is named by its Title, or else its
  trigger, and described by its Description.
- **Styles.** The content is a popover in the top layer, so the browser's own popover styles
  apply (a border, padding, `Canvas` colours, `overflow: auto`): style over them. It gets
  Radix's custom properties, `--radix-popover-content-transform-origin`,
  `--radix-popover-content-available-width` and `-height`, and `--radix-popover-trigger-width`
  and `-height`.
- **Animation.** It stays while a `data-state="closed"` animation runs (see
  [Presence](/primitives/presence.md)); `@forceMount` keeps it rendered while closed.

## From ember-primitives

ember-primitives' `Popover` positions content you render yourself:
`<Popover @placement="top" @offsetOptions={{8}} as |p|>` with `{{p.reference}}` on the button
and `<p.Content>` inside an `{{#if}}`. Joinery's takes the same arguments
(`@placement`, `@offsetOptions`, `@flipOptions`, `@shiftOptions`, `@middleware` and
`@strategy`, on the root or the Content), and yields `reference` (the anchor), `setReference`,
`arrow` and `data` (where the content went) under the same names. It also keeps the state, so
open it with its trigger (or `@open`) rather than an `{{#if}}`, and Content takes `@as`.

One default differs: ember-primitives flips with `elementContext: 'both'`, so the content also
flips when a scroll container clips its trigger. Joinery's flips as Radix's does, which the
browser's own anchor positioning can do; pass `@flipOptions={{hash elementContext="both"}}` for
ember-primitives' (Floating UI positions it then).

## API

| Argument                                                                                    | Type                      | Default | What it does                                         |
| ------------------------------------------------------------------------------------------- | ------------------------- | ------- | ---------------------------------------------------- |
| `@open`                                                                                     | `boolean`                 |         | Whether it is open, controlled                       |
| `@defaultOpen`                                                                              | `boolean`                 | `false` | Whether it starts open                               |
| `@onOpenChange`                                                                             | `(open: boolean) => void` |         | Called with each state the user asks for             |
| `@modal`                                                                                    | `boolean`                 | `false` | Keep focus inside; hide and lock the page behind     |
| `@placement`, `@offsetOptions`, `@flipOptions`, `@shiftOptions`, `@middleware`, `@strategy` |                           |         | ember-primitives' positioning, for its Content       |
| `@name`                                                                                     | `string`                  |         | Its name, for `PopoverHarness` (`data-test-jn-name`) |

It yields `{ Trigger, Anchor, Content, Close, Arrow, Title, Description, trigger, anchor,
close, title, description, arrow, reference, setReference, data, isOpen, isModal, open,
toggle, setOpen }`. The Content also takes `@forceMount`, `@as`, and Radix's
`@onOpenAutoFocus`, `@onCloseAutoFocus`, `@onEscapeKeyDown`, `@onPointerDownOutside`,
`@onFocusOutside` and `@onInteractOutside`; the Arrow takes `@width` and `@height` (10 and 5).

## Testing

```ts
import { PopoverHarness } from '@ember-joinery/test-support'

const popover = new PopoverHarness()
await popover.open()
assert.true(popover.isShown)
```

The [Popover](/components/popover.md#testing) page lists its members.
