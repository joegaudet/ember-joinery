# Scroller

A scrollable element that yields functions to scroll it to any edge: up, down, left or right.
Use it to follow content as it comes in (a log, a chat), or to jump to either end. It is
ember-primitives' `Scroller`.

<Example @name="scroller-demo" @title="Scrolling to each edge" />

## Usage

```gts
import { Scroller } from '@ember-joinery/primitives/scroller'

<template>
  <Scroller class="log" as |s|>
    {{#each this.lines as |line|}}
      <p>{{line}}</p>
      {{! each line that renders scrolls the log to the bottom }}
      {{(s.scrollToBottom)}}
    {{/each}}
  </Scroller>
</template>
```

The Scroller is the element that scrolls: give it a height (or a width) for its content to
overflow. It has `overflow: auto`, in `@layer joinery` at no specificity, so your CSS wins (in
CSS layers of your own, once `joinery` comes before them: see
[layout rules](/primitives/index.md#layout-rules-and-your-css-layers)), and `tabindex="0"`, so a
keyboard can scroll it.

Each function scrolls in the next animation frame, once what's rendering is in; a later call in
the same frame replaces it. Call one from a template where new content renders, or from an
action (`{{on "click" s.scrollToTop}}`). The scroll's `behavior` is `auto`, so your CSS decides
how it moves: `scroll-behavior: smooth`, as the example has.

## API

| Argument | Type     | What it does              |
| -------- | -------- | ------------------------- |
| `@name`  | `string` | Its name, for its harness |

| Yielded          | What it does                                                               |
| ---------------- | -------------------------------------------------------------------------- |
| `scrollToTop`    | Scrolls to the top                                                         |
| `scrollToBottom` | Scrolls to the bottom                                                      |
| `scrollToLeft`   | Scrolls to the left edge                                                   |
| `scrollToRight`  | Scrolls to the right edge                                                  |
| `scrollToStart`  | Scrolls to where lines of text start: the left, or the right right to left |
| `scrollToEnd`    | Scrolls to where lines of text end: the right, or the left right to left   |

Attributes go on the scrolling `<div>` (`data-jn-scroller`).

### From ember-primitives

The same component, with three differences. Left and right are the sides they name in
right-to-left text too (ember-primitives' `scrollToLeft` goes to the start, which is the right
there), and `scrollToStart` and `scrollToEnd` follow the text's direction. It has the
`overflow: auto` that ember-primitives' docs describe. And it holds a test waiter until each
scroll ends, smooth ones included, so a test needs no timeouts.

## Accessibility

A region that scrolls needs to be reachable from the keyboard ([axe: Scrollable region must
have keyboard access](https://dequeuniversity.com/rules/axe/4.10/scrollable-region-focusable)),
so the Scroller is in the tab order. Give it an `aria-label` if what it holds needs a name.

## Testing

`ScrollerHarness` reads where it is scrolled to and scrolls it as a user would. A Scroller wraps
your content, so it is a wrapper for the harnesses (`data-test-jn-wrapper`): a part inside it
still belongs to the component around it.

```ts
import { ScrollerHarness } from '@ember-joinery/test-support'

const log = new ScrollerHarness('log') // <Scroller @name="log">
log.position // { top, left }
log.range // how far it can scroll: { top, left }
log.isAtBottom // also isAtTop, isAtLeft, isAtRight
log.isFocusable
await log.scrollTo({ top: 0 })
await log.focus()
```
