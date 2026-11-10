---
'@ember-joinery/data-table': major
---

`@ember-joinery/data-table` is a new add-on: shadcn's Data Table, on TanStack Table v9's
framework-agnostic `@tanstack/table-core`. `createTable()` is upstream's `useTable` for Ember: a
table whose state lives in tracked atoms on Ember's autotracking (`emberReactivity()`), which
reads its options again from a function whenever what that reads changes, and whose rows',
cells', columns' and headers' methods come bound, so templates can call them. `tableState()`
owns a slice of state (upstream's `useState`), `FlexRender` (also `table.FlexRender`) renders a
column's header, cell or footer from a string, a function or a component (`flexComponent()`),
and `DataTable` is the element around a table, yielding `head`, `row`, `filter`, `previousPage`,
`nextPage` and `viewOptions` modifiers that mark its parts; `head` gives each header cell its
sort in `aria-sort`, which upstream's leave out. Everything `@tanstack/table-core` exports comes
through too. Its `/test-support` has `DataTableHarness` (rows, columns, sort, filter, pages,
selection and column visibility), and `settled()` waits for the auto-resets a table puts off
until after a render.
