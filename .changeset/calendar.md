---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Calendar` is shadcn's Calendar, with Joinery's own date picking in place of React DayPicker
and no date library: `@mode` `single`, `multiple` or `range` (`@value`, `@defaultValue` and
`@onValueChange`, a `Date`, `Date[]` or `{ from, to }`), month and year dropdowns
(`@captionLayout`), several months, `@disabled`, `@hidden` and `@modifiers` matchers, week
numbers, outside days, fixed weeks, and the date grid's keys, right to left too. Names,
numbers and the week's first day come from Intl in `@locale`; `@calendar` and `@numerals` show
any calendar Intl knows, such as the Persian one. A `<:day>` block draws what each day shows.
`@ember-joinery/primitives/calendar` is the headless one, with `CalendarState` and its date
helpers, and `@ember-joinery/test-support` adds `CalendarHarness`.
