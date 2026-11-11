# Resizable

Panels side by side or stacked, with a handle between each two that a pointer drags and the
keyboard moves: APG's window splitter pattern. It follows react-resizable-panels' API (v4, which
shadcn's [Resizable](/components/resizable.md) wraps), and covers everything ember-primitives'
`Resizable` does: sizes with limits, collapsible panels, nested groups, panels that come and go,
and a layout to save.

<Example @name="resizable-headless" @title="A saved, collapsible layout" @align="start" />

## Usage

```gts
import { Resizable } from '@ember-joinery/primitives/resizable'

<template>
  <Resizable @orientation="horizontal" class="h-64" as |r|>
    <r.Panel @defaultSize="25%" @minSize="15%" @collapsible={{true}}>Sidebar</r.Panel>
    <r.Handle aria-label="Resize the sidebar" />
    <r.Panel>Content</r.Panel>
  </Resizable>
</template>
```

`ResizablePanel` and `ResizableHandle` are the same components as `r.Panel` and `r.Handle`, to
import on their own. Panels and handles are the group's children, in order, and find their
group there. For an element of your own, use the yielded modifiers:
`<section {{r.panel defaultSize="30%"}}>` and `<div {{r.handle}}>`.

The primitive has no styles. The group lays its panels out as a flex row or column (in its
style, through the CSSOM, which a strict Content Security Policy allows), and gives each panel
its share as `flex-grow`; size the group as you would any container (a stacked group needs a
height). A panel's content goes in a box that fills it and scrolls what doesn't fit.

### Sizes

A size is a percentage (`"30%"`, or `"30"`), a string with a unit (`"200px"`, `"10rem"`,
`"2em"`, `"50vh"`, `"50vw"`), or a number of pixels (`{{200}}`), as in react-resizable-panels.
Sizes in pixels or font units turn into percentages of the space the panels share, and again
when the group changes size. Panels without a `@defaultSize` share the space that is left; a
panel that comes later takes its size, and the others make room, as a new window does in a
tiling window manager.

### Collapsing, and saving the layout

A `@collapsible` panel collapses when it is dragged past its `@minSize` (by half the distance to
`@collapsedSize`, or `@collapsedThreshold`), snaps open again past the same threshold, and gets
`data-collapsed`. Enter on its handle collapses or expands it, and an arrow key collapses it in
one press from its minimum. `@onLayoutChanged` hears each finished change (`@onLayoutChange`
every pointer move); pass the sizes back as `@defaultLayout` to open with them.

A panel yields its API (`<r.Panel as |panel|>`): `panel.size` (tracked), `panel.isCollapsed`,
`panel.getSize()`, `panel.resize("40%")`, `panel.collapse()` and `panel.expand()`. The group
yields `layout`, `getLayout()` and `setLayout()`.

### The engine

`ResizableGroup` is the engine the component uses, for a group of your own:

```ts
import { ResizableGroup } from '@ember-joinery/primitives/resizable'

class Workspace extends Component {
  group = new ResizableGroup({ orientation: () => this.args.orientation })
  // <div {{this.group.group}}>, <div {{this.group.panel defaultSize="30%"}}>, <div {{this.group.handle}}>
}
```

`adjustLayout`, `validateLayout` and `constrain` are the layout math, as react-resizable-panels
does it.

## API

The arguments are the styled component's: see [Resizable](/components/resizable.md#api-reference).
`<Resizable>` takes `@orientation`, `@defaultLayout`, `@onLayoutChange`, `@onLayoutChanged`,
`@disabled`, `@disableCursor`, `@dir`, `@as` and `@name`; a panel `@defaultSize`, `@minSize`,
`@maxSize`, `@collapsible`, `@collapsedSize`, `@collapsedThreshold`, `@disabled`,
`@groupResizeBehavior`, `@onResize`, `@id` and `@as`; a handle `@disabled`,
`@disableDoubleClick` and `@as`.

From ember-primitives' `Resizable`: `@size` is `@defaultSize`, a number there is a percentage
(here, `"30%"`), and `<Panel>` and `<Handle>` are `ResizablePanel` and `ResizableHandle`.

## Keyboard interactions

| Key                       | What it does                                                              |
| ------------------------- | ------------------------------------------------------------------------- |
| `ArrowLeft`, `ArrowRight` | Side by side: moves the handle 5% (10% with Shift); flipped right to left |
| `ArrowUp`, `ArrowDown`    | Stacked: moves the handle 5% (10% with Shift)                             |
| `Home`, `End`             | Moves it as far as it goes                                                |
| `Enter`                   | Collapses or expands the panel before it, if it is collapsible            |
| `F6`, `Shift+F6`          | Moves focus to the next handle, or the one before                         |

## Testing

`ResizableHarness` drives it, as on [Resizable's page](/components/resizable.md#testing).

## Upstream

[react-resizable-panels](https://github.com/bvaughn/react-resizable-panels) (v4), which shadcn's
Resizable wraps, and ember-primitives' `Resizable`, at 0.64.2.
