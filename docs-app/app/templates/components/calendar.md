# Calendar

A calendar component that allows users to select a date or a range of dates.

<Example @name="calendar-demo" @title="Calendar" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Calendar } from '@ember-joinery/ember'
```

## Usage

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar } from '@ember-joinery/ember'

export default class Example extends Component {
  @tracked date: Date | undefined = new Date()

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Calendar
      @mode="single"
      @value={{this.date}}
      @onValueChange={{this.setDate}}
      class="rounded-lg border"
    />
  </template>
}
```

`@mode` picks what it selects: `single` (a `Date`), `multiple` (`Date[]`) or `range`
(`{ from, to }`). Pass `@value` and `@onValueChange` to own the selection; with
`@onValueChange` and no `@defaultValue`, the calendar shows `@value` even while it is
`undefined`, as react-day-picker's `selected` and `onSelect` do. Leave both out, or give
`@defaultValue`, and it keeps the selection itself.

Upstream's options are arguments, with upstream's names (`@numberOfMonths`,
`@captionLayout`, `@showWeekNumber`…); see [API Reference](#api-reference).

## About

Upstream's Calendar is built on [React DayPicker](https://react-day-picker.js.org). Joinery's
replaces it with its own, `@ember-joinery/primitives/calendar` (see the
[Calendar primitive](/primitives/calendar.md)), which takes DayPicker's options and renders its
markup, with no date library: dates go in and out as `Date`s at local midnight, and every
name, number and week start comes from `Intl` in `@locale`.

## Date Picker

You can use the `<Calendar>` component to build a date picker, in a
[Popover](/components/popover.md). See the [Date Picker](/components/date-picker.md) page for
more information.

## Persian / Hijri / Jalali Calendar

Upstream swaps `react-day-picker` for `react-day-picker/persian`. Joinery's Calendar works in
any calendar `Intl` knows: pass `@calendar="persian"` (or `islamic-umalqura`, `hebrew`…), with
the locale and numerals to show it in.

```gts
<Calendar
  @mode="single"
  @calendar="persian"
  @locale="fa-IR"
  @numerals="arabext"
  @dir="rtl"
/>
```

<Example @name="calendar-hijri" @title="Persian / Hijri / Jalali Calendar" />

Months and years are the calendar's own (the dropdowns, `@startMonth`, the week numbers);
the dates going in and out are still `Date`s. A locale's own calendar and numbering system
count too, when its tag names them (`fa-IR-u-ca-persian-nu-arabext`); otherwise the calendar is
Gregorian with Latin digits, as react-day-picker's is, whatever the locale.

## Selected Date (With TimeZone)

Upstream's Calendar takes a `timeZone` to keep a selected day from shifting when the server and
the browser are in different time zones. Joinery's works in the browser's time zone: each day
is a `Date` at local midnight, so the 20th is the 20th wherever the page runs. To keep a day in
another zone, store it as its `yyyy-MM-dd` (`isoDate(date)` from
`@ember-joinery/primitives/calendar`, and `parseIsoDate` back).

## Basic

A basic calendar component. We used `class="rounded-lg border"` to style the calendar.

<Example @name="calendar-basic" @title="Basic" />

## Range Calendar

Use `@mode="range"` to enable range selection.

<Example @name="calendar-range" @title="Range Calendar" />

## Month and Year Selector

Use `@captionLayout="dropdown"` to show month and year dropdowns.

<Example @name="calendar-caption" @title="Month and Year Selector" />

## Presets

<Example @name="calendar-presets" @title="Presets" />

## Date and Time Picker

<Example @name="calendar-time" @title="Date and Time Picker" />

## Booked dates

<Example @name="calendar-booked-dates" @title="Booked dates" />

## Custom Cell Size

<Example @name="calendar-custom-days" @title="Custom Cell Size" />

You can customize the size of calendar cells using the `--cell-size` CSS variable. You can also
make it responsive by using breakpoint-specific values:

```gts
<Calendar
  @mode="single"
  @value={{this.date}}
  @onValueChange={{this.setDate}}
  class="rounded-lg border [--cell-size:--spacing(11)] md:[--cell-size:--spacing(12)]"
/>
```

Or use fixed values:

```gts
<Calendar
  @mode="single"
  @value={{this.date}}
  @onValueChange={{this.setDate}}
  class="rounded-lg border [--cell-size:2.75rem] md:[--cell-size:3rem]"
/>
```

The `<:day>` block draws what each day's button shows, as upstream's custom `DayButton`
does: it gets the day, with its `date`, `label` (its number), `outside` and `modifiers`.

## Week Numbers

Use `@showWeekNumber` to show week numbers.

<Example @name="calendar-week-numbers" @title="Week Numbers" />

## RTL

Joinery's Calendar takes its direction from the nearest `dir` (see
[Direction](/primitives/direction.md)), or from `@dir`: right to left, the week runs from the
right, the chevrons turn, and the left arrow moves to the next day. See also the
[Persian calendar](#persian--hijri--jalali-calendar).

<Example @name="calendar-rtl" @title="RTL" @dir="rtl" />

Upstream passes react-day-picker's `arSA` locale and `dir`; Joinery's takes the locale as a
tag, `@locale="ar-SA"`, and its names from `Intl`.

## API Reference

### Calendar

| Argument                 | Type                                                             | Default           | What it does                                                              |
| ------------------------ | ---------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------- |
| `@mode`                  | `"single" \| "multiple" \| "range"`                              |                   | What it selects; without it, the days are text                            |
| `@value`                 | `Date \| Date[] \| { from, to }`                                 |                   | The selection, controlled                                                 |
| `@defaultValue`          | the same                                                         |                   | The first selection, uncontrolled                                         |
| `@onValueChange`         | `(value, { date, modifiers, event }) => void`                    |                   | Called with each new selection, and the day pressed                       |
| `@required`              | `boolean`                                                        | `false`           | Whether pressing the selected day keeps it                                |
| `@min`, `@max`           | `number`                                                         |                   | `multiple`: the fewest and most days; `range`: the fewest and most nights |
| `@excludeDisabled`       | `boolean`                                                        | `false`           | `range`: start again when a range would hold a disabled day               |
| `@month`                 | `Date`                                                           |                   | The first month shown, controlled                                         |
| `@defaultMonth`          | `Date`                                                           | today's           | The first month shown at first                                            |
| `@onMonthChange`         | `(month: Date) => void`                                          |                   | Called with the first day of each new first month                         |
| `@startMonth`            | `Date`                                                           | 100 years back\*  | The earliest month you can go to                                          |
| `@endMonth`              | `Date`                                                           | this year's end\* | The latest month you can go to                                            |
| `@numberOfMonths`        | `number`                                                         | `1`               | How many months it shows                                                  |
| `@pagedNavigation`       | `boolean`                                                        | `false`           | Whether the buttons move by `@numberOfMonths`                             |
| `@captionLayout`         | `"label" \| "dropdown" \| "dropdown-months" \| "dropdown-years"` | `"label"`         | The caption: the month's name, or dropdowns                               |
| `@showOutsideDays`       | `boolean`                                                        | `true`            | Whether the days of the months around each one show                       |
| `@fixedWeeks`            | `boolean`                                                        | `false`           | Whether every month shows six weeks                                       |
| `@showWeekNumber`        | `boolean`                                                        | `false`           | Whether a column of week numbers shows                                    |
| `@hideWeekdays`          | `boolean`                                                        | `false`           | Whether the weekday names are left out                                    |
| `@hideNavigation`        | `boolean`                                                        | `false`           | Whether the previous and next buttons are left out                        |
| `@disableNavigation`     | `boolean`                                                        | `false`           | Whether you can't move to another month                                   |
| `@disabled`              | `Matcher \| Matcher[]`                                           |                   | The days you can't select                                                 |
| `@hidden`                | `Matcher \| Matcher[]`                                           |                   | The days that aren't shown                                                |
| `@modifiers`             | `Record<string, Matcher \| Matcher[]>`                           |                   | Modifiers of your own                                                     |
| `@modifiersClassNames`   | `Record<string, string>`                                         |                   | A class for each modifier, on the day's cell                              |
| `@today`                 | `Date`                                                           | today             | The day counted as today                                                  |
| `@locale`                | `string` (BCP 47)                                                | `"en-US"`         | The language of its names, and where its weeks start                      |
| `@calendar`              | `string` (Intl's calendar)                                       | `"gregory"`       | The calendar: `persian`, `islamic-umalqura`, `hebrew`…                    |
| `@numerals`              | `string` (Intl's numbering system)                               | `"latn"`          | The digits: `arab`, `arabext`…                                            |
| `@weekStartsOn`          | `0`–`6`                                                          | the locale's      | The first day of the week, 0 for Sunday                                   |
| `@firstWeekContainsDate` | `number`                                                         | the locale's      | Which day of the year week 1 holds                                        |
| `@dir`                   | `"ltr" \| "rtl"`                                                 | the document's    | The text direction                                                        |
| `@autoFocus`             | `boolean`                                                        | `false`           | Whether it takes focus as it renders                                      |
| `@labels`                | `Partial<CalendarLabels>`                                        | English           | The names of its parts, for assistive technology                          |
| `@formatters`            | `Partial<CalendarFormatters>`                                    | Intl              | How it formats captions, days and dropdowns                               |
| `@onDayClick`            | `(date, modifiers, event) => void`                               |                   | Called with each day pressed                                              |
| `@buttonVariant`         | a Button `@variant`                                              | `"ghost"`         | The look of the previous and next buttons                                 |
| `@name`                  | `string`                                                         |                   | Its name, for `CalendarHarness` (`data-test-jn-name`)                     |

\* With a year dropdown (`@captionLayout="dropdown"` or `"dropdown-years"`); otherwise there is
no bound.

A `Matcher` is react-day-picker's: `true`, a `Date`, an array of them, `{ from, to }`,
`{ before }`, `{ after }`, both, `{ dayOfWeek: [0, 6] }`, or a function of the date. Attributes
go on the root `<div>`.

The `<:day as |day|>` block replaces what each day's button shows (`{{day.label}}` by
default). `CalendarLabels` and `CalendarFormatters` are react-day-picker's `labels` and
`formatters`, each a function of the date and the calendar's `CalendarLocale` (whose
`format(date, options)` is `Intl.DateTimeFormat` in its locale, calendar and numerals):

| Label                   | Default                                                |
| ----------------------- | ------------------------------------------------------ |
| `labelDayButton`        | `Today, Monday, January 12, 2026, selected` (as it is) |
| `labelGridcell`         | the same, without `selected`, when the days are text   |
| `labelGrid`             | `January 2026`                                         |
| `labelPrevious`         | `Go to the Previous Month`                             |
| `labelNext`             | `Go to the Next Month`                                 |
| `labelMonthDropdown`    | `Choose the Month`                                     |
| `labelYearDropdown`     | `Choose the Year`                                      |
| `labelWeekday`          | `Sunday`                                               |
| `labelWeekNumber`       | `Week 3`                                               |
| `labelWeekNumberHeader` | `Week Number`                                          |
| `labelNav`              | none                                                   |

| Formatter                | Default                                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `formatCaption`          | `January 2026`                                                                                                   |
| `formatDay`              | `12`                                                                                                             |
| `formatMonthDropdown`    | `Jan`, as upstream's (react-day-picker's is `January`)                                                           |
| `formatYearDropdown`     | `2026`                                                                                                           |
| `formatWeekdayName`      | `Su` (Intl's short name; two letters in English, as date-fns', and the narrow one where the short one is a word) |
| `formatWeekNumber`       | `03`                                                                                                             |
| `formatWeekNumberHeader` | none                                                                                                             |

