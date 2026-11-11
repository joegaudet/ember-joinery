# Scroll Lock

Stops the page scrolling behind an overlay, as Radix's modal parts do with react-remove-scroll.
A modal [Dialog](/primitives/dialog.md)'s overlay locks it while it is open.

<Example @name="scroll-lock-panel" @title="A panel that locks the page" />

## Usage

```gts
import { scrollLock } from '@ember-joinery/primitives/scroll-lock'

<template>
  {{#if this.open}}
    <div class="overlay" {{scrollLock inside=this.shards}}></div>
  {{/if}}
</template>
```

While the element is rendered:

- **The scrollbar goes**, and the page keeps its place: `<body>` gets `overflow: hidden` and a
  right margin as wide as the scrollbar was, so nothing behind the overlay moves sideways.
- **A wheel or a finger does nothing**, except over the element itself and the ones given as
  `inside`, such as a dialog's content, which scroll as far as their ends and no further, so the
  page behind never takes the scroll over.
- **A pinch still zooms**, unless `allowPinchZoom=false`.

`inside` is a list of elements, or a function that returns them, read on each scroll, for
elements that render after the lock starts. `enabled=false` lifts the lock without removing the
element.

Locks stack: the newest one decides what scrolls, and the page scrolls again when the last one
ends. From your own code:

```ts
import { lockScroll, isScrollLocked } from '@ember-joinery/primitives/scroll-lock'

const lock = lockScroll(document, { inside: [panel] })
isScrollLocked() // true
lock.release()
```

## API

| Argument         | Type                              | Default | What it does                              |
| ---------------- | --------------------------------- | ------- | ----------------------------------------- |
| `inside`         | `Element[]`, or `() => Element[]` |         | Elements that keep their own scrolling    |
| `allowPinchZoom` | `boolean`                         | `true`  | Let a pinch zoom the page                 |
| `enabled`        | `boolean`                         | `true`  | The modifier only: `false` lifts the lock |

While the page is locked, `<body>` has `data-scroll-locked` (how many locks hold it) and
`--removed-body-scroll-bar-size`, the width of the scrollbar it took away: give a fixed element
of your own that much more right margin to keep it in place.

## Accessibility

Locking the scroll is for content that covers the page, such as a modal dialog: keep anything
inside it that's taller than its box scrollable, and give a scrolling region that holds nothing
focusable `tabindex="0"`, so a keyboard can scroll it too.

## Testing

`isScrollLocked()` says whether a lock holds the page. A wheel turned over an element shows
whether it scrolls:

```ts
const wheel = new WheelEvent('wheel', { deltaY: 100, bubbles: true, cancelable: true })
outside.dispatchEvent(wheel)
assert.true(wheel.defaultPrevented)
```
