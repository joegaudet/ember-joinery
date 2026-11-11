# Hover Card

A preview of what is behind a link, for sighted users with a pointer, as Radix's `HoverCard`.
It has no styles; the styled [Hover Card](/components/hover-card.md) is built on it.

<Example @name="hover-card-headless" @title="A hover card of your own" />

## Usage

```gts
import { HoverCard } from '@ember-joinery/primitives/hover-card'

<template>
  <HoverCard @openDelay={{200}} @closeDelay={{200}} as |h|>
    <h.Trigger href="https://ui.shadcn.com/">shadcn/ui</h.Trigger>
    <h.Content @side="top" class="my-card">…</h.Content>
  </HoverCard>
</template>
```

- **Opening and closing.** It opens once the pointer has rested on the trigger for
  `@openDelay` (or the trigger has had focus as long), and closes `@closeDelay` after the
  pointer has left both the trigger and the card (or focus left). Escape and a press outside
  close it at once. A touch doesn't open it.
- **Inside it.** Selecting text in it keeps it open, and its links and buttons are out of the
  tab order: it's for pointers, so what it shows must be behind its link too.
- **The trigger** is an `<a>`, as Radix's; `{{h.trigger}}` makes your own element the trigger.
- **Placement and styles** are as a [Popover](/primitives/popover.md)'s, below the trigger by
  default, with `--radix-hover-card-content-transform-origin` and the rest.

## API

| Argument                                 | Type     | Default | What it does                     |
| ---------------------------------------- | -------- | ------- | -------------------------------- |
| `@open`, `@defaultOpen`, `@onOpenChange` |          |         | Its state, controlled or not     |
| `@openDelay`                             | `number` | `700`   | How long before it opens, in ms  |
| `@closeDelay`                            | `number` | `300`   | How long before it closes, in ms |
| `@name`                                  | `string` |         | Its name, for `HoverCardHarness` |

It yields `{ Trigger, Content, Arrow, trigger, isOpen, setOpen }`.

## Testing

```ts
import { HoverCardHarness } from '@ember-joinery/test-support'

const card = new HoverCardHarness()
await card.focus()
assert.true(card.isOpen)
```

The [Hover Card](/components/hover-card.md#testing) page lists its members.
