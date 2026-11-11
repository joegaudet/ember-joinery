# Portal

Renders content somewhere else in the document, as ember-primitives' and Radix's `Portal` do:
in a named target, an element, an element's id, or the end of `<body>`. The content stays its
component's own (its state, its actions, its destruction); only its DOM moves. This can be used
for components altering the layout of the page, or getting around z-index issues.

Joinery's overlays don't need one: the [top layer](/primitives/top-layer.md) puts them above
everything without moving them. Use a portal where the DOM position itself matters, such as
rendering into another region of the page.

<Example @name="portal-tray" @title="A card's note, in the tray" />

## Usage

```gts
import { Portal, PortalTargets } from '@ember-joinery/primitives/portal'

<template>
  {{! once, in the application template }}
  <PortalTargets />

  <Portal @to="popover">…</Portal>
</template>
```

**`@to` accepts any valid CSS selector** (like `[data-portal-target]`, `.my-class`, `#my-id`),
a target's name (like `popover`, `tooltip` or `modal`), or an element. A `<Portal>` renders
into the nearest target it can find above it, which allows for layering: a modal can have its
own targets, so its tooltips and popovers render inside it.

The following example demonstrates Portal-nesting:

<Example @name="portal-nesting" @title="Three layers, each in the one before" />

### Component-controlled layout

Using portals, sub-components (or even sub-routes) can render into elements that live outside
of their hierarchy. With `@append`, each portal adds to what the target holds:

<Example @name="portal-layout" @title="Two components fill one layout" />

### Why not just `in-element`?

Ember's built-in
[`in-element`](https://api.emberjs.com/ember/release/classes/Ember.Templates.helpers/methods/in-element?anchor=in-element)
renders into an element, but it leaves finding the element to you:

```hbs
{{#in-element (getElementSomehow)}}
  content portaled to the element
{{/in-element}}
```

`Portal` finds it: by a target's name or a selector, nearest first, including a target that
renders after the portal. [ember-wormhole](https://github.com/yapplabs/ember-wormhole) and
[ember-stargate](https://github.com/simonihmig/ember-stargate) solve the same problem, and the
two sections below show `Portal` used each of their ways.

### `@to` can be an element

The element can be created dynamically (for rendering off screen), or any other element
obtained by other means.

<Example @name="portal-element" @title="An element made in JavaScript" />

### ember-wormhole

If you're migrating from ember-wormhole, `@wormhole` takes an element's id (with or without
the `#`), any other selector, or an element:

<Example @name="portal-wormhole" @title="By id, as ember-wormhole" />

The wormhole way assumes the element is in the document by the end of the render, and it isn't
reactive, nor does it nest, which is why it is an argument of its own rather than `@to`. Where
the element is in the document already, the content renders at once. Unlike the other ways, it
always appends to the target.

### ember-stargate

ember-stargate registers its targets by name. `<PortalTarget @name>` does the same, and the
portals find it however the two are ordered, nesting included:

<Example @name="portal-stargate" @title="A target registered by name" />

## Portal targets

`<PortalTargets />` renders ember-primitives' three targets, for popovers, tooltips and modals,
as `<div>`s with a `data-portal-name`:

```html
<div data-portal-name="joinery__portal-targets__popover"></div>
<div data-portal-name="joinery__portal-targets__tooltip"></div>
<div data-portal-name="joinery__portal-targets__modal"></div>
```

`@to` finds the nearest one above the portal, by its short name (`popover`, `tooltip`,
`modal`) or its full one (`PORTALS.popover`). Rendering `<PortalTargets />` again, inside a
modal, gives what is in the modal its own targets, so a tooltip there renders above the modal
rather than behind it. `<PortalTarget @name="tray" />` adds a target of your own, which can
render before or after its portals.

## API

| Argument    | Type                  | What it does                                                                                        |
| ----------- | --------------------- | --------------------------------------------------------------------------------------------------- |
| `@to`       | `string` \| `Element` | A target's name, a selector, or an element. Without it (or `@wormhole`), the end of `<body>`        |
| `@append`   | `boolean`             | Add to what the target holds, instead of replacing it. Default `false`; `<body>` is always appended |
| `@wormhole` | `string` \| `Element` | ember-wormhole's way: an element's id, a selector, or an element. Always appends                    |

`wormhole(query)` finds the element for an id or a selector, and `findNearestTarget(origin,
name)` the target a portal at `origin` would use.

## Accessibility

Portalling breaks away from how the browser natively handles focus, and returning focus to
certain elements. Content rendered elsewhere is elsewhere in the tab order too, so where it
takes focus, as a modal or a popover does, keep the element that had focus and give it back
when the content goes. Joinery's overlays do this for you
([`focusScope`](/primitives/focus-scope.md)), on the top layer.

## Testing

A part rendered somewhere else names its component in `data-test-jn-owner` (the root's `id`),
and the harnesses follow it, so `card.part('note')` finds the note in the tray, as the
example's test does.