### Data attributes

The markup is react-day-picker's, with its `rdp-*` classes, which Joinery's styles hang on:

| Part               | `class`                                                                        | Data attributes                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Root               | `jn-calendar rdp-root`, `data-slot="calendar"`                                 | `data-mode`, `data-required`, `data-multiple-months`, `data-week-numbers`                                                |
| Previous, next     | a ghost Button's, and `rdp-button_previous`/`_next`                            | `aria-disabled` at the ends                                                                                              |
| Month, its caption | `rdp-month`, `rdp-month_caption`, `rdp-caption_label`                          |                                                                                                                          |
| Dropdowns          | `rdp-dropdown_root`, a `<select class="rdp-dropdown">`                         |                                                                                                                          |
| Grid               | `rdp-month_grid`, `role="grid"`                                                | `aria-label`, `aria-multiselectable`                                                                                     |
| Day cell           | `rdp-day` and its modifiers' (`rdp-today`, `rdp-selected`, `rdp-range_start`…) | `data-day` (`yyyy-MM-dd`), `data-selected`, `data-disabled`, `data-hidden`, `data-outside`, `data-focused`, `data-today` |
| Day button         | an icon Button's, `jn-calendar-day-button`, `rdp-day_button`                   | `data-day`, `data-selected-single`, `data-range-start`, `data-range-middle`, `data-range-end`                            |

