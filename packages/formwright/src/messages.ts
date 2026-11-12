import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/formwright` shows or announces itself, in English, for a
 * translation catalog. Its controls also show the components' own (a slider thumb's
 * `Minimum`). An argument (`@placeholder`, `@emptyText`) still beats each one.
 */
export const messages = {
  datePickerPlaceholder: { id: 'joinery.formwright.datePickerPlaceholder', message: 'Pick a date' },
  comboboxEmpty: { id: 'joinery.formwright.comboboxEmpty', message: 'No items found.' },
  sliderThumb: {
    id: 'joinery.formwright.sliderThumb',
    message: '{label}, {thumb}',
    description:
      'A range slider\'s thumb: {label} is the field\'s label, {thumb} "Minimum" or "Maximum".',
  },
} satisfies Record<string, Message>
