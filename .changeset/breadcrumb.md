---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`@ember-joinery/primitives/breadcrumb` is ember-primitives' Breadcrumb: a named `nav` around an
ordered list, yielding a `Separator` that assistive technology skips
(`breadcrumbSeparatorAria()`). `Breadcrumb` in `@ember-joinery/ember` is shadcn's, yielding
`List`, `Item`, `Link`, `Page`, `Separator` (lucide's chevron, mirrored right to left, or your
block or `@icon`) and `Ellipsis`, each also a modifier (`<LinkTo {{b.link}}>`).
`@ember-joinery/test-support` adds `BreadcrumbHarness`, which drives both.
