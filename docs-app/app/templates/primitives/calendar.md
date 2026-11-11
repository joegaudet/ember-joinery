# Calendar

A calendar to pick a day, several days or a range: Joinery's replacement for React DayPicker,
which upstream's Calendar is built on. It takes DayPicker's options and renders DayPicker's
markup, with its `rdp-*` classes, or yours, and no styles; the styled
[Calendar](/components/calendar.md) renders the same from the same state, in shadcn's style.

<Example @name="calendar-headless" @title="Up to five days off, on weekdays" />

## Usage

```gts
import { Calendar } from '@ember-joinery/primitives/calendar'

<template>
  <Calendar
    @mode="range"
    @numberOfMonths={{2}}
    @value={{this.range}}
    @onValueChange={{this.setRange}}
    @classNames={{this.classes}}
  />
</template>
```

- **No date library.** Days go in and out as `Date`s at local midnight, a range as
  `{ from, to }`, and day arithmetic is native. Names, numbers and week starts come from `Intl`
  in `@locale` (`en-US` by default, as DayPicker's), so `@locale="es"` starts the week on a
  Monday and names it `lunes`. `@calendar` takes any calendar `Intl` knows (`persian`,
  `islamic-umalqura`, `hebrew`…), whose months are worked out from `Intl`'s own reading of each
  day; `@numerals` the digits (`arabext`).
- **Selection.** `@mode` is `single`, `multiple` or `range`. `@value` with `@onValueChange`
  controls it (even unset, as DayPicker's `selected` with `onSelect`); `@defaultValue`, or
  neither, leaves it to the calendar. `@required`, `@min`, `@max` and `@excludeDisabled` are
  DayPicker's.
- **Months.** `@month`, `@defaultMonth` and `@onMonthChange` are the first month shown;
  `@numberOfMonths` shows more, `@startMonth` and `@endMonth` bound them, and
  `@captionLayout="dropdown"` gives each month a month and a year `<select>`.
- **Days.** `@disabled`, `@hidden` and `@modifiers` take matchers (a date, dates,
  `{ from, to }`, `{ before }`, `{ after }`, `{ dayOfWeek }`, a function); a day's cell gets a
  class for each modifier it has (`rdp-today`, `rdp-selected`…, or `@modifiersClassNames`'),
  and `data-*` attributes for its state.
- **Classes.** `@classNames` replaces DayPicker's class for any part or state: `root`,
  `months`, `month`, `nav`, `button_previous`, `button_next`, `chevron`, `month_caption`,
  `caption_label`, `dropdowns`, `dropdown_root`, `dropdown`, `months_dropdown`,
  `years_dropdown`, `month_grid`, `weekdays`, `weekday`, `weeks`, `week`, `week_number_header`,
  `week_number`, `day`, `day_button`, and the states `today`, `outside`, `disabled`, `hidden`,
  `focused`, `selected`, `range_start`, `range_middle`, `range_end`.
- **Blocks.** `<:chevron as |orientation className|>` draws the chevrons (`left`, `right`, or
  `down` in a dropdown) in place of DayPicker's; `<:day as |day|>` draws what a day's button
  shows.

The state behind it is `CalendarState`, which the styled Calendar renders from too: build one
with `new CalendarState(() => this.args)` for markup of your own. The module also exports its
date helpers: `addDays`, `startOfDay`, `isSameDay`, `isoDate` and `parseIsoDate` (`yyyy-MM-dd`
in local time), `isMatch(date, matchers)`, `rangeIncludesDate`, `addToRange` (DayPicker's),
`calendarSystem(id)` (a calendar's months and years), `calendarLocale(locale, calendar,
numerals)` (its Intl formatting) and `weekInfo(locale)`.

## API

It takes every argument of the styled [Calendar](/components/calendar.md#api-reference) but
`@buttonVariant`, with DayPicker's defaults (`@showOutsideDays` is `false`), and:

| Argument      | Type                          | What it does                                              |
| ------------- | ----------------------------- | --------------------------------------------------------- |
| `@classNames` | `Partial<CalendarClassNames>` | A class for each part and state, in place of `rdp-<part>` |

The keyboard, the grid's ARIA and `CalendarHarness` are the styled Calendar's: see its
[Keyboard interactions](/components/calendar.md#keyboard-interactions) and
[Testing](/components/calendar.md#testing).
