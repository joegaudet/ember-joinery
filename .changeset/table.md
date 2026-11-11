---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Table` is shadcn's responsive table: a native `<table>` in a container that scrolls it
sideways, yielding `Header`, `Body`, `Footer`, `Row`, `Head`, `Cell` and `Caption`, each also a
modifier for an element of your own (`<tr {{t.row}}>`), each taking `@as`. While the table is
wider than its container and has nothing to focus, the container joins the tab order, so the
keyboard can scroll it. `@ember-joinery/test-support` adds `TableHarness`.
