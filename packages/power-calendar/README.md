# @ember-joinery/power-calendar

Calendars and date pickers in shadcn/ui's look for Ember, an opt-in add-on to
[Joinery](https://joegaudet.com/ember-joinery/), on
[ember-power-calendar](https://ember-power-calendar.com) 2: a calendar to choose a day, a range or
several days, and pickers that open one in a Popover from a button or an input. Dates are the
browser's `Date`, worked out and written with `Intl`; there is no date library to install.

```bash
pnpm add @ember-joinery/power-calendar @ember-joinery/ember ember-concurrency
```

`ember-power-calendar` comes with it; `ember-concurrency`, its peer, goes beside it. Nothing in
Joinery's core packages imports this one, so an app that doesn't install it doesn't load
ember-power-calendar. It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any
of its styles) styles its parts, as it does every Joinery component, and ember-power-calendar's
own style sheet isn't needed.

```gts
import {
  DatePicker,
  DateRangePicker,
  PowerCalendar,
  PowerCalendarMultiple,
  PowerCalendarRange,
} from '@ember-joinery/power-calendar'

<template>
  {{! a calendar, a day at a time: shadcn's Calendar }}
  <PowerCalendar @value={{this.date}} @onValueChange={{this.setDate}} class="rounded-lg border" />

  {{! { from, to } }}
  <PowerCalendarRange @value={{this.stay}} @onValueChange={{this.setStay}} />

  {{! a Date[] }}
  <PowerCalendarMultiple @value={{this.days}} @onValueChange={{this.setDays}} @maxLength={{3}} />

  {{! shadcn's Date Picker: a Popover from an outlined Button, or from an input }}
  <DatePicker @value={{this.due}} @onValueChange={{this.setDue}} />
  <DatePicker @trigger="input" @id="due" @value={{this.due}} @onValueChange={{this.setDue}} />
  <DateRangePicker @value={{this.stay}} @onValueChange={{this.setStay}} />
</template>
```

Values are `Date`s at local midnight, and ranges `{ from, to }`, as Joinery's (and shadcn's)
Calendar has them; each is controlled or not (`@value`, `@defaultValue`, `@onValueChange`). The
month shown is `@center` (`@defaultCenter`, `@onCenterChange`). Every calendar takes `@minDate`,
`@maxDate`, `@disabledDates` (dates, `YYYY-MM-DD` strings or weekdays such as `'Sat'`),
`@locale`, `@startOfWeek`, `@weekdayFormat` and `@showDaysAround`; a range also `@minRange`,
`@maxRange` and `@proximitySelection`, and several days `@maxLength`. The pickers take
`@placeholder`, `@format` (`Intl.DateTimeFormat` options), `@id`, `@disabled`, `@invalid`,
`@describedBy`, `@open` and the calendar's options. Every string is an argument with an English
default.

The day grid is WAI-ARIA's grid: one tab stop (the chosen day, else today), the arrow keys by a
day or a week (flipped right to left), Home and End to the week's ends, Page Up and Page Down by a
month (with Shift, a year), past the days that can't be chosen.

Its harnesses, `PowerCalendarHarness` and `DatePickerHarness`, are in
`@ember-joinery/power-calendar/test-support`:

```ts
import { DatePickerHarness, PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'

const due = new DatePickerHarness('due') // <DatePicker @name="due">
await due.select('2026-03-04') // opens it, pages to March 2026 and presses the 4th
assert.strictEqual(due.text, 'March 4, 2026')

const stay = new PowerCalendarHarness('stay')
await stay.selectRange('2026-03-04', '2026-03-09')
assert.deepEqual(stay.selected.length, 6)
```

Full documentation: the Power Calendar and Date Picker pages of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Built on
[ember-power-calendar](https://github.com/ember-power-addons/ember-power-calendar) (MIT); design
from [shadcn/ui](https://ui.shadcn.com/) (MIT).
