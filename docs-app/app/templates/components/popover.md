# Popover

Displays rich content in a portal, triggered by a button.

<Example @name="popover-demo" @title="Popover" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Popover } from '@ember-joinery/ember'
```

## Usage

`<Popover>` yields its parts. Upstream's `asChild` trigger is the yielded `trigger` modifier on
your own [Button](/components/button.md):

```gts
import { Button, Popover } from '@ember-joinery/ember'

<template>
  <Popover as |p|>
    <Button @variant="outline" {{p.trigger}}>Open Popover</Button>
    <p.Content>
      <p.Header>
        <p.Title>Title</p.Title>
        <p.Description>Description text here.</p.Description>
      </p.Header>
    </p.Content>
  </Popover>
</template>
```

Its state is its own, or yours: pass `@open` with `@onOpenChange` to control it, or
`@defaultOpen` to start it open.

## Composition

Use the following composition to build a `Popover`:

```text
Popover
├── p.Trigger (or {{p.trigger}} on your own element)
└── p.Content
```

## Basic

A simple popover with a header, title, and description.

<Example @name="popover-basic" @title="Basic" />

## Align

Use `@align` on `p.Content` to control the horizontal alignment.

<Example @name="popover-alignments" @title="Align" />

## With Form

A popover with form fields inside. Upstream's example, `popover-form`, comes with Field.

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)). `@side` is a physical side, as Radix's: `left` is on
the left in both directions, while `@align="start"` follows the text.

<Example @name="popover-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Popover

| Argument        | Type                      | Default | What it does                                                |
| --------------- | ------------------------- | ------- | ----------------------------------------------------------- |
| `@open`         | `boolean`                 |         | Whether it is open, controlled                              |
| `@defaultOpen`  | `boolean`                 | `false` | Whether it starts open, uncontrolled                        |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each state the user asks for                    |
| `@modal`        | `boolean`                 | `false` | Keep focus inside, and the pointer off the rest of the page |
| `@name`         | `string`                  |         | Its name, for `PopoverHarness` (`data-test-jn-name`)        |

It renders an element with `display: contents` and yields `{ Trigger, Anchor, Content, Header,
Title, Description, Close, Arrow, trigger, anchor, close, isOpen, open, toggle, setOpen }`. It
also takes ember-primitives' positioning arguments, which every Content of it uses: see
[the primitive](/primitives/popover.md).

### p.Content

| Argument                                                         | Type                                     | Default    | What it does                                          |
| ---------------------------------------------------------------- | ---------------------------------------- | ---------- | ----------------------------------------------------- |
| `@side`                                                          | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"` | The side of the trigger it goes on                    |
| `@align`                                                         | `"start" \| "center" \| "end"`           | `"center"` | Where along that side                                 |
| `@sideOffset`                                                    | `number`                                 | `4`        | Its distance from the trigger, in pixels              |
| `@alignOffset`                                                   | `number`                                 | `0`        | Its shift from the start or end, in pixels            |
| `@avoidCollisions`                                               | `boolean`                                | `true`     | Flip and shift to stay in view                        |
| `@collisionPadding`                                              | `number` or per side                     | `0`        | How far from the viewport's edges to stay             |
| `@sticky`                                                        | `"partial" \| "always"`                  | `partial`  | Whether it may shift off its trigger                  |
| `@hideWhenDetached`                                              | `boolean`                                | `false`    | Hide it while its trigger is scrolled out of view     |
| `@forceMount`                                                    | `boolean`                                | `false`    | Keep it rendered while closed, to animate it yourself |
| `@onOpenAutoFocus`                                               | `(event) => void`                        |            | Before focus moves in; `preventDefault()` to stop it  |
| `@onCloseAutoFocus`                                              | `(event) => void`                        |            | Before focus goes back; `preventDefault()` to stop it |
| `@onEscapeKeyDown`                                               | `(event) => void`                        |            | `preventDefault()` keeps it open                      |
| `@onPointerDownOutside`, `@onFocusOutside`, `@onInteractOutside` | `(event) => void`                        |            | `preventDefault()` keeps it open                      |
| `@as`                                                            | tag name                                 | `div`      | The tag to render                                     |

`p.Header` is a `<div>`, `p.Title` a `<div>` that names the content (its `aria-labelledby`) and
`p.Description` a `<p>` that describes it (its `aria-describedby`). `p.Trigger` is a `<button>`,
`p.Anchor` places the content against itself instead of the trigger, and `p.Close` (Radix's,
unstyled) closes it. Each takes `@as`.

### Data attributes

| Part                       | Attributes                                                                                                                                                                 |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root                       | `data-test-jn="popover"`, `data-test-jn-name`                                                                                                                              |
| trigger                    | `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls`, `data-state`, `data-test-jn-part="trigger"`                                                                    |
| content                    | `class="jn-popover-content"`, `data-slot="popover-content"`, `role="dialog"`, `data-state`, `data-side`, `data-align`, `data-test-jn-part="content"`, `data-test-jn-owner` |
| header, title, description | `class="jn-popover-header"` (`-title`, `-description`), `data-slot="popover-header"` (…)                                                                                   |

A Button of your own keeps its own `data-slot="button"`, as upstream's `asChild` does; the
Trigger part renders `data-slot="popover-trigger"`.

## Keyboard interactions

| Key              | What it does                                                      |
| ---------------- | ----------------------------------------------------------------- |
| `Space`, `Enter` | On the trigger, opens or closes it                                |
| `Tab`            | Moves to the next focusable element inside it, round to the first |
| `Shift` + `Tab`  | Moves to the previous one, round to the last                      |
| `Esc`            | Closes it, and moves focus back to the trigger                    |

## Accessibility

- The content has the `dialog` role, and is named by its Title, or else by its trigger; give it
  `aria-label` to name it yourself.
- Opening it moves focus to its first focusable element that isn't a link (or to the content),
  and closing it brings focus back to the trigger, unless the user pressed elsewhere.
- It is in the browser's top layer while open, so no ancestor's `overflow` clips it.
- A modal one (`@modal`) keeps focus in and the pointer off the rest of the page, and, as
  Radix's does, hides the rest of the page from screen readers and stops it scrolling until it
  closes.

## Testing

`PopoverHarness` from `@ember-joinery/test-support` drives a popover:

```ts
import { PopoverHarness } from '@ember-joinery/test-support'

const popover = new PopoverHarness()
await popover.open()
assert.strictEqual(popover.label, 'Dimensions')
await popover.pressEscape()
assert.false(popover.isOpen)
```

| Member                            | What it is                                            |
| --------------------------------- | ----------------------------------------------------- |
| `trigger`, `content`              | Its trigger, and its content (or `null` while closed) |
| `isOpen`                          | The trigger's `aria-expanded`                         |
| `isShown`                         | Whether the content is in the top layer               |
| `label`, `description`            | The content's accessible name and description         |
| `title`, `text`                   | The Title's text, and the content's                   |
| `side`, `align`                   | Where the content went, after any flip                |
| `arrow`                           | The arrow's element, or `null`                        |
| `open()`, `close()`, `toggle()`   | A click on the trigger                                |
| `clickClose()`                    | A click on its Close part                             |
| `pressEscape()`, `pressOutside()` | Escape, or a press outside it                         |

## Upstream

shadcn/ui's [Popover](https://ui.shadcn.com/docs/components/radix/popover), from
`apps/v4/registry/bases/radix/ui/popover.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Popover](https://www.radix-ui.com/docs/primitives/components/popover).
