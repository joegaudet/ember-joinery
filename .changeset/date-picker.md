---
'@ember-joinery/test-support': minor
---

`DatePickerHarness` drives a date picker, shadcn's composition of a `Popover` and a `Calendar`
(there is no date picker component of its own): a `PopoverHarness` with the `calendar` in its
content, the trigger's `text` and `isEmpty`, and `pick(day)`, `pickRange(from, to)` and
`showMonth(day)`, which open the popover, go to the day's month (by the month and year
dropdowns where the calendar has them, else the previous and next buttons) and press the day.
The guide's Date Picker page ports every upstream example: the demo, basic, a range over two
months, a date of birth, an input, a time picker, natural language and right to left.
