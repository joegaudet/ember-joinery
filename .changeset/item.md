---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Item` is shadcn's Item, with typed `@variant` and `@size`, `@as`, an `asItem` modifier for your
own elements and components (`<LinkTo {{asItem}}>`), and its parts, yielded and exported
(`ItemMedia`, `ItemContent`, `ItemTitle`, `ItemDescription`, `ItemActions`, `ItemHeader`,
`ItemFooter`); `itemClasses()` and `itemAttributes()` return what it renders. `ItemGroup` is a
list of items, with a `Separator`. `@ember-joinery/test-support` adds `ItemHarness` and
`ItemGroupHarness`.
