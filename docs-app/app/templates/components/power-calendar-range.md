# Power Calendar Range

A calendar to choose a range of days, in shadcn's Calendar look, on ember-power-calendar.

<div class="callout">

**An opt-in add-on.** Power Calendar Range is in `@ember-joinery/power-calendar`, built on
[ember-power-calendar](https://ember-power-calendar.com) 2, which nothing in Joinery's core
packages imports. Its installation is [Power Calendar's](/components/power-calendar.md).

</div>

`PowerCalendarRange` is ember-power-calendar's range calendar drawn as shadcn's Calendar with
`mode="range"`: the first press chooses one end and the second the other, in either order. The
ends are filled, and the days between them shaded, as one band.

<Example @name="power-calendar-range-demo" @title="Power Calendar Range" />

## Usage

```gts
import { PowerCalendarRange, type DateRange } from '@ember-joinery/power-calendar'

<PowerCalendarRange @value={{this.stay}} @onValueChange={{this.setStay}} />
```

The value is `{ from, to }`, `Date`s at local midnight, as shadcn's `DateRange` (react-day-picker's)
is. `@onValueChange` hears each press: `{ from }` after the first (the end still `undefined`),
`{ from, to }` after the second. A third press starts a new range, unless
`@proximitySelection` is on: then it moves the nearer end. It is controlled or not, as
[Power Calendar](/components/power-calendar.md) is, and takes all of its arguments.

## The shortest and longest range

`@minRange` and `@maxRange` are the fewest and most days between the two ends. Once a start is
chosen, the days closer to it than `@minRange` or further than `@maxRange` can't be the end
(they are disabled until the range is whole). `@minRange` is 0 by default, so a range can be
one day; ember-power-calendar's own default is 1.

<Example @name="power-calendar-range-limits" @title="One to seven nights, from today on" />

## API Reference

### PowerCalendarRange

Every [Power Calendar](/components/power-calendar.md#api-reference) argument but `@required`,
and:

| Argument              | Type                 | Default             | What it does                                                        |
| --------------------- | -------------------- | ------------------- | ------------------------------------------------------------------- |
| `@value`              | `DateRange \| null`  |                     | The range, `{ from, to }`. Pass it (even `undefined`) to control it |
| `@defaultValue`       | `DateRange \| null`  |                     | The range first chosen, uncontrolled                                |
| `@onValueChange`      | `(range: DateRange)` |                     | Called after each press: `{ from }`, then `{ from, to }`            |
| `@minRange`           | `number`             | `0`                 | The fewest days between the ends                                    |
| `@maxRange`           | `number`             |                     | The most days between the ends                                      |
| `@proximitySelection` | `boolean`            | `false`             | With both ends chosen, a press moves the nearer one                 |
| `@label`              | `string`             | `Choose date range` | The calendar's accessible name                                      |

Its root is `data-test-jn="power-calendar-range"`, its grid `aria-multiselectable`, and each day
of the range is `aria-selected`. A day's cell and button carry `data-range-start`,
`data-range-middle` and `data-range-end`, as react-day-picker's modifiers are, for the band.

## Keyboard interactions

As [Power Calendar's](/components/power-calendar.md#keyboard-interactions): the arrow keys, Home,
End, Page Up and Page Down move through the days, past the ones that can't be the end, and
Enter or Space presses one.

## Testing

`PowerCalendarHarness` drives it, with `selectRange(from, to)` for both ends; `kind` is `range`,
and `selected` lists every day of the range in the month shown.

```ts
const stay = new PowerCalendarHarness('stay')
await stay.selectRange('2026-11-12', '2026-11-16')
assert.strictEqual(stay.selected.length, 5)
assert.true(stay.isDayDisabled('2026-11-11'))
```

## Built on

ember-power-calendar's `PowerCalendarRange`: its range building (in order, by proximity), its
`minRange` and `maxRange`, and its range days, drawn here as shadcn's.
