import { Field, FieldLabel } from '@ember-joinery/ember'
import { PhoneInput, type CountryCode } from '@ember-joinery/maskito'

// The countries the picker offers, in this order.
const NORDICS: CountryCode[] = ['DK', 'FI', 'IS', 'NO', 'SE']

<template>
  <Field class="w-full max-w-xs">
    <FieldLabel for="phone-input-countries-phone">Phone</FieldLabel>
    <PhoneInput
      id="phone-input-countries-phone"
      @name="phone"
      @countries={{NORDICS}}
      @defaultCountry="SE"
      placeholder="+46 70 123-45-67"
    />
  </Field>
</template>