The root also has `data-test-jn="calendar"` and `data-test-jn-name`; the parts have
`data-test-jn-part` (`nav`, `previous`, `next`, `month`, `caption`, `month-dropdown`,
`year-dropdown`, `grid`, `weekday`, `week`, `week-number`, `day`, `day-button`), and each
month, day and day button `data-test-jn-value` (its `yyyy-MM-dd`).

## Keyboard interactions

| Key                                 | What it does                                        |
| ----------------------------------- | --------------------------------------------------- |
| `Tab`                               | Moves focus to the day in the tab order, and on out |
| `ArrowLeft`, `ArrowRight`           | The previous or next day (flipped right to left)    |
| `ArrowUp`, `ArrowDown`              | The same day of the previous or next week           |
| `PageUp`, `PageDown`                | The same day of the previous or next month          |
| `Shift` + `PageUp`, `PageDown`      | The same day of the previous or next year           |
| `Shift` + `ArrowLeft`, `ArrowRight` | The previous or next month                          |
| `Shift` + `ArrowUp`, `ArrowDown`    | The previous or next year                           |
| `Home`, `End`                       | The first or last day of the week                   |
| `Enter`, `Space`                    | Selects the focused day (or lets it go)             |

That is the [APG date picker dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/)'s
grid, with react-day-picker's keys. A move skips disabled days, stops at `@startMonth` and
`@endMonth`, and shows the month it lands in (with `@disableNavigation`, it stays in the months
shown). One day is in the tab order: the focused day, else the one focused last, the selected
day, today, or the month's first.

