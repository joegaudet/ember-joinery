import { Field, FieldDescription, FieldLabel } from '@ember-joinery/ember'
import { PhoneInput } from '@ember-joinery/maskito'

<template>
  <Field class="w-full max-w-xs">
    <FieldLabel for="phone-input-rtl-phone">رقم الجوال</FieldLabel>
    <PhoneInput
      id="phone-input-rtl-phone"
      @name="phone"
      @defaultCountry="SA"
      @locale="ar"
      @countryLabel="الدولة"
      placeholder="+966 50 123-4567"
      aria-describedby="phone-input-rtl-hint"
    />
    <FieldDescription id="phone-input-rtl-hint">سنرسل إليه رمز التحقق.</FieldDescription>
  </Field>
</template>
