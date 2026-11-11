---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Tabs` is shadcn's Tabs (`t.List` with `@variant="default"` or `"line"`, `t.Trigger`,
`t.Content`, and `@orientation="vertical"`), on a new headless `Tabs` and `TabsState` in
`@ember-joinery/primitives/tabs`, which covers ember-primitives' Tabs too: controlled or not
(`@value`, `@defaultValue`, and `@onValueChange`, which also hears the value before), the first
tab selected when no value is given, automatic or manual activation, one tab stop with the arrow
keys along the orientation (flipped right to left, wrapping unless `@loop={{false}}`), link tabs
on `<a href>` or `LinkTo` that focus never selects, and the `t.list`, `t.trigger` and
`t.content` modifiers for your own elements. `@ember-joinery/test-support` adds `TabsHarness`.