## Accessibility

- Each month is a `role="grid"` named by its month, its weeks rows and its days `gridcell`s
  with `aria-selected`. Each day is a button named by its full date (`Today, Thursday, January
15, 2026, selected`), so the weekday headings are hidden from assistive technology, as
  react-day-picker's are. The caption is a polite live region, so a new month is announced.
- The month and year dropdowns are native `<select>`s, invisible over their labels, so they
  work with every assistive technology and on touch.
- Upstream's week numbers are `td`s with `scope="row"`, which HTML allows only on a `th`
  (axe's `scope-attr-valid`); Joinery's keep `role="rowheader"` and leave the scope off.
- Every name is English by default; `@labels` gives words of your own, or another language.
- The custom days example puts each day's price in its button's name, which starts with what
  the button shows (WCAG 2.5.3, axe's `label-content-name-mismatch`); upstream's names only the
  date.

## Testing

`CalendarHarness` from `@ember-joinery/test-support` drives a `<Calendar>` (or the headless
one). A day is a `Date` or `yyyy-MM-dd`:

```ts
import { CalendarHarness } from '@ember-joinery/test-support'

const calendar = new CalendarHarness('booking') // <Calendar @name="booking">
await calendar.select('2026-01-12')
assert.deepEqual(calendar.selectedDays, ['2026-01-12'])
await calendar.press('ArrowRight')
assert.strictEqual(calendar.focusedDay, '2026-01-13')
await calendar.chooseYear(1990)
```

| Member                                                                 | What it is                                                        |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `mode`                                                                 | Its `@mode`, or `null`                                            |
| `caption`, `captions`                                                  | The first month's caption, and every month's                      |
| `months`, `monthLabels`, `grids`                                       | Each month shown: its first day, its grid's name, its grid        |
| `weekdays`, `weekdayLabels`, `weekNumbers`                             | The column headings and their full names, and the week numbers    |
| `cells`, `cell(day)`, `button(day)`                                    | The day cells, one day's cell, its button                         |
| `dayText(day)`, `dayLabel(day)`                                        | What a day shows, and its name                                    |
| `isSelected`, `isDisabled`, `isToday`, `isOutside`, `isHidden`         | A day's state                                                     |
| `rangePosition(day)`                                                   | `start`, `middle`, `end` or `null`                                |
| `selectedDays`, `selected`, `disabledDays`                             | The selected days (`yyyy-MM-dd`, or dates), and the disabled ones |
| `focusedDay`, `tabStop`                                                | The day with focus, and the one in the tab order                  |
| `previous()`, `next()`, `canGoPrevious`, `canGoNext`                   | The month buttons                                                 |
| `monthDropdown()`, `yearDropdown()`, `monthOptions()`, `yearOptions()` | The dropdowns and their options (of month 0, or the index given)  |
| `chooseMonth(month)`, `chooseYear(year)`                               | Picks in the dropdowns: a month's index or text, a year           |
| `select(day)`, `selectAll(...days)`                                    | Presses days                                                      |
| `focus(day)`, `press(key, { shiftKey })`                               | Moves focus to a day, and presses a key there                     |

## Upstream

shadcn/ui's [Calendar](https://ui.shadcn.com/docs/components/radix/calendar), from
`apps/v4/registry/bases/radix/ui/calendar.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
