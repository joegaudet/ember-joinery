# Scroll Area

Augments native scroll functionality for custom, cross-browser styling.

<Example @name="scroll-area-demo" @title="Scroll Area" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { ScrollArea, ScrollBar } from '@ember-joinery/ember'
```

## Usage

```gts
<ScrollArea class="h-[200px] w-[350px] rounded-md border p-4">
  Your scrollable content here.
</ScrollArea>
```

The content scrolls natively, with the wheel, touch and the keyboard; the area hides the
browser's scrollbar and draws its own, which shows while the pointer is over it. It is built
on Joinery's [`ScrollArea` primitive](/primitives/scroll-area.md), Radix's.

## Composition

Use the following composition to build a `ScrollArea`:

```text
ScrollArea
└── ScrollBar
```

The area draws a vertical `ScrollBar` itself. Put one with `@orientation="horizontal"` inside
it to scroll across too.

## Horizontal

Use `ScrollBar` with `@orientation="horizontal"` for horizontal scrolling.

<Example @name="scroll-area-horizontal-demo" @title="Horizontal" />

## RTL

To enable RTL support, see the [Direction](/components/direction.md) guide. Joinery's styles use
logical properties, so an area lays itself out right to left inside any element with
`dir="rtl"`, or with `@dir="rtl"`: the scrollbar moves to the left, with its border on its
inline start, and a horizontal one starts on the right.

<Example @name="scroll-area-rtl" @title="RTL" @dir="rtl" />

## API Reference

Upstream points to Radix's Scroll Area documentation; Joinery's takes its props as arguments.

### ScrollArea

| Argument           | Type                                        | Default        | What it does                                                                                                        |
| ------------------ | ------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------- |
| `@type`            | `"hover" \| "scroll" \| "auto" \| "always"` | `"hover"`      | When the scrollbars show: while the pointer is over it, while it scrolls, whenever the content overflows, or always |
| `@scrollHideDelay` | `number`                                    | `600`          | How long, in ms, a scrollbar stays after the pointer leaves or the scrolling stops                                  |
| `@dir`             | `"ltr" \| "rtl"`                            | the document's | The text direction, when the document's shouldn't decide                                                            |
| `@as`              | tag name                                    | `div`          | The tag to render                                                                                                   |
| `@name`            | `string`                                    |                | Its name, for `ScrollAreaHarness` (`data-test-jn-name`)                                                             |

Except with `always`, a scrollbar shows only when the content overflows its way.

### ScrollBar

| Argument       | Type                         | Default      | What it does                                       |
| -------------- | ---------------------------- | ------------ | -------------------------------------------------- |
| `@orientation` | `"vertical" \| "horizontal"` | `"vertical"` | Which way it scrolls                               |
| `@forceMount`  | `boolean`                    | `false`      | Keep it rendered while hidden, for CSS of your own |

It can go anywhere inside its `ScrollArea`: it finds the area through the DOM.

### Data attributes

| Part      | Attribute                                 | Value                                                                   |
| --------- | ----------------------------------------- | ----------------------------------------------------------------------- |
| area      | `class`, `data-slot`                      | `jn-scroll-area`, `scroll-area`                                         |
| area      | `data-test-jn`, `data-test-jn-name`       | `scroll-area`, its `@name`                                              |
| viewport  | `class`, `data-slot`                      | `jn-scroll-area-viewport`, `scroll-area-viewport`                       |
| scrollbar | `class`, `data-slot`, `data-orientation`  | `jn-scroll-area-scrollbar`, `scroll-area-scrollbar`, its `@orientation` |
| scrollbar | `data-state`                              | `visible` or `hidden`                                                   |
| thumb     | `class`, `data-slot`, `data-state`        | `jn-scroll-area-thumb`, `scroll-area-thumb`, `visible` or `hidden`      |
| parts     | `data-test-jn-part`, `data-test-jn-value` | `viewport`, `scrollbar` and `thumb` (with their orientation), `corner`  |

As in Radix, the scrollbar carries `--radix-scroll-area-thumb-height` (or `-width`), and the
area `--radix-scroll-area-corner-width` and `-height`.

## Keyboard interactions

The viewport scrolls as any scroller does: the arrow keys, Page Up and Page Down, Home and End,
and Space, once it (or something in it) has focus.

| Key   | What it does                                                    |
| ----- | --------------------------------------------------------------- |
| `Tab` | Moves focus to the viewport, when nothing inside it takes focus |

## Accessibility

- The viewport takes focus (`tabindex="0"`), so a keyboard can scroll it when nothing inside
  can take focus, as Chrome does for any scroller. Radix's doesn't; give it a `tabindex` of
  your own to change that.
- The scrollbars are for pointers, as Radix's are: they have no role and take no focus, and
  the viewport keeps native scrolling for everything else, assistive technology included.

## Testing

`ScrollAreaHarness` from `@ember-joinery/test-support` drives an area, from this package or the
primitive:

```ts
import { ScrollAreaHarness } from '@ember-joinery/test-support'

const tags = new ScrollAreaHarness('tags') // <ScrollArea @name="tags">
await tags.hover()
assert.true(tags.isScrollbarVisible())
await tags.scrollTo({ top: 200 })
```

| Member                                                     | What it is                                             |
| ---------------------------------------------------------- | ------------------------------------------------------ |
| `viewport`                                                 | The element that scrolls                               |
| `scrollbar(orientation)`, `thumb(orientation)`, `corner`   | The parts, or `null` while hidden                      |
| `isScrollbarVisible(orientation)`                          | Whether a scrollbar shows                              |
| `scrollTop`, `scrollLeft`, `maxScrollTop`, `maxScrollLeft` | Where it is scrolled, and how far it can go            |
| `thumbOffset(orientation)`, `thumbLength(orientation)`     | Where the thumb is along its track, and its length     |
| `hover()`, `unhover()`                                     | The pointer over the area, and away                    |
| `scrollTo({ top, left })`                                  | Scrolls the viewport, and waits for its `scroll` event |
| `dragThumb(orientation, distance)`                         | Drags a thumb (CSS pixels)                             |
| `pressTrack(orientation, fraction)`                        | Presses a scrollbar's track                            |
| `wheel(orientation, delta)`                                | Turns the wheel over a scrollbar                       |

## Upstream

shadcn/ui's [Scroll Area](https://ui.shadcn.com/docs/components/radix/scroll-area), from
`apps/v4/registry/bases/radix/ui/scroll-area.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
