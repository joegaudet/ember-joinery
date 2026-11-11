import { InputOTP, REGEXP_ONLY_DIGITS_AND_CHARS } from '@ember-joinery/ember'

<template>
  <InputOTP @maxLength={{6}} @pattern={{REGEXP_ONLY_DIGITS_AND_CHARS}} as |otp|>
    <otp.Group>
      <otp.Slot @index={{0}} />
      <otp.Slot @index={{1}} />
      <otp.Slot @index={{2}} />
    </otp.Group>
    <otp.Separator />
    <otp.Group>
      <otp.Slot @index={{3}} />
      <otp.Slot @index={{4}} />
      <otp.Slot @index={{5}} />
    </otp.Group>
  </InputOTP>
</template>
