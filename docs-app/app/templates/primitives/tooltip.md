# Tooltip

A popup that describes an element when it has keyboard focus or the pointer rests on it, as
Radix's `Tooltip`, with Radix's delay groups (`TooltipProvider`). It has no styles; the styled
[Tooltip](/components/tooltip.md) is built on it.

<Example @name="tooltip-headless" @title="Tooltips of your own, in a provider" />

## Usage

```gts
import { Tooltip, TooltipProvider } from '@ember-joinery/primitives/tooltip'

<template>
  <TooltipProvider @delayDuration={{400}}>
    <Tooltip as |t|>
      <t.Trigger class="my-button">Bold</t.Trigger>
      <t.Content @side="top" class="my-tooltip">
        Bold
        <t.Arrow />
      </t.Content>
    </Tooltip>
  </TooltipProvider>
</template>
```

- **Opening.** The pointer resting on the trigger opens it after its delay (`delayed-open`);
  focus opens it at once (`instant-open`). A touch doesn't open it.
- **Closing.** The pointer leaving for anywhere but the tooltip closes it (it can cross to the
  tooltip, through Radix's grace area, unless `@disableHoverableContent`), and so do blur, a
  press on the trigger, Escape, a press outside, a scroll that moves the trigger, and another
  tooltip opening.
- **Delay groups.** The tooltips in a `TooltipProvider` share its `@delayDuration`, and once
  one has opened, the next opens at once, until `@skipDelayDuration` after the last closed.
  Tooltips outside a provider share one group per app (and per test), with Radix's 700ms
  delay, or `@fallbackDelayDuration`.
- **Its description.** While open, the trigger's `aria-describedby` names the content, whose
  role is `tooltip`.
- **Placement and styles** are as a [Popover](/primitives/popover.md)'s, above the trigger by
  default, with `--radix-tooltip-content-transform-origin` and the rest.

## API

| Argument                                 | Type      | Default | What it does                                       |
| ---------------------------------------- | --------- | ------- | -------------------------------------------------- |
| `@open`, `@defaultOpen`, `@onOpenChange` |           |         | Its state, controlled or not                       |
| `@delayDuration`                         | `number`  |         | Its open delay, in ms; it wins over its provider's |
| `@fallbackDelayDuration`                 | `number`  | `700`   | The delay when neither it nor a provider sets one  |
| `@disableHoverableContent`               | `boolean` | `false` | Close as soon as the pointer leaves the trigger    |
| `@name`                                  | `string`  |         | Its name, for `TooltipHarness`                     |

It yields `{ Trigger, Content, Arrow, trigger, isOpen, state, setOpen }`. `TooltipProvider`
takes `@delayDuration` (700), `@skipDelayDuration` (300), `@disableHoverableContent` and `@as`,
and renders an element with `display: contents`.

## Testing

```ts
import { TooltipHarness } from '@ember-joinery/test-support'

const tooltip = new TooltipHarness()
await tooltip.hover() // waits out the delay
assert.strictEqual(tooltip.state, 'delayed-open')
```

The [Tooltip](/components/tooltip.md#testing) page lists its members.
