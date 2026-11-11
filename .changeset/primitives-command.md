---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

`@ember-joinery/primitives/command` adds `Command`, cmdk's command menu, headless: typing filters
the items with cmdk's command score (or `@filter`) and shows the best first, groups and
separators hide with nothing to show, Empty shows when nothing matches, and the arrows, Home and
End, Ctrl+N/J/P/K and Alt+arrow move the selection while focus stays in the input; Enter clicks
the selected item. It covers ember-primitives' CommandPalette too: `@search` and
`@onSearchChange`, `@onSelect`, `@hotkey` and `@onOpen`, link items, and a `role="status"` that
announces the result count (`@resultsText`). `CommandDialog` puts a Command in a modal dialog,
with a `@hotkey` that opens and closes it. `@ember-joinery/test-support` adds `CommandHarness`
and `CommandDialogHarness`.
