# Hover Card

For sighted users to preview content available behind a link.

<Example @name="hover-card-demo" @title="Hover Card" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { HoverCard } from '@ember-joinery/ember'
```

## Usage

```gts
import { HoverCard } from '@ember-joinery/ember'

<template>
  <HoverCard as |h|>
    <h.Trigger href="https://nextjs.org">Hover</h.Trigger>
    <h.Content>
      The React Framework – created and maintained by @vercel.
    </h.Content>
  </HoverCard>
</template>
```

`h.Trigger` is an `<a>`, as Radix's; the `trigger` modifier makes your own element or
component the trigger, as upstream's `asChild` does (`<Button @variant="link" {{h.trigger}}>`).

## Composition

Use the following composition to build a `HoverCard`:

```text
HoverCard
├── h.Trigger (or {{h.trigger}} on your own element)
└── h.Content
```

## Trigger Delays

Use `@openDelay` and `@closeDelay` on the `HoverCard` to control when the card opens and
closes.

```gts
<HoverCard @openDelay={{100}} @closeDelay={{200}} as |h|>
  <h.Trigger href="#">Hover</h.Trigger>
  <h.Content>Content</h.Content>
</HoverCard>
```

## Positioning

Use `@side` and `@align` on `h.Content` to control placement.

```gts
<HoverCard as |h|>
  <h.Trigger href="#">Hover</h.Trigger>
  <h.Content @side="top" @align="start">
    Content
  </h.Content>
</HoverCard>
```

## Basic

<Example @name="hover-card-demo" @title="Basic" />

## Sides

<Example @name="hover-card-sides" @title="Sides" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)). `@side` is a physical side, as Radix's: `left` is on
the left in both directions.

<Example @name="hover-card-rtl" @title="RTL" @dir="rtl" />

## API Reference

### HoverCard

| Argument        | Type                      | Default | What it does                                                             |
| --------------- | ------------------------- | ------- | ------------------------------------------------------------------------ |
| `@open`         | `boolean`                 |         | Whether it is open, controlled                                           |
| `@defaultOpen`  | `boolean`                 | `false` | Whether it starts open, uncontrolled                                     |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each state it asks for                                       |
| `@openDelay`    | `number`                  | `700`   | How long the pointer rests on the trigger (or it has focus) first, in ms |
| `@closeDelay`   | `number`                  | `300`   | How long after the pointer leaves it closes, in ms                       |
| `@name`         | `string`                  |         | Its name, for `HoverCardHarness` (`data-test-jn-name`)                   |

It renders an element with `display: contents` and yields `{ Trigger, Content, Arrow, trigger,
isOpen, setOpen }`.

### h.Content

| Argument                                                                                               | Type                                     | Default    | What it does                                                      |
| ------------------------------------------------------------------------------------------------------ | ---------------------------------------- | ---------- | ----------------------------------------------------------------- |
| `@side`                                                                                                | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"` | The side of the trigger it goes on                                |
| `@align`                                                                                               | `"start" \| "center" \| "end"`           | `"center"` | Where along that side                                             |
| `@sideOffset`                                                                                          | `number`                                 | `4`        | Its distance from the trigger                                     |
| `@alignOffset`, `@avoidCollisions`, `@collisionPadding`, `@sticky`, `@hideWhenDetached`, `@forceMount` |                                          |            | As on a [Popover's content](/components/popover.md#api-reference) |
| `@onEscapeKeyDown`, `@onPointerDownOutside`, `@onFocusOutside`, `@onInteractOutside`                   | `(event) => void`                        |            | `preventDefault()` keeps it open                                  |

### Data attributes

| Part    | Attributes                                                                                                                                                      |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root    | `data-test-jn="hover-card"`, `data-test-jn-name`                                                                                                                |
| trigger | `data-state`, `data-test-jn-part="trigger"`; the Trigger part also `data-slot="hover-card-trigger"`                                                             |
| content | `class="jn-hover-card-content"`, `data-slot="hover-card-content"`, `data-state`, `data-side`, `data-align`, `data-test-jn-part="content"`, `data-test-jn-owner` |

## Keyboard interactions

| Key   | What it does                                      |
| ----- | ------------------------------------------------- |
| `Tab` | Focusing the trigger opens it, after `@openDelay` |
| `Esc` | Closes it                                         |

## Accessibility

- A hover card is for sighted users with a pointer: what it shows must also be behind its
  link. Its links and buttons are taken out of the tab order, and a touch doesn't open it.
- Focusing the trigger opens it too, so keyboard users see the preview.
- Selecting text in it keeps it open.

## Testing

`HoverCardHarness` from `@ember-joinery/test-support` drives a hover card:

```ts
import { HoverCardHarness } from '@ember-joinery/test-support'

const card = new HoverCardHarness()
await card.hover() // waits out the open delay
assert.true(card.isOpen)
await card.unhover() // and the close delay
```

| Member                               | What it is                                                |
| ------------------------------------ | --------------------------------------------------------- |
| `trigger`, `content`                 | Its trigger, and the card (or `null` while closed)        |
| `isOpen`, `isShown`                  | The trigger's `data-state`, and whether the card is shown |
| `text`, `side`, `align`              | The card's text, and where it went                        |
| `hover()`, `unhover()`               | The pointer resting on the trigger, or leaving it         |
| `hoverContent()`, `unhoverContent()` | The pointer moving onto the card, or off it               |
| `focus()`, `blur()`                  | Focus on the trigger, or away from it                     |
| `pressEscape()`, `pressOutside()`    | Escape, or a press outside                                |

## Upstream

shadcn/ui's [Hover Card](https://ui.shadcn.com/docs/components/radix/hover-card), from
`apps/v4/registry/bases/radix/ui/hover-card.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Hover Card](https://www.radix-ui.com/docs/primitives/components/hover-card).
