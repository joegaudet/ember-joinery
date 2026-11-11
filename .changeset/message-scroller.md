---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`MessageScrollerProvider` is shadcn's Message Scroller: a chat transcript's scroll container that
opens a saved transcript at the start, the end or the last anchored turn (`@defaultScrollPosition`,
hidden until it gets there), settles a new `@scrollAnchor` turn near the top with a peek of the
one before (`@scrollPreviousItemPeek`), follows a streamed reply at the end with `@autoScroll`
until the reader scrolls away, keeps the reader's row in place when history is prepended, and
jumps to any row. It yields its styled parts (`Root`, `Viewport`, `Content`, `Item`, `Button`,
`Visibility`), the commands (`scrollToMessage`, `scrollToEnd`, `scrollToStart`) and the scroll
state (`scrollable`); the parts are exported on their own too (`MessageScroller`,
`MessageScrollerItem`…). `@ember-joinery/primitives/message-scroller` is the headless scroller,
`@shadcn/react`'s, with `MessageScrollerConsumer` and the `messageScrollerButton` modifier. Its
button, as upstream's, keeps a `tabindex` of your own while it is active, and a click listener of
yours runs first and can stop the scroll with `preventDefault()`; the styled one takes `@as`.
`@ember-joinery/test-support` adds `MessageScrollerHarness`.
