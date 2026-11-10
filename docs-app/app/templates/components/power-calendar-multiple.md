# Power Calendar Multiple

A calendar to choose several days, in shadcn's Calendar look, on ember-power-calendar.

<div class="callout">

**An opt-in add-on.** Power Calendar Multiple is in `@ember-joinery/power-calendar`, built on
[ember-power-calendar](https://ember-power-calendar.com) 2, which nothing in Joinery's core
packages imports. Its installation is [Power Calendar's](/components/power-calendar.md).

</div>

`PowerCalendarMultiple` is ember-power-calendar's multiple calendar drawn as shadcn's Calendar
with `mode="multiple"`: each press adds a day, or removes one already chosen, and the chosen days
are filled.

<Example @name="power-calendar-multiple-demo" @title="Power Calendar Multiple" />

## Usage

```gts
import { PowerCalendarMultiple } from '@ember-joinery/power-calendar'

<PowerCalendarMultiple @value={{this.days}} @onValueChange={{this.setDays}} @maxLength={{3}} />
```

The value is an array of `Date`s at local midnight, in the order they were chosen. With
`@maxLength` days chosen, only those can be pressed (the rest are disabled) until one is removed.
It is controlled or not, as [Power Calendar](/components/power-calendar.md) is, and takes all of
its arguments.

## API Reference

### PowerCalendarMultiple

Every [Power Calendar](/components/power-calendar.md#api-reference) argument but `@required`,
and:

| Argument         | Type              | Default        | What it does                                              |
| ---------------- | ----------------- | -------------- | --------------------------------------------------------- |
| `@value`         | `Date[] \| null`  |                | The days chosen. Pass it (even `undefined`) to control it |
| `@defaultValue`  | `Date[] \| null`  |                | The days first chosen, uncontrolled                       |
| `@onValueChange` | `(dates: Date[])` |                | Called whenever a press adds or removes a day             |
| `@maxLength`     | `number`          |                | The most days that can be chosen                          |
| `@label`         | `string`          | `Choose dates` | The calendar's accessible name                            |

Its root is `data-test-jn="power-calendar-multiple"`, its grid `aria-multiselectable`, and each
chosen day `aria-selected` and `data-selected-single="true"`.

## Keyboard interactions

As [Power Calendar's](/components/power-calendar.md#keyboard-interactions); Enter or Space adds
or removes the focused day.

## Testing

`PowerCalendarHarness` drives it, with `selectDays(...dates)` to press several days in turn;
`kind` is `multiple`.

```ts
const days = new PowerCalendarHarness('days')
await days.selectDays('2026-03-03', '2026-03-10')
assert.deepEqual(days.selected, ['2026-03-03', '2026-03-10'])
```

## Built on

ember-power-calendar's `PowerCalendarMultiple`: its collection of days and its `maxLength`.
