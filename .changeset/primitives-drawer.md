---
'@ember-joinery/primitives': minor
---

`drawer`: vaul's Drawer (1.1.2), headless, covering ember-primitives' Drawer. `<Drawer as |d|>`
is a Dialog with gestures: it yields a Dialog's parts with vaul's attributes, a `Handle`, a
`Nested` drawer and its state (`isDragging`, `direction`, `activeSnapPoint`,
`setActiveSnapPoint`…). A drag along its axis moves it, fades its overlay and closes it when let
go far or fast enough (`@closeThreshold`); `@direction` puts it on any edge (left and right are
the inline start and end); `@snapPoints` gives it places to rest, controlled or not
(`@activeSnapPoint`, `@onActiveSnapPointChange`), with `@fadeFromIndex` and
`@snapToSequentialPoint`; `@shouldScaleBackground` scales `[data-vaul-drawer-wrapper]` back;
`@dismissible={{false}}` leaves closing to you; `@handleOnly`, `@onDrag`, `@onRelease`,
`@onAnimationEnd` and `@repositionInputs` are vaul's. Focus moves to the drawer itself when it
opens (`@autoFocus` for its first field).
