---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

The primitives' foundations, one subpath export each: `controllable-state` (Radix's
controlled-or-uncontrolled pattern, as `controllable(this, 'open', false)`), `id` (`uniqueId`
and `idFor`), `direction` (`DirectionProvider` and `getDirection`), `as` and `part` (the `@as`
tag swap and the part modifiers that let any element, `LinkTo` included, be a part),
`presence` (keeps a part mounted through its exit animation), `visually-hidden`
(`VisuallyHidden` and `{{visuallyHidden}}`), `keys` (`Key` and `KeyCombo`), `color-scheme`
(system, light or dark, saved, synced across tabs, applied to `<html>`; replaces next-themes)
and `service` (one instance per owner, for app-wide state that tests must not share).
`@ember-joinery/test-support` adds `KeyHarness`, `KeyComboHarness` and `setupColorScheme`.
