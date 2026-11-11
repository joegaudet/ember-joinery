# Drawer

A drawer component for Ember.

<Example @name="drawer-demo" @title="Drawer" />

Its bar chart is a [Chart](/components/chart.md)'s `BarChart`, from `@ember-joinery/chart`, where
upstream's is recharts'.

## About

Drawer is built on top of [Vaul](https://github.com/emilkowalski/vaul) by
[emilkowalski](https://twitter.com/emilkowalski). Joinery ports Vaul 1.1.2's behaviour into
[`@ember-joinery/primitives/drawer`](/primitives/drawer.md): a drag along the drawer's axis
moves it, and a long or fast one closes it, as on a phone; and its slides are vaul's own CSS,
in `joinery.css`.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Drawer } from '@ember-joinery/ember'
```

## Usage

```gts
<Drawer as |d|>
  <d.Trigger>Open</d.Trigger>
  <d.Content>
    <d.Header>
      <d.Title>Are you absolutely sure?</d.Title>
      <d.Description>This action cannot be undone.</d.Description>
    </d.Header>
    <d.Footer>
      <Button>Submit</Button>
      <Button @variant="outline" {{d.close}}>Cancel</Button>
    </d.Footer>
  </d.Content>
</Drawer>
```

`<Drawer>` yields its parts. Where upstream wraps your own element in a part with `asChild`
(`<DrawerClose asChild><Button>`), Joinery puts the part's modifier on it:
`<Button {{d.close}}>`, and `<Button {{d.trigger}}>` for the trigger. A Drawer is a
[Dialog](/components/dialog.md) underneath, so its state is its own or yours, with `@open` and
`@onOpenChange`.

## Composition

Use the following composition to build a `Drawer`:

```text
Drawer
├── Trigger
└── Content
    ├── Header
    │   ├── Title
    │   └── Description
    └── Footer
```

## Scrollable Content

Keep actions visible while the content scrolls.

<Example @name="drawer-scrollable-content" @title="Scrollable Content" />

The scrolling region takes focus (`tabindex="0"`), so a keyboard can scroll it; upstream's
doesn't, and the accessibility audit every example runs asks for it.

## Sides

Use `@direction` on the Drawer to set the side of the drawer. Available options are `top`,
`right`, `bottom`, and `left`.

<Example @name="drawer-sides" @title="Sides" />

A drawer slides in from its side, and a drag toward that side closes it. One from the top or
bottom lets its content scroll, rather than drag, for the half second after it opens and
whenever the content is scrolled, as vaul's does.

## Responsive Dialog

You can combine the [Dialog](/components/dialog.md) and `Drawer` components to create a
responsive dialog. This renders a `Dialog` component on desktop and a `Drawer` on mobile.

<Example @name="drawer-dialog" @title="Responsive Dialog" />

Upstream's `useMediaQuery` is the example's own: it asks the window the example renders in,
which in the frame's width presets is an `<iframe>` that wide, so pick 375 to see the drawer.

## RTL

Joinery's styles use logical properties, so a drawer lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): its text starts on the
right, and `left` and `right` are the inline start and end, as the ported styles place them. A
`left` drawer is on the right, right to left, and slides and drags from there. The example is
the first one's, in Arabic, with its chart's x-axis reversed (`@reversed={{true}}`) so the bars
run from the right.

<Example @name="drawer-rtl" @title="RTL" @dir="rtl" />

## More from Vaul

Upstream's page leaves the rest to [Vaul's documentation](https://vaul.emilkowal.ski/getting-started).
Joinery's Drawer has all of it, so these are Joinery's own examples of it.

### Snap Points

`@snapPoints` gives it places to rest, smallest first: fractions of the screen (`0.5`, `1`) or
pixels (`'148px'`). A drag lets go at the nearest, and a fast one goes on to the next.
`@activeSnapPoint` and `@onActiveSnapPointChange` keep it in your state (or start it with
`@defaultActiveSnapPoint`), and `@fadeFromIndex` says from which the overlay shows.

<Example @name="drawer-snap-points" @title="Snap Points" />

The drawer itself is as tall as the screen (`h-full max-h-[97%]`), and each snap point moves it
down so that much shows.

### Nested Drawers

`d.Nested` is a Drawer whose opening steps this one back, as vaul's `NestedRoot`. Dragging it
brings the outer one forward as it goes.

<Example @name="drawer-nested" @title="Nested Drawers" />

### Non-dismissible

With `@dismissible={{false}}`, no drag, Escape, press outside or close part closes it, and its
trigger only opens it. Close it yourself, with `@open` or `d.setOpen`.

<Example @name="drawer-non-dismissible" @title="Non-dismissible" />

### Scaled Background

With `@shouldScaleBackground`, the element marked `data-vaul-drawer-wrapper` (your app's root)
scales back while the drawer is open, as an iOS sheet's page does, and `<body>` turns black
behind it unless `@setBackgroundColorOnScale={{false}}`.

<Example @name="drawer-scale-background" @title="Scaled Background" />

## API Reference

### Drawer

It takes a [Dialog](/components/dialog.md)'s arguments (`@open`, `@defaultOpen`,
`@onOpenChange`, `@modal`, `@onClose` and `@name`, for `DrawerHarness`) and vaul's:

| Argument                     | Type                                     | Default    | What it does                                                                      |
| ---------------------------- | ---------------------------------------- | ---------- | --------------------------------------------------------------------------------- |
| `@direction`                 | `"top" \| "right" \| "bottom" \| "left"` | `"bottom"` | The edge it comes in from                                                         |
| `@dismissible`               | `boolean`                                | `true`     | Whether a drag, Escape, a press outside, its close parts and trigger can close it |
| `@snapPoints`                | `(number \| string)[]`                   |            | Where it can rest: fractions of the screen, or `'<n>px'`                          |
| `@activeSnapPoint`           | `number \| string \| null`               |            | The snap point it rests at, when you control it                                   |
| `@defaultActiveSnapPoint`    | `number \| string`                       | the first  | Where it starts resting, when it controls itself                                  |
| `@onActiveSnapPointChange`   | `(snapPoint) => void`                    |            | Called when it moves to another snap point                                        |
| `@fadeFromIndex`             | `number`                                 | the last   | The snap point from which the overlay shows                                       |
| `@snapToSequentialPoint`     | `boolean`                                | `false`    | A fast drag goes to the next snap point, never past it                            |
| `@closeThreshold`            | `number`                                 | `0.25`     | How much of it a slow drag must hide to close it                                  |
| `@scrollLockTimeout`         | `number`                                 | `100`      | How long after its content scrolls it won't drag, in ms                           |
| `@handleOnly`                | `boolean`                                | `false`    | Only a `Handle` starts a drag                                                     |
| `@shouldScaleBackground`     | `boolean`                                | `false`    | Scale `[data-vaul-drawer-wrapper]` back while it is open                          |
| `@setBackgroundColorOnScale` | `boolean`                                | `true`     | Make `<body>` black behind the scaled background                                  |
| `@noBodyStyles`              | `boolean`                                | `false`    | Leave `<body>`'s styles alone                                                     |
| `@autoFocus`                 | `boolean`                                | `false`    | Focus its first focusable element when it opens, rather than the drawer itself    |
| `@repositionInputs`          | `boolean`                                | `true`     | Keep a focused input in view when a phone's keyboard opens                        |
| `@fixed`                     | `boolean`                                | `false`    | With `@repositionInputs`, shrink it rather than move it up                        |
| `@onDrag`                    | `(event, percentageDragged) => void`     |            | Called as it is dragged, with how far toward closed (0 to 1)                      |
| `@onRelease`                 | `(event, open) => void`                  |            | Called when a drag lets go, with whether it stays open                            |
| `@onAnimationEnd`            | `(open) => void`                         |            | Called once it has finished opening or closing                                    |

It yields `Trigger`, `Content`, `Header`, `Footer`, `Title`, `Description`, `Close`, `Nested`
and `Handle` (vaul's, unstyled), the `trigger` and `close` modifiers, and its state: `isOpen`,
`isModal`, `isDragging`, `direction`, `activeSnapPoint`, `setActiveSnapPoint`, `open`, `toggle`,
`setOpen` and `returnValue`.

### Content

It takes a Dialog Content's focus and dismissal handlers (`@onOpenAutoFocus`,
`@onEscapeKeyDown`, `@onPointerDownOutside`…), `@forceMount` and `@as`. It draws the handle
upstream draws at the top of a drawer from the bottom.

### Data attributes

| Part        | `class`                                  | `data-slot`          | Also                                                                     |
| ----------- | ---------------------------------------- | -------------------- | ------------------------------------------------------------------------ |
| Root        |                                          |                      | `data-test-jn="drawer"`                                                  |
| Trigger     |                                          | `drawer-trigger`     | `data-state`, `aria-expanded`                                            |
| Overlay     | `jn-drawer-overlay`                      | `drawer-overlay`     | `data-state`, `data-vaul-overlay`, `data-vaul-snap-points-overlay`       |
| Content     | `jn-drawer-content group/drawer-content` | `drawer-content`     | `data-vaul-drawer-direction`, `data-vaul-snap-points`, `data-snap-point` |
| Handle      | `jn-drawer-handle`                       |                      | `data-test-jn-part="handle"`                                             |
| Header      | `jn-drawer-header`                       | `drawer-header`      |                                                                          |
| Footer      | `jn-drawer-footer`                       | `drawer-footer`      |                                                                          |
| Title       | `jn-drawer-title jn-font-heading`        | `drawer-title`       | `id`, named by `aria-labelledby`                                         |
| Description | `jn-drawer-description`                  | `drawer-description` | `id`, named by `aria-describedby`                                        |
| Close       |                                          | `drawer-close`       |                                                                          |

The content has vaul's `data-vaul-drawer` attributes, which vaul's CSS slides by, and the class
`vaul-dragging` while it is dragged.

## Keyboard interactions

A Drawer's keys are a [Dialog](/components/dialog.md)'s: `Space` or `Enter` on the trigger
opens it, `Tab` and `Shift` + `Tab` go round inside it, and `Esc` closes it, with focus back on
the trigger. A drag is a pointer's; everything it does, the drawer's own buttons and `Esc` do
too.

## Accessibility

As a [Dialog](/components/dialog.md)'s: the content has the `dialog` role and is named by its
Title, the page behind is inert and doesn't scroll, and focus goes back to the trigger when it
closes. When it opens, focus moves to the drawer itself (it takes `tabindex="-1"`), so a phone's
keyboard doesn't pop up for an input in it; vaul leaves focus on the trigger, behind the inert
page, and Joinery moves it in, as WAI-ARIA's dialog pattern asks. `@autoFocus={{true}}` moves it
to the first focusable element instead. The handle is hidden from screen readers, as vaul's is.

## Testing

`DrawerHarness` from `@ember-joinery/test-support` drives a `<Drawer>`. It is a `DialogHarness`
(see [Dialog](/components/dialog.md)), and drags the drawer as a pointer does:

```ts
import { DrawerHarness } from '@ember-joinery/test-support'

const drawer = new DrawerHarness('goal')
await drawer.open()
await drawer.afterOpening() // a drawer from the bottom won't drag for half a second
await drawer.drag(40)
assert.true(drawer.isOpen, 'a short drag springs back')
await drawer.drag(200)
assert.false(drawer.isOpen, 'a long one closes it')
```

| Member               | What it is                                                                   |
| -------------------- | ---------------------------------------------------------------------------- |
| `direction`          | Its `@direction`, from `data-vaul-drawer-direction`                          |
| `side`               | The physical edge it is on (right to left, `left` is on the right)           |
| `handle`             | The handle, or `null`                                                        |
| `isDragging`         | Whether it is being dragged                                                  |
| `activeSnapPoint`    | The snap point it rests at, as a string (`"0.5"`, `"148px"`), or `null`      |
| `offset`             | How far it is moved along its axis now, in pixels                            |
| `finishAnimations()` | Ends its slide and transitions now, to measure it where it rests             |
| `afterOpening()`     | Waits out its opening, after which a drawer from the top or bottom drags     |
| `drag(distance)`     | Drags it toward closed by `distance` px (negative: toward open), and lets go |
| `swipe(distance)`    | The same, fast, as a flick                                                   |
| `tapHandle()`        | Taps the `Handle`: the next snap point, or closed after the last             |

`drag()` takes `{ duration, steps, from, pointerType }`; slow by default (600ms), so the
distance decides rather than the speed.

## Upstream

shadcn/ui's [Drawer](https://ui.shadcn.com/docs/components/radix/drawer), from
`apps/v4/registry/bases/radix/ui/drawer.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
vaul 1.1.2. The headless part is [Drawer](/primitives/drawer.md) in
`@ember-joinery/primitives`, which covers ember-primitives' Drawer too.
