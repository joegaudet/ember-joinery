# Power Calendar

A calendar to choose a day, in shadcn's Calendar look, on ember-power-calendar.

<div class="callout">

**An opt-in add-on.** Power Calendar is its own package, `@ember-joinery/power-calendar`, built
on [ember-power-calendar](https://ember-power-calendar.com) 2. Nothing in Joinery's core packages
imports it, so an app that doesn't install it doesn't load ember-power-calendar. For a calendar
with no dependency at all, Joinery's own Calendar, in `@ember-joinery/ember`, ports shadcn's.

</div>

`PowerCalendar` is ember-power-calendar's calendar (its days, its selection, its month paging)
drawn as shadcn's [Calendar](https://ui.shadcn.com/docs/components/radix/calendar): the month's
caption between ghost Buttons for the previous and next month, over a grid of the month's days,
each a ghost icon Button. Today is shaded and the chosen day filled. It follows the style, base
colour and radius you pick: each style's Calendar rule sets its padding, `--cell-size` and
`--cell-radius`. [Power Calendar Range](/components/power-calendar-range.md) and
[Power Calendar Multiple](/components/power-calendar-multiple.md) choose a range or several days,
and the [Power Date Picker](/components/power-date-picker.md) opens one in a Popover.

<Example @name="power-calendar-demo" @title="Power Calendar" />

## Installation

Power Calendar is an add-on, so it comes in its own package, with ember-power-calendar as a
dependency and ember-concurrency, its peer, beside it:

```bash
pnpm add @ember-joinery/power-calendar @ember-joinery/ember ember-concurrency
```

It ships no CSS of its own, and ember-power-calendar's style sheet isn't needed: Joinery's
`joinery.css` (or any of its styles) styles its parts, as it does every component. Import that
once (see [Installation](/getting-started/installation.md)), then the components where you use
them:

```gts
import { PowerCalendar } from '@ember-joinery/power-calendar'
```

ember-power-calendar works its dates out through a "date library" an app registers (its moment and
luxon packages are two). This add-on registers one built on the browser's `Date` and `Intl` as
its first calendar is made, unless the app registered one already, so there is nothing to set up
and no date package to install. It exports it too, as `nativeDateLibrary` (and
`ensureDateLibrary()`), for an app that registers it itself.

## Usage

```gts
<PowerCalendar @value={{this.date}} @onValueChange={{this.setDate}} class="rounded-lg border" />
```

The value is a `Date` at local midnight. Pressing a day chooses it; pressing the chosen day again
clears it (`undefined`), as upstream's does, unless the calendar is `@required`. The value is
controlled or not, as in Joinery's other components: pass `@value` (even while it is
`undefined`) and keep what `@onValueChange` sends, or pass `@defaultValue` and leave the rest to
the calendar.

The month shown is the chosen day's, else today's. `@defaultCenter` starts it elsewhere, and
`@center` (any day in the month) controls it, with `@onCenterChange` hearing each change the
nav buttons or the keyboard make.

## Days that can't be chosen

`@minDate` and `@maxDate` (a `Date` or `YYYY-MM-DD`) bound the days, and the months outside
them can't be shown: their nav button is `aria-disabled`. `@disabledDates` takes days that can't
be chosen: `Date`s, `YYYY-MM-DD` strings, or weekdays (`'Sat'`, `'Sun'`), as ember-power-calendar
reads them. Formwright's weekday picker, as a calendar of its own:

<Example @name="power-calendar-disabled-days" @title="Weekdays in November and December" />

## Locale, week and weekdays

`@locale` (a BCP 47 locale) names the month, the weekdays and each day, and starts the week on
the locale's first day, unless `@startOfWeek` (0 for Sunday to 6) says otherwise.
`@weekdayFormat` writes the weekdays over the columns `short` (`Mon`, the default), `min` (`M`)
or `long`; each header's accessible name is the weekday in full. `@showDaysAround={{false}}`
leaves the first and last weeks' days of the months around blank.

## RTL

Joinery's components take their direction from the nearest `dir`, which a
`DirectionProvider` sets. Right to left, the week runs from the right, the previous
month's button is on the right with its chevron mirrored, and the arrow keys flip.

<Example @name="power-calendar-rtl" @title="RTL" @dir="rtl" />

## API Reference

### PowerCalendar

| Argument                                 | Type                         | Default                        | What it does                                                         |
| ---------------------------------------- | ---------------------------- | ------------------------------ | -------------------------------------------------------------------- |
| `@value`                                 | `Date \| null`               |                                | The day chosen. Pass it (even `undefined`) to control it             |
| `@defaultValue`                          | `Date \| null`               |                                | The day chosen first, uncontrolled                                   |
| `@onValueChange`                         | `(date: Date \| undefined)`  |                                | Called with each day chosen, or `undefined` when it is cleared       |
| `@required`                              | `boolean`                    | `false`                        | Pressing the chosen day keeps it                                     |
| `@center`, `@defaultCenter`              | `Date`                       | the value's, or today          | The month shown, controlled or first                                 |
| `@onCenterChange`                        | `(center: Date)`             |                                | Called with a day of the month shown, whenever it changes            |
| `@minDate`, `@maxDate`                   | `Date \| string`             |                                | The first and last days that can be chosen (`YYYY-MM-DD` too)        |
| `@disabledDates`                         | `Array<Date \| string>`      |                                | Days that can't be chosen: dates, `YYYY-MM-DD`, weekdays (`'Sat'`)   |
| `@locale`                                | `string`                     | the browser's                  | The month's, the weekdays' and the days' language                    |
| `@startOfWeek`                           | `number`                     | the locale's                   | The week's first day, 0 (Sunday) to 6                                |
| `@weekdayFormat`                         | `'min' \| 'short' \| 'long'` | `short`                        | How the weekdays are written over the columns                        |
| `@showDaysAround`                        | `boolean`                    | `true`                         | Show the days of the months around, to fill the first and last weeks |
| `@disabled`                              | `boolean`                    | `false`                        | No day can be chosen (the months still page)                         |
| `@label`                                 | `string`                     | `Choose date`                  | The calendar's accessible name                                       |
| `@previousMonthLabel`, `@nextMonthLabel` | `string`                     | `Previous month`, `Next month` | The nav buttons' names                                               |
| `@name`                                  | `string`                     |                                | Its name, for `PowerCalendarHarness`                                 |

