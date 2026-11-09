# Tooltip

A popup that displays information related to an element when the element receives keyboard
focus or the mouse hovers over it.

<Example @name="tooltip-demo" @title="Tooltip" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Tooltip } from '@ember-joinery/ember'
```

Upstream asks you to put a `TooltipProvider` at the root of your app. Joinery's tooltips need
none: those outside a provider open at once, as in upstream's, and share their delays the same
way. Wrap a group of them in a `TooltipProvider` to give them a delay of their own:

```gts
import { TooltipProvider } from '@ember-joinery/ember'

<template>
  <TooltipProvider @delayDuration={{300}}>{{outlet}}</TooltipProvider>
</template>
```

## Usage

```gts
import { Button, Tooltip } from '@ember-joinery/ember'

<template>
  <Tooltip as |t|>
    <Button @variant="outline" {{t.trigger}}>Hover</Button>
    <t.Content>
      <p>Add to library</p>
    </t.Content>
  </Tooltip>
</template>
```

`t.Trigger` is a `<button>` of its own; the `trigger` modifier makes your own element or
component the trigger, as upstream's `asChild` does.

## Composition

Use the following composition to build a `Tooltip`:

```text
Tooltip
├── t.Trigger (or {{t.trigger}} on your own element)
└── t.Content
```

## Side

Use `@side` on `t.Content` to change the position of the tooltip.

<Example @name="tooltip-sides" @title="Side" />

## With Keyboard Shortcut

A tooltip showing an icon button's keyboard shortcut. Upstream's example, `tooltip-keyboard`,
comes with Kbd.

## Disabled Button

Show a tooltip on a disabled button by wrapping it with a span.

<Example @name="tooltip-disabled" @title="Disabled Button" />

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)). `@side` is a physical side, as Radix's: `left` is on
the left in both directions.

<Example @name="tooltip-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Tooltip

| Argument                   | Type                      | Default | What it does                                         |
| -------------------------- | ------------------------- | ------- | ---------------------------------------------------- |
| `@open`                    | `boolean`                 |         | Whether it is open, controlled                       |
| `@defaultOpen`             | `boolean`                 | `false` | Whether it starts open, uncontrolled                 |
| `@onOpenChange`            | `(open: boolean) => void` |         | Called with each state it asks for                   |
| `@delayDuration`           | `number`                  | `0`     | How long the pointer rests before it opens, in ms    |
| `@disableHoverableContent` | `boolean`                 | `false` | Close as soon as the pointer leaves the trigger      |
| `@name`                    | `string`                  |         | Its name, for `TooltipHarness` (`data-test-jn-name`) |

`@delayDuration` wins over its provider's. It renders an element with `display: contents` and
yields `{ Trigger, Content, trigger, isOpen, state, setOpen }`.

### t.Content

| Argument                                                                                | Type                                     | Default    | What it does                                                      |
| --------------------------------------------------------------------------------------- | ---------------------------------------- | ---------- | ----------------------------------------------------------------- |
| `@side`                                                                                 | `"top" \| "right" \| "bottom" \| "left"` | `"top"`    | The side of the trigger it goes on                                |
| `@align`                                                                                | `"start" \| "center" \| "end"`           | `"center"` | Where along that side                                             |
| `@sideOffset`                                                                           | `number`                                 | `0`        | Its distance from the trigger, past the arrow                     |
| `@alignOffset`, `@avoidCollisions`, `@collisionPadding`, `@sticky`, `@hideWhenDetached` |                                          |            | As on a [Popover's content](/components/popover.md#api-reference) |
| `@onEscapeKeyDown`, `@onPointerDownOutside`                                             | `(event) => void`                        |            | `preventDefault()` keeps it open                                  |
| `@forceMount`                                                                           | `boolean`                                | `false`    | Keep it rendered while closed                                     |

It draws its arrow itself, as upstream's.

### TooltipProvider

| Argument                   | Type      | Default | What it does                                            |
| -------------------------- | --------- | ------- | ------------------------------------------------------- |
| `@delayDuration`           | `number`  | `0`     | The open delay of the tooltips inside, in ms            |
| `@skipDelayDuration`       | `number`  | `300`   | How soon after one closes the next opens at once, in ms |
| `@disableHoverableContent` | `boolean` | `false` | For every tooltip inside                                |

### Data attributes

| Part    | Attributes                                                                                                                                                                  |
| ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| root    | `data-test-jn="tooltip"`, `data-test-jn-name`                                                                                                                               |
| trigger | `aria-describedby` (while open), `data-state`, `data-test-jn-part="trigger"`                                                                                                |
| content | `class="jn-tooltip-content"`, `data-slot="tooltip-content"`, `role="tooltip"`, `data-state`, `data-side`, `data-align`, `data-test-jn-part="content"`, `data-test-jn-owner` |
| arrow   | a `<span data-test-jn-part="arrow">` around `<svg class="jn-tooltip-arrow">`                                                                                                |

`data-state` is Radix's: `delayed-open` after the delay, `instant-open` at once (focus, or just
after another tooltip closed), or `closed`. The style sheets animate `delayed-open` only.

## Keyboard interactions

| Key              | What it does                           |
| ---------------- | -------------------------------------- |
| `Tab`            | Focusing the trigger opens it, at once |
| `Space`, `Enter` | Activating the trigger closes it       |
| `Esc`            | Closes it                              |

## Accessibility

- While open, the trigger's `aria-describedby` names the tooltip, whose role is `tooltip`, so
  a screen reader reads it after the trigger's name. Radix renders a hidden copy of the content
  for this; Joinery describes the trigger by the content itself.
- It doesn't take focus, and its content shouldn't be interactive: use a
  [Popover](/components/popover.md) for that.
- A disabled `<button>` gets no pointer or focus events, so put it in a `<span>` that is the
  trigger, as the Disabled Button example does.

## Testing

`TooltipHarness` from `@ember-joinery/test-support` drives a tooltip:

```ts
import { TooltipHarness } from '@ember-joinery/test-support'

const tooltip = new TooltipHarness()
await tooltip.hover()
assert.strictEqual(tooltip.description, 'Add to library')
await tooltip.unhover()
```

| Member                 | What it is                                                                 |
| ---------------------- | -------------------------------------------------------------------------- |
| `trigger`, `content`   | Its trigger, and its content (or `null` while closed)                      |
| `state`, `isOpen`      | The trigger's `data-state`, and whether that is open                       |
| `isShown`              | Whether the tooltip is in the top layer                                    |
| `description`          | The trigger's accessible description: what a screen reader reads           |
| `text`                 | The tooltip's text                                                         |
| `side`, `align`        | Where it went, after any flip                                              |
| `arrow`                | The arrow's element                                                        |
| `hover()`, `unhover()` | Rests the pointer on the trigger (waiting out the delay), or moves it away |
| `hoverContent()`       | Moves the pointer from the trigger onto the tooltip                        |
| `focus()`, `blur()`    | Focuses the trigger, or moves focus away                                   |
| `pressEscape()`        | Escape                                                                     |

## Upstream

shadcn/ui's [Tooltip](https://ui.shadcn.com/docs/components/radix/tooltip), from
`apps/v4/registry/bases/radix/ui/tooltip.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's [Tooltip](https://www.radix-ui.com/docs/primitives/components/tooltip).
