---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`ContextMenu` is shadcn's Context Menu, on Radix's: a right click on `<c.Trigger>` (or a long
press by touch or pen) opens its content at the pointer, in place of the browser's own menu. Its
content, items, checkbox and radio items, labels, separators, shortcuts and submenus are the
Dropdown Menu's, with `context-menu` in their classes and slots. `@onOpenChange` tells you when
it opens and closes. `@ember-joinery/primitives/context-menu` is the headless one, and
`@ember-joinery/test-support` adds `ContextMenuHarness`, with `open(point)` for a right click and
`longPress()`.
