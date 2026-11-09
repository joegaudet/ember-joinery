---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

ember-primitives' components that shadcn has no counterpart for, one subpath export each:
`scroller` (`Scroller`, which yields `scrollToTop`, `scrollToBottom`, `scrollToLeft`,
`scrollToRight`, `scrollToStart` and `scrollToEnd`), `zoetrope` (`Zoetrope`: a row that scrolls a
page at a time, instantly for reduced motion, right to left too, and without trapping Tab),
`hero` (`Hero`), `sticky-footer` (`StickyFooter`), `link` (`Link`, active-aware, with
`aria-current` and `data-active`), `external-link` (`ExternalLink`), `heading` (`Heading`, whose
level comes from the sections around it, and `getSectionHeadingLevel`), `incremental-each`
(`IncrementalEach`, which renders a long list a batch at a time) and `shadowed` (`Shadowed`, a
shadow root, with `@includeStyles`). The layouts bring their own rules, in `@layer joinery`, with
nothing to import. `@ember-joinery/test-support` adds `ScrollerHarness`, `ZoetropeHarness`,
`HeroHarness`, `StickyFooterHarness`, `LinkHarness`, `ExternalLinkHarness`, `HeadingHarness` and
`ShadowedHarness`, ember-primitives' shadow DOM helpers (`findInShadow`, `findShadow`,
`findInFirstShadow`, `hasShadowRoot`), and `data-test-jn-wrapper`: a component that wraps your
content marks its root with it, and the parts inside belong to the component around it.
