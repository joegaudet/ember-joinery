# Drawer

The headless part under Joinery's [Drawer](/components/drawer.md): vaul's Drawer (1.1.2, the
one shadcn's is built on), with no styles. It is a [Dialog](/primitives/dialog.md) with
gestures, and it covers ember-primitives' `Drawer` too.

<Example @name="drawer-headless" @title="A headless drawer" />

## Usage

```gts
import { Drawer } from '@ember-joinery/primitives/drawer'

<template>
  <Drawer @direction="bottom" as |d|>
    <d.Trigger>Move goal</d.Trigger>
    <d.Overlay class="overlay" />
    <d.Content class="panel">
      <d.Handle class="handle" />
      <d.Title>Move goal</d.Title>
      <d.Description>Set your daily activity goal.</d.Description>
      <d.Close>Done</d.Close>
    </d.Content>
  </Drawer>
</template>
```

Everything a [Dialog](/primitives/dialog.md) does, it does: the content is in the top layer,
Escape and a press on the overlay close it, focus moves in and goes back, and a modal one (the
default) makes the page inert and locks its scroll. Beside that, as vaul's:

- **A drag moves it.** A pointer that goes down on the content and moves along its axis drags
  it, and the overlay fades as it goes. Let go past `@closeThreshold` of its size (a quarter),
  or fast (over 0.4px a millisecond), and it closes; otherwise it springs back. Dragged the
  other way, it gives a little and springs back.
- **It lets content scroll.** A drawer from the top or bottom doesn't drag for half a second
  after it opens, while text is selected, from an element marked `data-vaul-no-drag` (or in
  one), or while a scrolling element under the pointer isn't scrolled to its top.
- **Snap points.** `@snapPoints` gives it places to rest (`[0.25, '355px', 1]`): a drag lets
  go at the nearest, a fast one goes to the next, and `d.Handle` moves to the next on a tap.
- **The page behind** scales back with `@shouldScaleBackground`, and a drawer opened from
  `d.Nested` steps this one back.
- **It isn't dismissible** with `@dismissible={{false}}`: nothing of its own closes it.

### Its CSS

The gestures set inline transforms through the CSSOM, which a strict Content Security Policy
allows. Its slides, and where it rests at its snap points, are vaul's own CSS, keyed on the
`data-vaul-*` attributes the parts render: Joinery's `joinery.css` ships it (with what right to
left needs), so import that, or write your own rules for those attributes. The example above
relies on it.

### Directions

`@direction` is `top`, `right`, `bottom` (the default) or `left`. Left and right are the inline
start and end, as Joinery's styled Drawer places them with `start-0` and `end-0`: right to left,
a `left` drawer is on the right, and it drags and slides as one on the right. Place yours with
logical properties (`inset-inline-start`) to match.

### Focus

When it opens, focus goes to the content itself (`tabindex="-1"`), not its first field, so a
phone's keyboard doesn't open over it; `@autoFocus={{true}}` focuses the first focusable
element instead, as a Dialog does. vaul leaves focus where it was, which Joinery's inert page
would strand.

### ember-primitives' Drawer

| ember-primitives                | Joinery                                                            |
| ------------------------------- | ------------------------------------------------------------------ |
| `<Drawer as \|d\|>`, `d.Drawer` | `<Drawer as \|d\|>`, `d.Content` (with `d.Overlay`)                |
| `d.open`, `d.close`, `d.isOpen` | `d.open`, `(fn d.setOpen false)`, `d.isOpen`                       |
| `@open`                         | `@open` with `@onOpenChange`, or `@defaultOpen`                    |
| `d.focusOnClose`                | Built in: focus goes back to the trigger, or to where it was       |
| `@onClose(returnValue)`         | `@onClose(returnValue)`, from a `<form method="dialog">` inside it |

## API

### Drawer

It takes a [Dialog](/primitives/dialog.md)'s arguments (`@open`, `@defaultOpen`,
`@onOpenChange`, `@modal`, `@onClose`, `@name`) and vaul's, listed with the styled
[Drawer](/components/drawer.md#api-reference)'s: `@direction`, `@dismissible`, `@snapPoints`,
`@activeSnapPoint` (with `@defaultActiveSnapPoint` and `@onActiveSnapPointChange`),
`@fadeFromIndex`, `@snapToSequentialPoint`, `@closeThreshold`, `@scrollLockTimeout`,
`@handleOnly`, `@shouldScaleBackground`, `@setBackgroundColorOnScale`, `@noBodyStyles`,
`@autoFocus`, `@repositionInputs`, `@fixed`, `@onDrag`, `@onRelease` and `@onAnimationEnd`.

It renders an element with `display: contents` and yields:

| Yield                                          | What it is                                                         |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| `Trigger`, `Overlay`, `Content`, `Title`, …    | A Dialog's parts; the content and overlay with vaul's attributes   |
| `Handle`                                       | vaul's Handle: a `<div>`, hidden from screen readers               |
| `Nested`                                       | A Drawer nested in this one                                        |
| `trigger`, `close`, `title`, `description`     | The parts' modifiers, for your own elements                        |
| `handle`                                       | The handle's modifier (`preventCycle=true` stops taps cycling)     |
| `isOpen`, `isModal`, `isDragging`, `direction` | Its state                                                          |
| `activeSnapPoint`, `setActiveSnapPoint`        | The snap point it rests at, and a function that moves it           |
| `open`, `toggle`, `setOpen`, `returnValue`     | As a Dialog's; `setOpen` closes it whether or not it's dismissible |

### Handle

| Argument        | Type      | Default | What it does                                 |
| --------------- | --------- | ------- | -------------------------------------------- |
| `@preventCycle` | `boolean` | `false` | A tap doesn't move it to the next snap point |

A tap on the handle moves it to the next snap point, and closes it after the last (if it is
dismissible). A double tap, or a long press, isn't a tap. With `@handleOnly`, a drag starts only
here.

### Not ported

vaul's `container` has nothing to do here: the content is in the top layer, not a portal. Its
iOS Safari workarounds (`disablePreventScroll`, `preventScrollRestoration`, and fixing `<body>`
in place while it is open) aren't ported either; the overlay's
[scroll lock](/primitives/scroll-lock.md) stops the page scrolling.

## Testing

`DrawerHarness` drives it, as the styled one: see [Drawer](/components/drawer.md#testing).
