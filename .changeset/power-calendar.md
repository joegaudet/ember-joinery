---
'@ember-joinery/power-calendar': major
'@ember-joinery/ember': minor
---

`@ember-joinery/power-calendar` is a new opt-in add-on, on ember-power-calendar 2:
`PowerCalendar`, `PowerCalendarRange` and `PowerCalendarMultiple`, ember-power-calendar's
calendars drawn as shadcn's Calendar (ghost-Button chevrons around the caption, a grid of ghost
icon Buttons, today shaded, the chosen days filled, a range's middle shaded as one band, each
style's `--cell-size` and `--cell-radius`), and `DatePicker` and `DateRangePicker`, which open one
in a Joinery Popover from an outlined Button or from an Input Group's input that reads typed
dates. Values are `Date`s at local midnight and ranges `{ from, to }`, controlled or not
(`@value`, `@defaultValue`, `@onValueChange`), with `@center` for the month shown, `@minDate`,
`@maxDate`, `@disabledDates` (dates, `YYYY-MM-DD` or weekdays), `@locale`, `@startOfWeek`,
`@weekdayFormat` and `@showDaysAround`; a range takes `@minRange`, `@maxRange` and
`@proximitySelection`, several days `@maxLength`, and the pickers `@trigger`, `@placeholder`,
`@format`, `@id`, `@disabled`, `@invalid`, `@describedBy` and `@open`. The grid is WAI-ARIA's:
one tab stop, the arrow keys (flipped right to left), Home, End, Page Up and Page Down, past
days that can't be chosen, each day named by its full date. A picker's button is named by its
label and the date it shows, and its calendar opens with focus on the chosen day. A native `Date`
and `Intl` date library is registered for ember-power-calendar unless the app has one
(`nativeDateLibrary`, `ensureDateLibrary()`), and `formatDate`, `formatDateRange`, `parseDate`,
`toDate` and `toIsoDate` are exported. Its `/test-support` has `PowerCalendarHarness` and
`DatePickerHarness`. `@ember-joinery/ember`'s style sheets style its parts
(`power-calendar.css`); nothing in the core packages imports it.
