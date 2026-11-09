---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Drawer` is shadcn's Drawer, on the headless one in `@ember-joinery/primitives/drawer`: a panel
from any edge of the screen (`@direction`), with upstream's handle, header, footer, title and
description, and vaul's snap points, nested drawers and scaled background. `joinery.css` (and
every style) ships vaul 1.1.2's CSS, which slides it in and out, with twins for right to left.
`@ember-joinery/test-support` adds `DrawerHarness`, a `DialogHarness` that drags the drawer
(`drag()`, `swipe()`, `tapHandle()`) and reads its `direction`, `side`, `activeSnapPoint`,
`offset` and `isDragging`.