Its attributes (a `class`, a size such as `[--cell-size:--spacing(10)]`) go on
ember-power-calendar's root, a `group`.

### Data attributes

| Element              | Attributes                                                                                                                                           |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| The root             | `data-slot="calendar"`, `data-disabled`, `data-test-jn="power-calendar"`, `data-test-jn-name`                                                        |
| The grid             | `data-slot="calendar-grid"`, `data-test-jn-part="grid"`                                                                                              |
| A day's cell         | `data-day`, `data-selected`, `data-today`, `data-outside`, `data-disabled`, `data-hidden`, `data-range-start`, `data-range-middle`, `data-range-end` |
| A day                | `data-date` (`YYYY-MM-DD`), `data-selected-single`, `data-range-*` (`true`/`false`), `data-test-jn-part="day"`, `data-test-jn-value`                 |
| The caption, the nav | `data-test-jn-part="caption"`, `"previous"`, `"next"`; each weekday header `"weekday"`                                                               |

## Keyboard interactions

| Key                       | What it does                                                                                |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| `Tab`                     | Into the grid, on the chosen day, else today, else the month's first day that can be chosen |
| `ArrowLeft`, `ArrowRight` | The day before or after (flipped right to left)                                             |
| `ArrowUp`, `ArrowDown`    | The same day a week before or after                                                         |
| `Home`, `End`             | The week's first or last day                                                                |
| `PageUp`, `PageDown`      | The same day a month before or after; with `Shift`, a year                                  |
| `Enter`, `Space`          | Chooses the day                                                                             |

Each key passes over the days that can't be chosen, and shows another month when the day it
lands on is in one. This is WAI-ARIA's date picker grid; ember-power-calendar's own days move by
the arrow keys alone, the same way in both directions.

## Accessibility

- The calendar is a `group` named by `@label`. Its days are a `grid` named by the month's
  caption, which announces itself (`aria-live`) as the month changes; each weekday header is a
  `columnheader` named by the weekday in full.
- Each day is a button that is the grid's cell (`role="gridcell"`), named by its full date
  ("Wednesday, March 4, 2026"), with `aria-selected`, and `aria-current="date"` on today. A day
  that can't be chosen is `disabled`.
- The grid has one tab stop, so Tab passes through it in one step. ember-power-calendar's own
  days leave every day out of the tab order until one has focus; these don't.
- react-day-picker's nav is a `<nav>`; this one is a plain group of two buttons, so a page with
  several calendars doesn't repeat a landmark that navigates nowhere.

## Testing

`PowerCalendarHarness`, from `@ember-joinery/power-calendar/test-support`, drives all three
calendars. Days are `YYYY-MM-DD` strings: it pages to a day's month with the nav buttons and
presses the day, as a user does, and reads the state from the grid's ARIA. Each example's
**Test** tab uses it.

```ts
import { PowerCalendarHarness } from '@ember-joinery/power-calendar/test-support'

const calendar = new PowerCalendarHarness('due') // <PowerCalendar @name="due">
await calendar.select('2026-03-04')
assert.deepEqual(calendar.selected, ['2026-03-04'])
assert.strictEqual(calendar.month, 'March 2026')
await calendar.focusDay('2026-03-04')
await calendar.pressKey('ArrowRight')
assert.strictEqual(calendar.focusedDay, '2026-03-05')
```

| Member                                                                 | What it is                                                              |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `kind`                                                                 | `single`, `range` or `multiple`                                         |
| `label`, `month`, `shownMonth`                                         | Its name, the caption ("March 2026") and the month shown (`2026-03`)    |
| `weekdays`, `weekdayNames`                                             | The weekday headers as they read, and in full                           |
| `days`, `selected`, `today`, `tabStop`, `focusedDay`                   | The month's days, the chosen ones, today, the tab stop, the focused day |
| `day(date)`, `anyDay(date)`, `dayLabel(date)`                          | A day's button in the month shown (or around it), and its name          |
| `isDayDisabled(date)`, `isDaySelected(date)`                           | A day's state, in the month shown                                       |
| `previousButton`, `nextButton`, `isPreviousDisabled`, `isNextDisabled` | The nav buttons, and whether they do nothing                            |
| `previousMonth()`, `nextMonth()`, `goTo(date)`                         | Pages a month, or to a day's month                                      |
| `select(date)`, `selectRange(from, to)`, `selectDays(...dates)`        | Presses days                                                            |
| `focusDay(date)`, `pressKey(key, modifiers)`                           | Focuses a day; presses a key on the focused element                     |

## Built on

[ember-power-calendar](https://ember-power-calendar.com) 2: its `PowerCalendar` component holds
the selection and the month and pages it (an ember-concurrency task), and its Days component
builds the days and tracks focus, subclassed here to draw shadcn's markup and to move as
WAI-ARIA's grid does. Formwright's `@ember-formwright/power-calendar` offers its date pickers as
form controls; this package is the standalone components, for use without a form library.
