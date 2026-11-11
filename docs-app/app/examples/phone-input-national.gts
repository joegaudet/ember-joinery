import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { PhoneInput } from '@ember-joinery/maskito'

<template>
  <Field class="w-full max-w-xs">
    <FieldLabel for="phone-input-national-phone">Phone</FieldLabel>
    <PhoneInput
      id="phone-input-national-phone"
      @name="phone"
      @national={{true}}
      @defaultValue="+12125550123"
      aria-describedby="phone-input-national-hint"
    />
    <FieldDescription id="phone-input-national-hint">
      Shown as it is dialled at home; stored with its calling code.
    </FieldDescription>
  </Field>
</template>
