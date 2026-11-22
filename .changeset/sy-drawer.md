---
'@ember-joinery/primitives': patch
---

The Drawer's modes and timers run on a Switchyard statechart; nothing changes in behavior, apart from these fixes. A close that a controlled `@open` refuses no longer moves it to its first snap point (as vaul's, only a close the drawer itself made does), closing before it has finished opening no longer calls `onAnimationEnd(true)`, a handle tap no longer changes the snap point after the drawer is destroyed, and `settled()` now waits for its animation end, background and nested-drawer timers, and a drawer destroyed while open puts the body's background back. As vaul's, `onAnimationEnd` isn't called for a drawer that renders open.
