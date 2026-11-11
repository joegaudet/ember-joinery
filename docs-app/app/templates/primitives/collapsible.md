# Collapsible

A trigger that shows and hides a panel: Radix's `Collapsible`, headless. It has no styles; the
styled [Collapsible](/components/collapsible.md) is the same with shadcn's `data-slot`s, and
each item of an [Accordion](/primitives/accordion.md) is one.

<Example @name="collapsible-headless" @title="A disclosure" @align="start" />

## Usage

```gts
import { Collapsible } from '@ember-joinery/primitives/collapsible'

<template>
  <Collapsible @defaultOpen={{true}} as |c|>
    <c.Trigger>Can I use this in my project?</c.Trigger>
    <c.Content>Yes. Free to use for personal and commercial projects.</c.Content>
  </Collapsible>
</template>
```

- **The trigger** is a `<button type="button">` with `aria-expanded` and `aria-controls`, or
  the yielded `c.trigger` modifier on an element of your own (a `<button>` without a `type`
  becomes `type="button"`).
- **The content** is always in the document, so `aria-controls` always names it: `hidden` and
  empty while closed. Closing, it stays shown until its exit animation, on
  `data-state="closed"`, ends (through [Presence](/primitives/presence.md)).
- **Its size** is measured into `--radix-collapsible-content-height` and `-width` each time it
  opens or closes, with its animation paused for the moment, so a keyframe can animate the
  height to or from it, as the example does. Content open from the start doesn't animate in,
  and isn't measured until it first changes, as in Radix.
- **State**: `@open` with `@onOpenChange` to control it, or `@defaultOpen` to start it open.
  `@disabled` disables the trigger.

`@forceMount={{true}}` on `c.Content` keeps it rendered and shown while closed, for animating it
yourself. Every part takes `@as` for another tag, and attributes.

### In a component

`CollapsibleState` is the behaviour, for a component that renders its own parts, as the styled
one does. Its `triggerSpec()` and `contentSpec({ shown })` are what the parts put on their
elements, so a component can add its own attributes in a `part()` of its own, and
`CollapsibleContent` renders the content with its presence, given the state and that part:

```ts
import { CollapsibleState } from '@ember-joinery/primitives/collapsible'
import { part } from '@ember-joinery/primitives/part'

class Disclosure extends Component {
  collapsible = new CollapsibleState({ open: () => this.args.open })
  trigger = part(() => {
    const spec = this.collapsible.triggerSpec()
    return { ...spec, attributes: { ...spec.attributes, 'data-slot': 'disclosure-trigger' } }
  })
}
```

## API

| Argument        | Type                      | Default | What it does                               |
| --------------- | ------------------------- | ------- | ------------------------------------------ |
| `@open`         | `boolean`                 |         | The controlled open state                  |
| `@defaultOpen`  | `boolean`                 | `false` | Whether it starts open, when uncontrolled  |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each new open state            |
| `@disabled`     | `boolean`                 | `false` | Whether the trigger can't open or close it |
| `@as`           | tag name                  | `div`   | The tag to render                          |
| `@name`         | `string`                  |         | Its name, for `CollapsibleHarness`         |

It yields `Trigger`, `Content`, `trigger` (the modifier), `isOpen` and `toggle`. Every part has
`data-state` (`open` or `closed`) and, while disabled, `data-disabled`.

## Testing

`CollapsibleHarness` drives it; see [Collapsible](/components/collapsible.md#testing).
