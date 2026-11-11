---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Menubar` is shadcn's Menubar, on Radix's: `<Menubar as |bar|><bar.Menu as |m|>` yields a
Trigger and a Content placed as upstream's (below the trigger, at its start, 4px before it and
8px off), with the Dropdown Menu's items, checkbox and radio items, labels, separators,
shortcuts and submenus in the menubar's classes and slots, and `trigger`, `item` and
`checkboxItem` modifiers for your own elements. Its triggers share one tab stop: the arrow keys
move between them, Enter, Space or ArrowDown open a menu on its first item, and while one is
open ArrowLeft and ArrowRight (flipped right to left) and the pointer move to the others. Which
menu is open is `@value`/`@defaultValue`/`@onValueChange`. `@ember-joinery/primitives/menubar`
is the headless one, and `@ember-joinery/test-support` adds `MenubarHarness`, whose `menu(label)`
has a Dropdown Menu harness's members for each menu.
