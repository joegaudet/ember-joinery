---
'@ember-joinery/test-support': minor
'@ember-joinery/ember': patch
---

`DatePickerHarness` drives a date picker, shadcn's composition of a `Popover` and a `Calendar`
(there is no date picker component of its own): a `PopoverHarness` with the `calendar` in its
content and the trigger's `text`, and `pick(day)`, `pickRange(from, to)` and `showMonth(day)`,
which open the popover, go to the day's month (by the month and year dropdowns where the
calendar has them, else the previous and next buttons) and press the day. `pickRange()` picks
just that range whatever range the calendar holds, pressing `from` until the range starts and
ends there before it presses `to`, and throws when the calendar won't take the range.
The guide's Date Picker page ports every upstream example: the demo, basic, a range over two
months, a date of birth, an input, a time picker, natural language and right to left.

An Input Group addon's margin for a button directly in it (each style's `has-[>button]` rule)
now also reaches a button inside a Popover's, Tooltip's, Hover Card's, Dialog's, Sheet's,
Drawer's, Select's or menu's root, which renders an element (display: contents) where Radix's
renders none: a date picker's calendar button, or a tooltip's or dropdown's button in an addon,
sits where upstream's does. `build-css.mjs` declares a `style-<name>` variant for each style,
which a component's hand-written rule uses to restate a sheet's per-style utilities.
