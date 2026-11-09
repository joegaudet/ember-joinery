---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Collapsible` is shadcn's Collapsible, and `@ember-joinery/primitives/collapsible` the headless
one under it, Radix's: a trigger (`aria-expanded`, `aria-controls`) that shows and hides content,
controlled (`@open`, `@onOpenChange`) or not (`@defaultOpen`), with a yielded `trigger` modifier
for your own element (`<Button {{c.trigger}}>`). The content stays in the document, `hidden`
while closed, animates out through `Presence`, and is measured into
`--radix-collapsible-content-height` and `-width`; `CollapsibleState` holds the behaviour for
components built on it. Joinery's base keeps a part that is `hidden` hidden whatever `display`
a class gives it, as Tailwind's preflight does, so content laid out with `flex` stays out of the
way while closed. `Presence` now also yields `isExiting`. `@ember-joinery/test-support` adds
`CollapsibleHarness`.
