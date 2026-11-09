---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`DropdownMenu` is shadcn's Dropdown Menu, on Radix's: `<DropdownMenu as |m|>` yields Trigger,
Content, Group, Label, Item (`@variant`, `@inset`, `@onSelect`), LinkItem, CheckboxItem,
RadioGroup, Separator, Shortcut, Sub (its Trigger and Content) and Portal, a `trigger` modifier
for your own Button (`<Button {{m.trigger}}>`), and `item` and `checkboxItem` modifiers that
style your own element as an item. The content is a menu in the top layer, below its trigger and
lined up with its start: the arrow keys, Home, End and typing move between its items, Enter or a
click selects one, Escape or a press outside closes it, and focus goes back to the trigger.
Submenus open on hover or the arrow pointing into them, and stay open while the pointer crosses
other items on its way there; as Radix's, a submenu closes (`@onOpenChange(false)`) when the
menu it is in closes or it goes away. Every part but LinkItem (always an `<a>`) takes `@as`.
Modal by default, it keeps focus and the pointer in the menu and makes the page inert. Its
state is `@open`/`@defaultOpen`/`@onOpenChange`.
`@ember-joinery/primitives/dropdown-menu` is the headless one, covering ember-primitives' Menu
(also exported as `Menu`), and `@ember-joinery/test-support` adds `DropdownMenuHarness`, which
finds items by their text and opens submenus with `sub()`.
