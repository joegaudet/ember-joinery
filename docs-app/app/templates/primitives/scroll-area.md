# Scroll Area

A scrollable area with scrollbars of its own drawing, as Radix's `ScrollArea` (which shadcn's
[Scroll Area](/components/scroll-area.md) wraps). The content scrolls natively, with the wheel,
touch and the keyboard; the browser's scrollbars are hidden, and the area's show when wanted.

<Example @name="scroll-area-headless" @title="A list with a scrollbar of its own" />

## Usage

```gts
import { ScrollArea } from '@ember-joinery/primitives/scroll-area'

<template>
  <ScrollArea @type="auto" class="h-48 w-56 overflow-hidden" as |s|>
    <s.Viewport class="size-full">…</s.Viewport>
    <s.Scrollbar class="flex w-2 p-px" as |bar|>
      <bar.Thumb class="flex-1 rounded-full bg-border" />
    </s.Scrollbar>
    <s.Scrollbar @orientation="horizontal" class="flex h-2 flex-col p-px" as |bar|>
      <bar.Thumb class="flex-1 rounded-full bg-border" />
    </s.Scrollbar>
    <s.Corner />
  </ScrollArea>
</template>
```

The parts are components of their own too (`ScrollAreaViewport`, `ScrollAreaScrollbar`,
`ScrollAreaThumb`, `ScrollAreaCorner`). They find their area through the DOM, so a scrollbar can
go anywhere inside it, even inside the viewport, and is still placed against the area.

The primitive has no styles of its own but what Radix sets: the area is `position: relative`,
the viewport scrolls the ways it has a scrollbar for (and hides the browser's), and each
scrollbar is placed along its edge, past the corner, on the side the text ends. Size the
scrollbars and their thumbs yourself; the thumb's length is `--radix-scroll-area-thumb-height`
(or `-width`), set on its scrollbar.

### When the scrollbars show

`@type` is Radix's: `hover` (the default) while the pointer is over the area, `scroll` while it
scrolls, `auto` whenever the content overflows, and `always`. Except with `always`, a scrollbar
shows only when the content overflows its way, and it goes `@scrollHideDelay` ms (600) after
the pointer leaves or the scrolling stops. A scrollbar with `@forceMount` stays rendered, with
`data-state="hidden"`, for CSS of your own.

### Scrolling

The thumb follows the scroll position and drags; a press on the track scrolls there, and the
wheel over a scrollbar scrolls the viewport (the page doesn't scroll while the viewport still
can). Right to left, the horizontal thumb starts on the right, as the scroll position does.

The viewport takes focus (`tabindex="0"`), so a keyboard can scroll it when nothing inside can
take focus; Chrome makes scrollers focusable the same way. Radix's viewport doesn't.

## API

| Part            | Arguments                                           |
| --------------- | --------------------------------------------------- |
| `<ScrollArea>`  | `@type`, `@scrollHideDelay`, `@dir`, `@as`, `@name` |
| `<s.Viewport>`  | `@as`                                               |
| `<s.Scrollbar>` | `@orientation` (`vertical`), `@forceMount`, `@as`   |
| `<bar.Thumb>`   | `@forceMount`, `@as`                                |
| `<s.Corner>`    | `@as`                                               |

`ScrollAreaState` is the engine the component uses, and `thumbSize`, `thumbOffset` and
`scrollFromPointer` its math, as Radix does it.

## Testing

`ScrollAreaHarness` drives it, as on [Scroll Area's page](/components/scroll-area.md#testing).

## Upstream

Radix's [Scroll Area](https://www.radix-ui.com/primitives/docs/components/scroll-area)
(`@radix-ui/react-scroll-area` 1.2.10, which radix-ui 1.4.3 uses).
