# @ember-joinery/data-table

## 1.0.1

### Patch Changes

- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
- Updated dependencies [2b887bf]
  - @ember-joinery/primitives@1.0.1
  - @ember-joinery/ember@1.0.1
  - @ember-joinery/test-support@1.0.1

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/data-table` is a new add-on: shadcn's Data Table, on TanStack Table v9's
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

### Patch Changes

- a53c07b: Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency, so `ember-joinery add` now installs it into the app for most components, `icon` included. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
