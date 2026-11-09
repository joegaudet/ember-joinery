# Collapsible

An interactive component which expands/collapses a panel.

<Example @name="collapsible-demo" @title="Collapsible" @align="start" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Collapsible } from '@ember-joinery/ember'
```

## Usage

```gts
<Collapsible as |c|>
  <c.Trigger>Can I use this in my project?</c.Trigger>
  <c.Content>
    Yes. Free to use for personal and commercial projects. No attribution required.
  </c.Content>
</Collapsible>
```

## Composition

Use the following composition to build a `Collapsible`:

```text
Collapsible
├── c.Trigger
└── c.Content
```

`c.Trigger` is a `<button type="button">`. To make your own element or component the trigger,
as upstream's `asChild` does, put the yielded `c.trigger` modifier on it:

```gts
<Collapsible as |c|>
  <Button @variant="ghost" @size="icon" {{c.trigger}}>…</Button>
  <c.Content>…</c.Content>
</Collapsible>
```

## Controlled State

Use `@open` and `@onOpenChange` to control the state.

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Collapsible } from '@ember-joinery/ember'

export default class Example extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  <template>
    <Collapsible @open={{this.open}} @onOpenChange={{this.setOpen}} as |c|>
      <c.Trigger>Toggle</c.Trigger>
      <c.Content>Content</c.Content>
    </Collapsible>
  </template>
}
```

Without `@open` it keeps its own state; `@defaultOpen={{true}}` starts it open.

## Basic

<Example @name="collapsible-basic" @title="Basic" @align="start" />

## Settings Panel

Use a trigger button to reveal additional settings. Upstream's example is a Card of Field and
Input controls; it comes with Field, which hasn't landed in Joinery yet.

## File Tree

Use nested collapsibles to build a file tree. In a conversation, this is the File Tree pattern.

<Example @name="collapsible-file-tree" @title="File Tree" />

Upstream's `renderItem` calls itself for a folder's items; in Ember, a small component renders
itself instead. Each folder's trigger is a [Button](/components/button.md), put on with the
yielded `c.trigger` modifier, and the [Tabs](/components/tabs.md) in the card's header have no
panels.

## RTL

Collapsible lays out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)): it has no styles of its own, so whatever you put in it
follows the direction.

<Example @name="collapsible-rtl" @title="RTL" @dir="rtl" @align="start" />

## API Reference

### Collapsible

| Argument        | Type                      | Default | What it does                                             |
| --------------- | ------------------------- | ------- | -------------------------------------------------------- |
| `@open`         | `boolean`                 |         | The controlled open state                                |
| `@defaultOpen`  | `boolean`                 | `false` | Whether it starts open, when uncontrolled                |
| `@onOpenChange` | `(open: boolean) => void` |         | Called with each new open state                          |
| `@disabled`     | `boolean`                 | `false` | Whether the trigger can't open or close it               |
| `@as`           | tag name                  | `div`   | The tag to render                                        |
| `@name`         | `string`                  |         | Its name, for `CollapsibleHarness` (`data-test-jn-name`) |

It yields:

| Yield     | What it is                                                     |
| --------- | -------------------------------------------------------------- |
| `Trigger` | The button that opens and closes it (`@as` for another tag)    |
| `Content` | What it shows and hides (`@as` for another tag, `@forceMount`) |
| `trigger` | The trigger, as a modifier on your own element or component    |
| `isOpen`  | Whether it is open                                             |
| `toggle`  | Opens or closes it                                             |

### Content

The content's element is always in the document, so the trigger's `aria-controls` always names
it. While closed it is `hidden` and empty; closing, it stays shown until an exit animation of
yours, on `data-state="closed"`, ends. Each time it opens or closes, its size is measured into
`--radix-collapsible-content-height` and `--radix-collapsible-content-width`, for an animation
to use. `@forceMount={{true}}` keeps it rendered and shown while closed, to animate it yourself
from `data-state`.

### Data attributes

| Part      | Attribute       | Value                                                            |
| --------- | --------------- | ---------------------------------------------------------------- |
| every one | `data-state`    | `open` or `closed`                                               |
| every one | `data-disabled` | present while `@disabled`                                        |
| root      | `data-slot`     | `collapsible`; `data-test-jn="collapsible"`, `data-test-jn-name` |
| trigger   | `data-slot`     | `collapsible-trigger`; `data-test-jn-part="trigger"`             |
| content   | `data-slot`     | `collapsible-content`; `data-test-jn-part="content"`             |

## Keyboard interactions

| Key              | What it does                    |
| ---------------- | ------------------------------- |
| `Tab`            | Moves focus to the trigger      |
| `Enter`, `Space` | Opens or closes the collapsible |

That is the [APG disclosure pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/),
which the trigger's native `<button>` has built in. With the modifier on another element,
choose one that keeps it.

## Accessibility

- The trigger has `aria-expanded` and `aria-controls`, naming the content.
- Closed content is `hidden`, so nothing in it takes focus or is read.
- An icon-only trigger needs a name: `aria-label`, or hidden text as in the example above.
- A `<button>` made the trigger with the modifier gets `type="button"` unless it has a type, so
  it never submits a form.

## Testing

`CollapsibleHarness` from `@ember-joinery/test-support` drives a `<Collapsible>`, styled or
headless:

```ts
import { CollapsibleHarness } from '@ember-joinery/test-support'

const order = new CollapsibleHarness('order') // <Collapsible @name="order">
await order.open()
assert.true(order.isOpen)
assert.strictEqual(order.text, '100 Market St, San Francisco')
```

| Member            | What it is                                              |
| ----------------- | ------------------------------------------------------- |
| `trigger`         | The trigger's element                                   |
| `content`         | The content's element (there, `hidden`, while closed)   |
| `isOpen`          | Whether it is open, from the trigger's `aria-expanded`  |
| `isShown`         | Whether the content shows: open, or still animating out |
| `isDisabled`      | Whether the trigger can't open or close it              |
| `label`           | The trigger's accessible name                           |
| `text`            | The content's text, `''` while closed                   |
| `controlsContent` | Whether the trigger's `aria-controls` names the content |
| `toggle()`        | Clicks the trigger                                      |
| `open()`          | Opens it, unless it is open                             |
| `close()`         | Closes it, unless it is closed                          |
| `focus()`         | Focuses the trigger                                     |

## Upstream

shadcn/ui's [Collapsible](https://ui.shadcn.com/docs/components/radix/collapsible), from
`apps/v4/registry/bases/radix/ui/collapsible.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
The behaviour is Radix's Collapsible; [the primitive](/primitives/collapsible.md) is the same
without its `data-slot`s.
