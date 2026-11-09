---
'@ember-joinery/test-support': minor
---

The harness base: `Harness` finds a component by `data-test-jn` and `data-test-jn-name` on
every read, reaches its parts through `data-test-jn-part` (following `data-test-jn-owner` into
the top layer and portals), and fails clearly when pointed at another component. `@child`
declares child harnesses, created once and kept, with legacy or standard decorators; `find()`
and `findAll()` make one-off lookups; and `selectors` and `attributes` cover the
`data-test-jn-*` attributes.
