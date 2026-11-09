# Accordion

A stack of headings that each show and hide a section: Radix's `Accordion`, headless, which
also covers ember-primitives' (its items yield `isExpanded`, and its header yields the
trigger). It has no styles; the styled [Accordion](/components/accordion.md) is built on it.

<Example @name="accordion-headless" @title="Questions" @align="start" />

## Usage

```gts
import { Accordion } from '@ember-joinery/primitives/accordion'

<template>
  <Accordion @type="single" @collapsible={{true}} as |accordion|>
    <accordion.Item @value="accessible" as |item|>
      <item.Header as |header|>
        <header.Trigger>Is it accessible?</header.Trigger>
      </item.Header>
      <item.Content>Yes. It follows the WAI-ARIA accordion pattern.</item.Content>
    </accordion.Item>
  </Accordion>
</template>
```

- **`@type="single"`**: one item open at a time; the value is a string, `''` for none. Unless
  `@collapsible`, the open item can't be closed, and its trigger is `aria-disabled="true"`.
- **`@type="multiple"`**: any number open; the value is an array.
- **Each item** is a [Collapsible](/primitives/collapsible.md): `item.Header` (an `<h3>`, or
  `@as` the level that fits) holds `item.Trigger` (also yielded by the header, as `Trigger`),
  a button with `aria-expanded` and `aria-controls`; `item.Content` is a `region` labelled by
  it. The yielded `item.trigger` modifier makes your own element the trigger.
- **The keys**: the arrows along `@orientation` (up and down by default; left and right,
  swapped right to left, when horizontal) move between the triggers and wrap round; Home and
  End go to the ends. Disabled triggers are passed over. Every trigger is in the tab order.
- **State**: `@value` with `@onValueChange` to control it, or `@defaultValue`. `@disabled` on
  the accordion or an item disables it.
- **Animation**: each content's size is measured into `--radix-accordion-content-height` (and
  `--radix-collapsible-content-height`), as in Radix, for your keyframes.

Each part has `data-state` (`open` or `closed`), `data-orientation` and, while disabled,
`data-disabled`. Items yield `isOpen` (and `isExpanded`, by ember-primitives' name),
`isDisabled` and `toggle`; the accordion yields `value`.

### In a component

`AccordionState` is the accordion's behaviour (its value and keys), and `AccordionItemState`
an item's, with a modifier for each part (`item`, `header`, `trigger`, `content`) and their
specs (`triggerSpec()`, `contentSpec()`), for a component that renders its own parts, as the
styled one does.

## Testing

`AccordionHarness` drives it; see [Accordion](/components/accordion.md#testing).
