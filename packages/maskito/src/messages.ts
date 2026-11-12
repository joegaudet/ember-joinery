import type { Message } from '@ember-joinery/primitives/i18n'

/**
 * Every string `@ember-joinery/maskito` shows or announces itself, in English, for a
 * translation catalog. An argument (`@countryLabel`) still beats each one.
 */
export const messages = {
  country: { id: 'joinery.phone-input.country', message: 'Country' },
  namedCountry: {
    id: 'joinery.phone-input.namedCountry',
    message: '{name} country',
    description: "The country picker's name, after its input's: {name} is the input's name.",
  },
  countryWord: {
    id: 'joinery.phone-input.countryWord',
    message: 'country',
    description: "Read after the input's label to name its country picker: “Phone country”.",
  },
} satisfies Record<string, Message>
