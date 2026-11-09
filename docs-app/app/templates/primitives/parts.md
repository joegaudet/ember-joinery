# Parts

Joinery's components yield their parts (`<d.Trigger>`, `<d.Content>`). Radix lets a part
render as your own element with `asChild`; Joinery has two ways to do that:

- **`@as`** renders the part as another tag: `<d.Trigger @as="span">`.
- **A part modifier** makes any element or component the part: `<LinkTo {{d.trigger}}>`.
  Each component yields one for each part you might want to render yourself.

<Example @name="as-part" @title="One part, two elements" />

## `@as`

Every part takes `@as`, a tag name. Inside a component, `As` does the swap:

```gts
import { As } from '@ember-joinery/primitives/as'

<template>
  <As @as={{@as}} @tag="button" ...attributes {{@part}}>{{yield}}</As>
</template>
```

It renders `@as`, or else `@tag`, with the attributes, modifiers and block it is given. It uses
Ember's built-in `element` helper on Ember 7.1 and later, and works the same on 6.12.

## Part modifiers

`part()` makes a modifier that turns an element into one of a component's parts: it sets the
part's attributes (its ARIA, `data-state`, `data-slot`, `data-test-jn-part`), adds its classes,
listens for its events, and keeps them current as the component's state changes.

```gts
import { part } from '@ember-joinery/primitives/part'

class Collapsible extends Component {
  open = controllable(this, 'open', false)

  trigger = part(() => ({
    attributes: {
      'aria-expanded': String(this.open.value),
      'data-state': this.open.value ? 'open' : 'closed',
      'data-test-jn-part': 'trigger',
    },
    on: { click: () => this.open.set(open => !open) },
  }))

  <template>
    {{yield (hash Trigger=(component Trigger part=this.trigger) trigger=this.trigger)}}
  </template>
}
```

Then the caller picks the element:

```gts
<Collapsible as |c|>
  <c.Trigger>Details</c.Trigger>                 {{! the part's own button }}
  <LinkTo @route="details" {{c.trigger}}>Details</LinkTo>  {{! or any element }}
</Collapsible>
```

How a part meets the element's own attributes:

- The part's attributes win, except `class`, which adds to the element's classes. An attribute
  the part stops setting goes back to the element's own value.
- On events, listeners that come before the part modifier run first (put `...attributes`
  before it), and can stop the part's by calling `event.preventDefault()`, as in Radix.
- A part can take arguments, such as an item's value: `part((named) => …)` for
  `<a {{m.item value="profile"}}>`.
- `element: (element) => cleanup` in the spec is called once with the element, to keep it for
  focus or positioning.

## Testing

A part rendered either way carries the same `data-test-jn-part`, so the component's harness
finds it either way.
