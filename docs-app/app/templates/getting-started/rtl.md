# RTL

Right-to-left support for Joinery's components.

Joinery's components support right-to-left (RTL) layouts. Text alignment, positioning and
directional styles adapt for languages like Arabic, Hebrew and Persian, and so do the keyboard
and the pointer.

<Example @name="card-rtl" @title="A card component in RTL mode." @dir="rtl" />

## Get started

There is nothing to install: every component works in both directions. Set the direction and
the language on `<html>`, in your app's `index.html`:

```html
<!doctype html>
<html lang="ar" dir="rtl"></html>
```

Components take their direction from the document where they are, the nearest `dir`, so a
part of the page in another direction only needs `dir` on an element around it. For a
direction your code sets, use the [Direction](/components/direction.md) component,
`<DirectionProvider @direction="rtl">`, which renders that `dir` without adding a box to the
layout.

## How it works

Upstream's CLI rewrites a component's classes when you add it to an RTL project. Joinery's
style sheets are ported from upstream's with the same rewrite done once, so one sheet serves
both directions:

- Physical sides are logical: `pl-2` is `ps-2`, `left-0` is `start-0`, `ml-auto` is `ms-auto`,
  and so on, so padding, margins, borders and positions follow the text.
- Animations slide from the logical side: a dropdown or a sheet opening from the start slides in
  from the right in RTL.
- Icons that point a way (a breadcrumb's chevron, pagination's arrows, a submenu's chevron) keep
  upstream's `cn-rtl-flip` marker as `jn-rtl-flip`, which mirrors them right to left.

And what isn't CSS follows the direction too, as Radix's does:

- Arrow keys flip: in a horizontal menu bar, tabs, a radio group or a slider, Right moves
  towards the end, which is left in RTL.
- Drags follow it: a slider's or a resizable handle's pointer, a drawer's swipe, a carousel.
- Floating parts (popovers, menus, tooltips, select lists) take `align="start"` and `"end"` from
  the direction, and are in the top layer inside their component's root, so they inherit its
  `dir`; upstream's note about passing `dir` to portal content doesn't apply.

The guide's examples have an **RTL** switch above them, and each component page with one of
upstream's right-to-left examples shows it, in Arabic.

## Reading the direction

In code, `getDirection(element)` (from `@ember-joinery/ember`, or
`@ember-joinery/primitives/direction`) reads the direction where an element is, and
`isRTL(element)` says whether it is right to left:

```ts
import { getDirection } from '@ember-joinery/ember'

const next = getDirection(event.currentTarget as Element) === 'rtl' ? 'ArrowLeft' : 'ArrowRight'
```

## Font recommendations

For the best RTL experience, use a font with proper support for your language.
[Noto](https://fonts.google.com/noto) is a good family for it, and pairs well with Inter and
Geist. Joinery's parts take the page's `--font-sans`, so set it to the font:

```css
@import '@fontsource-variable/noto-sans-arabic';

:root {
  --font-sans: 'Noto Sans Arabic Variable', sans-serif;
}
```

## Migrating icons of your own

An icon of your own that points a way needs flipping too. Give it the `jn-rtl-flip` class, as
Joinery's own do, or in a Tailwind app `rtl:rotate-180`:

```gts
<Icon @icon={{ArrowRight}} class="jn-rtl-flip" />
```

## Testing

Render a test's component inside `<DirectionProvider @direction="rtl">` (or an element with
`dir="rtl"`), and check what the user would: that the logical sides flip, and that the arrow keys
move the other way. The harnesses read positions and keys as the browser does, so they need
nothing told.

## Upstream

shadcn/ui's [RTL](https://ui.shadcn.com/docs/rtl) pages, from `apps/v4/content/docs/rtl/` at
shadcn-ui/ui@8ab2771.
