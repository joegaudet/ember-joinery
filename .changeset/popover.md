---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Popover` is shadcn's Popover, on Radix's: `<Popover as |p|>` yields Trigger, Anchor, Content,
Header, Title, Description, Close and Arrow, and a `trigger` modifier for your own Button
(`<Button {{p.trigger}}>`). The content is in the top layer while open, placed against its
trigger (centred, 4px off, flipping to stay in view), closed by Escape or a press outside, with
focus moving in and back; `@modal` keeps focus and the pointer inside, and hides the rest of
the page from assistive technology and stops it scrolling. Its state is
`@open`/`@defaultOpen`/`@onOpenChange`. `@ember-joinery/primitives/popover` is the headless
one, covering ember-primitives' Popover (`@placement`, `@offsetOptions`, `@flipOptions`,
`@shiftOptions`, `@middleware`, `@strategy`, and the `reference`, `setReference`, `arrow` and
`data` yields), and `@ember-joinery/test-support` adds `PopoverHarness`.
