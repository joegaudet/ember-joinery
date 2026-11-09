---
'@ember-joinery/primitives': minor
---

`dialog` and `alert-dialog`: Radix's Dialog and AlertDialog, headless, covering ember-primitives'
Dialog and Modal. `<Dialog as |d|>` yields Trigger, Overlay, Content, Title, Description and
Close, a modifier for each part you render yourself (`<Button {{d.trigger}}>`), and its state
(`isOpen`, `open`, `toggle`, `setOpen`, `returnValue`), controlled or not (`@open`,
`@defaultOpen`, `@onOpenChange`). Its content sits in the top layer; Escape and a press outside
close it; focus moves in and back. A modal one traps focus, makes the rest of the page inert and
locks the page's scroll; both animate out. A `<form method="dialog">` inside closes it, and
`@onClose` hears its `returnValue`. `<AlertDialog>` is always modal, with the `alertdialog` role,
focus on Cancel, and Action and Cancel parts. `scroll-lock`: `lockScroll()` and `{{scrollLock}}`,
as react-remove-scroll. `hide-others`: `hideOthers()` and `inertOthers()`, as the aria-hidden
package.
