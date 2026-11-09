---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

Toasts, as shadcn's Sonner: sonner 2.0.7 ported. `@ember-joinery/primitives/toast` has
`toast()` with sonner's methods (`success`, `info`, `warning`, `error`, `loading`, `message`,
`custom`, `promise`, `dismiss`, `getHistory`, `getToasts`), kept per owner in a `Toasts`
service so each app and each test has its own (`toastsFor(this)`), and a headless `Toaster`
with sonner's arguments, markup and data attributes: positions, the stack (three visible,
expanding on hover, focus or Alt+T), timers that pause, swipe to dismiss, rich colours, close,
action and cancel buttons. Its lists are in the top layer, so toasts show above dialogs, and are
dismissable branches. `@ember-joinery/ember` adds `Toaster`, upstream's: lucide's icons, the
popover tokens and the theme's radius, a theme that follows `.dark`, and sonner's CSS in
`joinery.css`; it exports `toast` and `toastsFor` too. `@ember-joinery/test-support` adds
`ToasterHarness`, `ToastHarness` and `setupToaster(hooks)`.
