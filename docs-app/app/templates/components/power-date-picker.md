# Power Date Picker

A date picker: a Power Calendar in a Popover, opened from a button or an input.

<div class="callout">

**An opt-in add-on.** Power Date Picker is in `@ember-joinery/power-calendar`, built on
[ember-power-calendar](https://ember-power-calendar.com) 2, which nothing in Joinery's core
packages imports. Its installation is [Power Calendar's](/components/power-calendar.md).

</div>

`DatePicker` is shadcn's [Date Picker](https://ui.shadcn.com/docs/components/radix/date-picker),
made one component: a Joinery [Popover](/components/popover.md) holding a
[Power Calendar](/components/power-calendar.md), opened from an outlined Button that shows the
date (as upstream's date-picker-demo), or from an Input Group's input it can be typed into (as
date-picker-input). Its examples port Formwright's date-picker control as a standalone
component.

<Example @name="power-date-picker-demo" @title="Power Date Picker" />

## Usage

```gts
import { DatePicker } from '@ember-joinery/power-calendar'

<Field>
  <FieldLabel for="check-in">Check-in</FieldLabel>
  <DatePicker @id="check-in" @value={{this.checkIn}} @onValueChange={{this.setCheckIn}} />
</Field>
```

The button shows the date, written with `Intl.DateTimeFormat` in `@locale` (`@format` takes its
options; `{ dateStyle: 'long' }` by default), or `@placeholder` (`Pick a date`) in the muted
colour. A press opens the calendar on the date's month with focus on the date (else on today);
choosing a day closes it and puts focus back on the button. Escape, or a press outside, closes
it with the date unchanged.

The value is a `Date` at local midnight, controlled or not (`@value`, `@defaultValue`,
`@onValueChange`), and so is the popover (`@open`, `@defaultOpen`, `@onOpenChange`). Every
[Power Calendar](/components/power-calendar.md#api-reference) argument reaches the calendar:
`@minDate`, `@maxDate`, `@disabledDates`, `@startOfWeek` and the rest.

A [DateRangePicker](/components/power-date-range-picker.md) picks a range the same way.

## Weekdays only, written in full

Formwright's inline date picker, as a picker of its own: `@format` writes the date in full, and
`@minDate`, `@maxDate` and `@disabledDates` leave a weekday in November or December.

<Example @name="power-date-picker-weekdays" @title="Weekdays in November and December" />

## Input

With `@trigger="input"`, the date is typed into an input (an Input Group's), with a calendar
button at its end, as upstream's date-picker-input. Typed text that names a day, with its year
(`June 1, 2025`, `2025-06-01`, `6/1/2025` in English), becomes the value as it is typed; leaving
the input writes it back in `@format`, and emptying it clears the value. ArrowDown in the input,
or a press on the button, opens the calendar; a choice, or Escape, puts focus back in the input.
The calendar opens at the button's end, as upstream's.

<Example @name="power-date-picker-input" @title="Input" />

## RTL

Right to left, the button's chevron is on the left, the calendar's week runs from the right and
its arrow keys flip.

<Example @name="power-date-picker-rtl" @title="RTL" @dir="rtl" />

## API Reference

### DatePicker

| Argument                                 | Type                         | Default                                                | What it does                                                                  |
| ---------------------------------------- | ---------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------- |
| `@value`                                 | `Date \| null`               |                                                        | The day chosen. Pass it (even `undefined`) to control it                      |
| `@defaultValue`                          | `Date \| null`               |                                                        | The day first chosen, uncontrolled                                            |
| `@onValueChange`                         | `(date: Date \| undefined)`  |                                                        | Called with the day chosen or typed, or `undefined` when the input is emptied |
| `@open`, `@defaultOpen`, `@onOpenChange` | `boolean`                    | `false`                                                | The popover, controlled or not                                                |
| `@trigger`                               | `'button' \| 'input'`        | `button`                                               | What opens it                                                                 |
| `@id`                                    | `string`                     |                                                        | The button's (or input's) id, for a `<label for>`                             |
| `@placeholder`                           | `string`                     | `Pick a date`                                          | What shows with no date                                                       |
| `@format`                                | `Intl.DateTimeFormatOptions` | `{ dateStyle: 'long' }`                                | How the date is written                                                       |
| `@locale`                                | `string`                     | the browser's                                          | The date's and the calendar's language                                        |
| `@disabled`, `@invalid`                  | `boolean`                    | `false`                                                | It can't be opened; it is `aria-invalid`                                      |
| `@describedBy`                           | `string`                     |                                                        | The ids that describe it (`aria-describedby`)                                 |
| `@icon`, `@iconPosition`                 | lucide icon \| `null`, side  | `chevron-down`, `inline-end` (`calendar` for an input) | The button's icon, and its side                                               |
| `@triggerLabel`                          | `string`                     | `Select date`                                          | The calendar button's name, with an input                                     |
| `@align`, `@side`                        | Popover's                    | `start` (`end` for an input), `bottom`                 | Where the calendar opens                                                      |
| `@name`                                  | `string`                     |                                                        | Its name, for `DatePickerHarness`                                             |

The calendar's arguments (`@minDate`, `@maxDate`, `@disabledDates`, `@startOfWeek`,
`@showDaysAround`, `@weekdayFormat`, `@label`, `@previousMonthLabel`, `@nextMonthLabel`) are Power
Calendar's. The caller's attributes (a `class`, a width) go on the button, or with an input on
the Input Group. The button is an outline Button with `data-slot="date-picker"`, `data-empty`,
`data-test-jn="date-picker"` and the Popover trigger's `aria-haspopup`, `aria-expanded` and
`aria-controls`; the popover's content is `w-auto p-0`, as upstream's.

## Keyboard interactions

| Key                       | What it does                                                               |
| ------------------------- | -------------------------------------------------------------------------- |
| `Enter`, `Space`          | On the button, opens the calendar, with focus on the date (else today)     |
| `ArrowDown`               | In the input, opens the calendar                                           |
| The calendar's keys       | As [Power Calendar's](/components/power-calendar.md#keyboard-interactions) |
| `Enter`, `Space` on a day | Chooses it, closes the calendar and puts focus back on the button or input |
| `Escape`                  | Closes the calendar, the date unchanged                                    |

## Accessibility

- A `<label for>` names a button by the label's text alone, so the date it shows would go
  unread. Once the button has a label, its name is the label's text and then the date (its
  `aria-labelledby`, giving the label an id if it has none): "Check-in November 12, 2026". With
  no label, its text names it.
- The popover is a `dialog` named by its trigger, non-modal, as upstream's; focus moves to the
  calendar's chosen day (or today) rather than its first button, as WAI-ARIA's date picker
  dialog does.
- With an input, the calendar button is named by `@triggerLabel`, and the input by its label.

## Testing

`DatePickerHarness`, from `@ember-joinery/power-calendar/test-support`, drives a DatePicker or a
DateRangePicker, with a button or an input: it opens the calendar, pages to the month and presses
the day, as a user does. The open calendar is `calendar`, a
[`PowerCalendarHarness`](/components/power-calendar.md#testing). Each example's **Test** tab uses
it.

```ts
import { DatePickerHarness } from '@ember-joinery/power-calendar/test-support'

const checkIn = new DatePickerHarness('check-in') // <DatePicker @name="check-in">
await checkIn.select('2026-03-04')
assert.strictEqual(checkIn.text, 'March 4, 2026')
assert.false(checkIn.isOpen)
```

| Member                                         | What it is                                                          |
| ---------------------------------------------- | ------------------------------------------------------------------- |
| `trigger`, `input`                             | The button (or the calendar button beside the input), and the input |
| `text`, `isEmpty`, `placeholder`               | What it shows, whether there is no date, the placeholder            |
| `label`, `triggerLabel`                        | Its accessible name; the calendar button's, with an input           |
| `isRange`, `isOpen`, `isDisabled`, `isInvalid` | Its state                                                           |
| `content`, `calendar`                          | The open popover, and a `PowerCalendarHarness` for its calendar     |
| `open()`, `close()`                            | Opens it with a press on the trigger; closes it with Escape         |
| `select(date)`, `selectRange(from, to)`        | Opens it and presses the days                                       |
| `typeDate(text)`, `pressKeyInInput(key)`       | Types into the input and leaves it; presses a key in the input      |

## Built on

ember-power-calendar's calendar, in Joinery's Popover (the top layer, anchored to the trigger)
rather than ember-basic-dropdown, which Formwright's `@ember-formwright/power-calendar` uses;
there is no wormhole to render.
