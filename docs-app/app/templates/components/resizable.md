# Resizable

Accessible resizable panel groups and layouts with keyboard support.

<Example @name="resizable-demo" @title="Resizable" />

## About

Upstream's `Resizable` is built on top of
[react-resizable-panels](https://github.com/bvaughn/react-resizable-panels) by
[bvaughn](https://github.com/bvaughn). Joinery's is built on its own
[`Resizable` primitive](/primitives/resizable.md), which follows react-resizable-panels' API
(v4, the version upstream uses) and covers ember-primitives' `Resizable`.

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<ResizablePanelGroup @orientation="horizontal">
  <ResizablePanel>One</ResizablePanel>
  <ResizableHandle />
  <ResizablePanel>Two</ResizablePanel>
</ResizablePanelGroup>
```

Panels and handles are the group's children, in order: the handle between two panels resizes
them. A panel's sizes are percentages (`@defaultSize="50%"`, or `"50"`), other units (`"200px"`,
`"10rem"`, `"2em"`, `"50vh"`, `"50vw"`), or a number of pixels (`@defaultSize={{200}}`), as in
react-resizable-panels. Panels without a size share the space that is left.

The group fills its container (`h-full w-full`), so a stacked (`vertical`) group needs a
container with a height, or a height of its own (`class="min-h-[200px]"`).

## Composition

Use the following composition to build a `ResizablePanelGroup`:

```text
ResizablePanelGroup
├── ResizablePanel
├── ResizableHandle
└── ResizablePanel
```

The group also yields its parts (`<g.Panel>`, `<g.Handle>`), its layout (`g.layout`), and the
parts as modifiers for elements of your own (`<section {{g.panel defaultSize="30%"}}>`).

## Vertical

Use `@orientation="vertical"` for vertical resizing.

<Example @name="resizable-vertical" @title="Vertical" />

## Handle

Use the `@withHandle` argument on `ResizableHandle` to show a visible handle.

<Example @name="resizable-handle" @title="Handle" />

## RTL

Joinery's styles use logical properties, so a group lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/components/direction.md)): the first panel is on the
right, and the arrow keys and the pointer follow (Left moves a handle left).

<Example @name="resizable-rtl" @title="RTL" @dir="rtl" />

## Collapsible panels and saved layouts

These come from react-resizable-panels, which upstream's API Reference points to. A
`@collapsible` panel collapses when it is resized past its `@minSize` (by half the distance to
its collapsed size, or `@collapsedThreshold`), and Enter on its handle collapses or expands it.
To keep a layout between visits, save the sizes `@onLayoutChanged` gives and pass them back as
`@defaultLayout`:

```gts
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@ember-joinery/ember'

<template>
  <ResizablePanelGroup @defaultLayout={{this.saved}} @onLayoutChanged={{this.save}}>
    <ResizablePanel @id="nav" @minSize="15%" @collapsible={{true}} as |panel|>
      <button type="button" {{on "click" panel.collapse}}>Hide</button>
    </ResizablePanel>
    <ResizableHandle aria-label="Resize the navigation" />
    <ResizablePanel @id="main">…</ResizablePanel>
  </ResizablePanelGroup>
</template>
```

The [primitive's page](/primitives/resizable.md) has a live one.

## API Reference

Upstream points to react-resizable-panels' documentation. Joinery takes the same props as
arguments, with Ember's names for its callbacks and refs.

### ResizablePanelGroup

| Argument           | Type                                             | Default        | What it does                                             |
| ------------------ | ------------------------------------------------ | -------------- | -------------------------------------------------------- |
| `@orientation`     | `"horizontal" \| "vertical"`                     | `"horizontal"` | Panels side by side, or stacked                          |
| `@defaultLayout`   | `number[]` or `{ [id]: number }`                 |                | The first sizes in percent, in order or by panel `@id`   |
| `@onLayoutChange`  | `(sizes, layout) => void`                        |                | Called while the layout changes, on every pointer move   |
| `@onLayoutChanged` | `(sizes, layout, { isUserInteraction }) => void` |                | Called once a change is over: to save the layout         |
| `@disabled`        | `boolean`                                        | `false`        | Nothing in the group resizes                             |
| `@disableCursor`   | `boolean`                                        | `false`        | No resize cursor over the handles, or while dragging     |
| `@dir`             | `"ltr" \| "rtl"`                                 | the document's | The text direction, when the document's shouldn't decide |
| `@as`              | tag name                                         | `div`          | The tag to render                                        |
| `@name`            | `string`                                         |                | Its name, for `ResizableHarness` (`data-test-jn-name`)   |

It yields `Panel`, `Handle`, `panel` and `handle` (modifiers), `layout` (the sizes in order),
`getLayout()` (by id) and `setLayout(layout)`: react-resizable-panels' `groupRef`.

### ResizablePanel

| Argument               | Type                                                 | Default                    | What it does                                         |
| ---------------------- | ---------------------------------------------------- | -------------------------- | ---------------------------------------------------- |
| `@defaultSize`         | size                                                 | a share of what is left    | Its first size                                       |
| `@minSize`             | size                                                 | `0%`                       | The smallest it can be                               |
| `@maxSize`             | size                                                 | `100%`                     | The largest it can be                                |
| `@collapsible`         | `boolean`                                            | `false`                    | It collapses when resized past its minimum           |
| `@collapsedSize`       | size                                                 | `0%`                       | Its size when collapsed                              |
| `@collapsedThreshold`  | size                                                 | half of min to collapsed   | How far past its minimum it must go to collapse      |
| `@disabled`            | `boolean`                                            | `false`                    | It can't be resized, by its own handles or another's |
| `@groupResizeBehavior` | `"preserve-relative-size" \| "preserve-pixel-size"`  | `"preserve-relative-size"` | When the group resizes, keep its share or its pixels |
| `@onResize`            | `({ asPercentage, inPixels }, id, previous) => void` |                            | Called when its size changes                         |
| `@id`                  | `string`                                             | one made for it            | Its key in a layout, and its element's `id`          |
| `@as`                  | tag name                                             | `div`                      | The tag to render                                    |

A size is a percentage string (`"30%"`, `"30"`), a string with a unit (`"200px"`, `"10rem"`,
`"2em"`, `"50vh"`, `"50vw"`), or a number of pixels. It yields its API, react-resizable-panels'
`panelRef`: `size` (tracked, in percent), `isCollapsed`, `getSize()`, `resize(size)`,
`collapse()` and `expand()`.

### ResizableHandle

| Argument              | Type      | Default | What it does                                                  |
| --------------------- | --------- | ------- | ------------------------------------------------------------- |
| `@withHandle`         | `boolean` | `false` | Shows a grip on the line                                      |
| `@disabled`           | `boolean` | `false` | It can't be moved                                             |
| `@disableDoubleClick` | `boolean` | `false` | A double-click doesn't put its panel back to its default size |
| `@as`                 | tag name  | `div`   | The tag to render                                             |

### Data attributes

| Part   | Attribute                                                          | Value                                                          |
| ------ | ------------------------------------------------------------------ | -------------------------------------------------------------- |
| group  | `class`, `data-slot`                                               | `jn-resizable-panel-group`, `resizable-panel-group`            |
| group  | `data-orientation`                                                 | its `@orientation`                                             |
| group  | `data-test-jn`, `data-test-jn-name`                                | `resizable`, its `@name`                                       |
| panel  | `data-slot`, `data-panel`, `id`                                    | `resizable-panel`, present, its `@id`                          |
| panel  | `data-collapsed`, `data-disabled`                                  | present while collapsed, and when `@disabled`                  |
| panel  | `data-test-jn-part`, `data-test-jn-value`                          | `panel`, its `@id`                                             |
| handle | `class`, `data-slot`                                               | `jn-resizable-handle`, `resizable-handle`                      |
| handle | `role`, `aria-orientation`                                         | `separator`; `vertical` between side-by-side panels            |
| handle | `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-controls` | the panel before it: its size, its range, its `id`             |
| handle | `data-separator`                                                   | `inactive`, `hover`, `focus`, `active` (dragged) or `disabled` |
| handle | `data-test-jn-part`                                                | `handle`                                                       |

The grip is `jn-resizable-handle-icon`. The group sets the panels' sizes as `flex-grow` in their
style, through the CSSOM, which a strict Content Security Policy allows.

## Keyboard interactions

The [APG window splitter pattern](https://www.w3.org/WAI/ARIA/apg/patterns/windowsplitter/),
on a focused handle:

| Key                       | What it does                                                              |
| ------------------------- | ------------------------------------------------------------------------- |
| `ArrowLeft`, `ArrowRight` | Side by side: moves the handle 5% (10% with Shift); flipped right to left |
| `ArrowUp`, `ArrowDown`    | Stacked: moves the handle 5% (10% with Shift)                             |
| `Home`, `End`             | Moves it as far as it goes: the panel before at its minimum, or maximum   |
| `Enter`                   | Collapses the panel before it, if it is `@collapsible`, or expands it     |
| `F6`, `Shift+F6`          | Moves focus to the group's next handle, or the one before                 |

## Accessibility

- Each handle is a focusable `role="separator"` whose value is the size of the panel before it,
  which it names with `aria-controls`. Upstream's handles have no name; give yours one for what
  it resizes (`aria-label="Resize the sidebar"`).
- A collapsed panel's content doesn't scroll or take focus as a scroller.
- Dragging also works with touch: the group handles the drag along its axis, and the content
  still scrolls the other way.

## Testing

`ResizableHarness` from `@ember-joinery/test-support` drives a group, from this package or the
primitive:

```ts
import { ResizableHarness } from '@ember-joinery/test-support'

const layout = new ResizableHarness('workspace') // <ResizablePanelGroup @name="workspace">
await layout.press(0, 'ArrowRight')
await layout.drag(0, 40)
assert.deepEqual(layout.sizes, [65, 35])
```

| Member                                         | What it is                                                     |
| ---------------------------------------------- | -------------------------------------------------------------- |
| `orientation`                                  | `horizontal` or `vertical`                                     |
| `panels`, `handles`                            | The parts, in order                                            |
| `panel(indexOrId)`, `handle(index)`            | One part                                                       |
| `sizes`, `size(indexOrId)`                     | Each panel's share of the space, as rendered, in percent       |
| `valueNow(index)`, `range(index)`              | A handle's `aria-valuenow`, and its `aria-valuemin` and `-max` |
| `controls(index)`                              | The panel a handle resizes (`aria-controls`)                   |
| `handleState(index)`                           | Its `data-separator`                                           |
| `isHandleDisabled(index)`                      | `aria-disabled`                                                |
| `isCollapsed(indexOrId)`                       | `data-collapsed`                                               |
| `focus(index)`, `press(index, key, modifiers)` | Focuses a handle, and presses a key on it                      |
| `drag(index, distance)`                        | Drags a handle (CSS pixels along the axis, or `{ x, y }`)      |
| `hover(index, over)`, `doubleClick(index)`     | The pointer over a handle; a double-click                      |

A group nested in a panel has its own harness: `ResizableHarness.findAll()` gives one for each.

## Upstream

shadcn/ui's [Resizable](https://ui.shadcn.com/docs/components/radix/resizable), from
`apps/v4/registry/bases/radix/ui/resizable.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
