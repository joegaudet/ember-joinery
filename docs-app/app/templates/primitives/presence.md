# Presence

shadcn's styles animate parts in and out on `data-state`: `data-[state=closed]:animate-out`
fades a closing dialog. For that, the part has to stay in the page until its exit animation
ends. `Presence` keeps it there, as Radix's Presence does.

<Example @name="presence-fade" @title="Fade out, then go" />

## Usage

```gts
import { Presence } from '@ember-joinery/primitives/presence'

<template>
  <Presence @present={{this.isOpen}} as |presence|>
    <div {{presence.ref}} data-state={{if this.isOpen "open" "closed"}}>…</div>
  </Presence>
</template>
```

The content renders while `@present` is true. When it turns false, the part's `data-state`
becomes `closed`, and Presence looks at the element given `presence.ref`:

- if a new CSS animation started there (the exit animation), the content stays until it ends;
- if there is no animation, the same one as before, or the element is hidden, it goes at once.

Turning `@present` back on during the exit keeps the element. Without `presence.ref` there is
nothing to wait for, so the content goes at once.

`presence.ref` can go anywhere among the element's modifiers, before or after the part
modifier that sets its `data-state`: Presence looks for the exit animation once the render is
over, as Radix does after React commits.

```gts
<Presence @present={{this.open.value}} as |presence|>
  <div {{presence.ref}} {{this.content}}>…</div>
</Presence>
```

## API

| Argument      | Type      | What it does                                        |
| ------------- | --------- | --------------------------------------------------- |
| `@present`    | `boolean` | Whether the content should be shown                 |
| `@forceMount` | `boolean` | Keep it rendered regardless, to animate it yourself |

It yields `ref` (the modifier for the animated element) and `isPresent` (`@present`, so false
while the content is on its way out).

## Testing

Presence holds `settled()` until the content is gone, so a test that closes something and then
checks it is gone needs no timers: `await click(close)` returns after the exit animation.
