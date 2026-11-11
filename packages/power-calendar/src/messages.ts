import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/power-calendar` shows or announces itself, in English, for a
 * translation catalog. An argument (`@label`, `@placeholder`, `@triggerLabel`) still beats each.
 */
export const messages = {
  previousMonth: { id: 'joinery.power-calendar.previousMonth', message: 'Previous month' },
  nextMonth: { id: 'joinery.power-calendar.nextMonth', message: 'Next month' },
  chooseDate: { id: 'joinery.power-calendar.chooseDate', message: 'Choose date' },
  chooseDates: { id: 'joinery.power-calendar.chooseDates', message: 'Choose dates' },
  chooseRange: { id: 'joinery.power-calendar.chooseRange', message: 'Choose date range' },
  placeholder: { id: 'joinery.date-picker.placeholder', message: 'Pick a date' },
  selectDate: { id: 'joinery.date-picker.selectDate', message: 'Select date' },
  selectDates: { id: 'joinery.date-range-picker.selectDates', message: 'Select dates' },
  range: {
    id: 'joinery.date-range-picker.range',
    message: '{from} – {to}',
    description: 'A range of dates in the input: {from} and {to} are dates, en dash between.',
  },
} satisfies Record<string, Message>
