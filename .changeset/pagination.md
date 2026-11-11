---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Pagination` is shadcn's: a named `nav` yielding `Content`, `Item`, `Link` (`@isActive`,
`@size`), `Previous` and `Next` (`@text`, `@label`, `@icon`) and `Ellipsis`. Its links are
Buttons, ghost or, for the current page, outline with `aria-current="page"`; the `link`,
`previous` and `next` modifiers make a router's link one, and `paginationLinkClasses()` and
`paginationLinkAttributes()` return what they render. `@ember-joinery/test-support` adds
`PaginationHarness`.
