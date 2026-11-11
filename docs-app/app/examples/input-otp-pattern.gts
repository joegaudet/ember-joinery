import { Field, FieldLabel, InputOTP, REGEXP_ONLY_DIGITS } from '@ember-joinery/ember'

<template>
  <Field class="w-fit">
    <FieldLabel for="digits-only">Digits Only</FieldLabel>
    <InputOTP id="digits-only" @maxLength={{6}} @pattern={{REGEXP_ONLY_DIGITS}} as |otp|>
      <otp.Group>
        <otp.Slot @index={{0}} />
        <otp.Slot @index={{1}} />
        <otp.Slot @index={{2}} />
        <otp.Slot @index={{3}} />
        <otp.Slot @index={{4}} />
        <otp.Slot @index={{5}} />
      </otp.Group>
    </InputOTP>
  </Field>
</template>
