# Date Picker

A date picker component with range and presets.

<Example @name="date-picker-demo" @title="Date Picker" />

## Installation

The Date Picker is built using a composition of the [Popover](/components/popover.md) and the
[Calendar](/components/calendar.md) components, so it comes with `@ember-joinery/ember`:

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Button, Calendar, Popover } from '@ember-joinery/ember'
```

## Usage

```gts
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Calendar as CalendarIcon } from 'lucide'
import { Button, Calendar, Icon, Popover } from '@ember-joinery/ember'

const format = (date: Date) => date.toLocaleDateString('en-US', { dateStyle: 'long' })

export default class ExampleDatePicker extends Component {
  @tracked date: Date | undefined

  setDate = (date: Date | undefined) => (this.date = date)

  <template>
    <Popover as |p|>
      <Button
        @variant="outline"
        data-empty={{if this.date "false" "true"}}
        class="w-[280px] justify-start text-left font-normal data-[empty=true]:text-muted-foreground"
        {{p.trigger}}
      >
        <Icon @icon={{CalendarIcon}} />
        {{#if this.date}}{{format this.date}}{{else}}<span>Pick a date</span>{{/if}}
      </Button>
      <p.Content class="w-auto p-0">
        <Calendar @mode="single" @value={{this.date}} @onValueChange={{this.setDate}} />
      </p.Content>
    </Popover>
  </template>
}
```

See the [Calendar](/components/calendar.md) page for everything the calendar takes, and the
[Popover](/components/popover.md) page for the popover.

Upstream writes the date with date-fns' `format(date, "PPP")`. Joinery has no date library:
its dates are `Date`s, written with `Intl` (`toLocaleDateString`, `Intl.DateTimeFormat`). The
examples below write `PPP` from `Intl` in a few lines, ordinal suffix and all
(`November 10th, 2026`).

## Composition

A date picker is built from `Popover` and `Calendar` (there is no `DatePicker` root
component):

```text
Popover
├── {{p.trigger}} on your Button (or p.Trigger)
└── p.Content
    └── Calendar
```

## Basic

A basic date picker component.

<Example @name="date-picker-basic" @title="Basic" />

## Range Picker

A date picker component for selecting a range of dates.

<Example @name="date-picker-range" @title="Range Picker" />

## Date of Birth

A date picker component for selecting a date of birth. This component includes a dropdown
caption layout for date and month selection.

<Example @name="date-picker-dob" @title="Date of Birth" />

It controls the popover (`@open` and `@onOpenChange`), so that a pick can close it; closing it
puts focus back on the button.

## Input

A date picker component with an input field for selecting a date.

<Example @name="date-picker-input" @title="Input" />

The input and the calendar share the date: what you type moves the calendar (`@month` and
`@onMonthChange`), and a pick writes the input. `ArrowDown` in the input opens the calendar.

## Time Picker

A date picker component with a time input field for selecting a time.

<Example @name="date-picker-time" @title="Time Picker" />

## Natural Language Picker

This component uses the `chrono-node` library to parse natural language dates.

<Example @name="date-picker-natural-language" @title="Natural Language Picker" />

`chrono-node` is the example's own dependency (`pnpm add chrono-node`), as it is upstream's;
Joinery's components need no date library.

## RTL

Joinery's components take their direction from the nearest `dir` (see
[Direction](/primitives/direction.md)): right to left, the popover opens at the trigger's
right edge (`@align="start"`), the calendar's week runs from the right, and the left arrow
moves to the next day.

<Example @name="date-picker-rtl" @title="RTL" @dir="rtl" />

Upstream passes react-day-picker's `arSA` locale to the calendar and date-fns' to `format`;
Joinery's calendar takes the locale as a tag, `@locale="ar-SA"`, and the example writes the
date with `Intl` in the same locale, so it reads `10 نوفمبر 2026` where date-fns' reads
`نوفمبر 10, 2026`.

## API Reference

A date picker has no API of its own: see [Popover](/components/popover.md#api-reference) and
[Calendar](/components/calendar.md#api-reference). The arguments the examples use:

| Where       | Argument                                          | What it does here                                     |
| ----------- | ------------------------------------------------- | ----------------------------------------------------- |
| `Popover`   | `@open`, `@onOpenChange`                          | Control it, so a pick can close it                    |
| `p.Content` | `@align`, `@alignOffset`, `@sideOffset`           | Place it at the trigger's start or end                |
| `Calendar`  | `@mode`                                           | `single` (a `Date`) or `range` (`{ from, to }`)       |
| `Calendar`  | `@value`, `@onValueChange`                        | The date picked, and each new one                     |
| `Calendar`  | `@defaultMonth`, or `@month` and `@onMonthChange` | The month it opens on: the date's, or one you control |
| `Calendar`  | `@captionLayout="dropdown"`                       | Month and year dropdowns, to go back years            |
| `Calendar`  | `@numberOfMonths`                                 | Two months for a range                                |
| `Calendar`  | `@locale`, `@dir`                                 | Its language, names and direction                     |

`data-empty` on the trigger is the examples' own, as upstream's: `"true"` while no date is
picked, which `data-[empty=true]:text-muted-foreground` greys.

## Keyboard interactions

The [APG date picker dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/)'s
keys, from the Popover and the Calendar:

| Key                            | What it does                                                        |
| ------------------------------ | ------------------------------------------------------------------- |
| `Space`, `Enter`               | On the trigger, opens or closes it; on a day, picks it              |
| `Tab`, `Shift` + `Tab`         | Moves between the month buttons and the day in the tab order, round |
| `ArrowLeft`, `ArrowRight`      | The previous or next day (flipped right to left)                    |
| `ArrowUp`, `ArrowDown`         | The same day of the previous or next week                           |
| `PageUp`, `PageDown`           | The same day of the previous or next month                          |
| `Shift` + `PageUp`, `PageDown` | The same day of the previous or next year                           |
| `Home`, `End`                  | The first or last day of the week                                   |
| `Esc`                          | Closes it, and moves focus back to the trigger                      |
| `ArrowDown` in the input       | Opens it (the input examples' own, as upstream's)                   |

Opening it moves focus to its first button, the previous month's, as Radix's does; `Tab` goes
on to the next month's, then to the selected day (or today). Closing it, with `Esc` or a pick
that closes it, puts focus back on the trigger.

## Accessibility

- The content is a `dialog` named by its trigger, so it reads as the date (or `Pick a date`)
  it holds. Give the content `aria-label` to name it yourself.
- The calendar's days are buttons named by their whole date, in a `grid` named by its month;
  see [Calendar](/components/calendar.md#accessibility).
- In the Basic, Range, Date of Birth and Time examples, the field's label names the button
  (`for` and `id`), as upstream's: a screen reader reads `Date` for it, and the date it shows
  as its text. The input examples' calendar button is named by its `aria-label`.
- In the input examples, the popover is in the input group's addon, as upstream's: a press in
  the addon that isn't on a button focuses the input, and that includes a press inside the
  open calendar but not on one of its buttons, as upstream's does (React's events bubble out
  of its portal).

## Testing

`DatePickerHarness` from `@ember-joinery/test-support` drives a date picker. It is a
[`PopoverHarness`](/components/popover.md#testing) (give the `Popover` a `@name`), with the
calendar in its content and a way to pick a day: it opens the popover, goes to the day's month
(by the dropdowns where the calendar has them, else the previous and next buttons) and presses
the day. A day is a `Date` or `yyyy-MM-dd`:

```ts
import { DatePickerHarness } from '@ember-joinery/test-support'

const picker = new DatePickerHarness('due') // <Popover @name="due">
assert.strictEqual(picker.text, 'Pick a date')
await picker.pick('2026-03-04')
assert.strictEqual(picker.text, 'March 4th, 2026')
assert.deepEqual(picker.calendar.selectedDays, ['2026-03-04'])
await new DatePickerHarness('stay').pickRange('2026-03-04', '2026-03-09')
```

| Member                                   | What it is                                                                         |
| ---------------------------------------- | ---------------------------------------------------------------------------------- |
| `calendar`                               | The `CalendarHarness` of the calendar in the content (there only while it is open) |
| `text`                                   | What the trigger shows: the date as written, or the placeholder                    |
| `isEmpty`                                | Whether the trigger has `data-empty="true"`                                        |
| `shows(day)`                             | Whether the open calendar shows the day in its own month                           |
| `showMonth(day)`                         | Opens it and goes to the day's month; throws when the calendar can't go there      |
| `pick(day)`                              | Opens it, goes to the day's month and presses the day                              |
| `pickRange(from, to)`                    | Picks both ends of a range                                                         |
| `open()`, `close()`, `isOpen`, `trigger` | The popover's, and the rest of `PopoverHarness`                                    |

For an input beside the picker, read and fill the input with `InputGroupHarness`.

## Upstream

shadcn/ui's [Date Picker](https://ui.shadcn.com/docs/components/radix/date-picker), from
`apps/v4/content/docs/components/radix/date-picker.mdx` and its examples at
shadcn-ui/ui@8ab2771, in the Nova style.
