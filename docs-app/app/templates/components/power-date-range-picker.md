# Power Date Range Picker

A date range picker: a Power Calendar Range in a Popover, opened from a button or an input.

<div class="callout">

**An opt-in add-on.** Power Date Range Picker is in `@ember-joinery/power-calendar`, built on
[ember-power-calendar](https://ember-power-calendar.com) 2, which nothing in Joinery's core
packages imports. Its installation is [Power Calendar's](/components/power-calendar.md).

</div>

`DateRangePicker` is shadcn's Range Picker (upstream's date-picker-range) made one component: a
Joinery [Popover](/components/popover.md) holding a
[Power Calendar Range](/components/power-calendar-range.md), opened from an outlined Button with a
calendar icon, or from an input both dates can be typed into.

<Example @name="power-date-range-picker-demo" @title="Power Date Range Picker" />

## Usage

```gts
import { DateRangePicker, type DateRange } from '@ember-joinery/power-calendar'

<DateRangePicker @value={{this.stay}} @onValueChange={{this.setStay}} />
```

The first day pressed starts the range and the second ends it, in either order: only then does
the value change and the calendar close. Closing it in between (Escape, a press outside) keeps
the range there was, as Formwright's date-range control does. The button writes the range with
`Intl`'s range format (`Jan 20 – Feb 9, 2026`; `@format` takes its options,
`{ dateStyle: 'medium' }` by default).

The value is `{ from, to }`, controlled or not. It takes every
[Power Date Picker](/components/power-date-picker.md#api-reference) argument, and
[Power Calendar Range's](/components/power-calendar-range.md#api-reference) `@minRange` and
`@maxRange`. Its button's icon is a calendar at the inline start, and its calendar button's name,
with an input, `Select dates`.

## Input

With `@trigger="input"`, both dates are typed, a dash (or "to") between them: `Mar 4, 2026 – Mar
9, 2026`. Text that names two days, each with its year, becomes the range (in order); leaving the
input writes both back in full.

<Example @name="power-date-range-picker-input" @title="Input" />

## Testing

`DatePickerHarness` drives it, as it does a DatePicker: `selectRange(from, to)` opens the calendar
and presses both ends, and `isRange` is `true`.

```ts
const stay = new DatePickerHarness('stay')
await stay.selectRange('2026-03-04', '2026-03-09')
assert.strictEqual(stay.text, 'Mar 4 – 9, 2026')
```

See [Power Date Picker](/components/power-date-picker.md#testing) for its members, and its
keyboard interactions and accessibility, which are this picker's too.
