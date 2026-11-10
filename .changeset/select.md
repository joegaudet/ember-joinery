---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Select` is shadcn's Select, on Radix's: `<Select as |s|>` yields Trigger (`@size`), Value
(`@placeholder`), Content, Group, Label, Item, Separator and Arrow, and a `trigger` modifier.
The list opens over its trigger with the chosen option on the value (`item-aligned`, the
default) or below it (`@position="popper"`), with scroll buttons while it scrolls, typeahead on
the closed trigger and in the list, focus kept inside and the rest of the page inert while it
is open, a hidden native `<select>` named `@formName` in a form, and a trigger a Field sizes
as it does upstream's. Its state is
`@value`/`@defaultValue`/`@onValueChange` and `@open`/`@defaultOpen`/`@onOpenChange`.
`@ember-joinery/primitives/select` is the headless one, and `@ember-joinery/test-support`
adds `SelectHarness`.
