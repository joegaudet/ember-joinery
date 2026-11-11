---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Tooltip` and `TooltipProvider` are shadcn's, on Radix's: a tooltip opens when the pointer
rests on its trigger (at once by default, as in shadcn's provider) or on focus, describes the
trigger through `aria-describedby`, lets the pointer cross onto it, and closes on blur, a
press, Escape or the pointer leaving; it draws its arrow. A provider's tooltips share its
`@delayDuration`, and the next opens at once just after one closed; tooltips need no provider.
`@ember-joinery/primitives/tooltip` is the headless pair, and `@ember-joinery/test-support`
adds `TooltipHarness` and the `hover()` and `unhover()` pointer helpers.
