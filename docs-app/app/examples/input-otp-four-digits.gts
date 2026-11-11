import { InputOTP, REGEXP_ONLY_DIGITS } from '@ember-joinery/ember'

<template>
  <InputOTP @maxLength={{4}} @pattern={{REGEXP_ONLY_DIGITS}} as |otp|>
    <otp.Group>
      <otp.Slot @index={{0}} />
      <otp.Slot @index={{1}} />
      <otp.Slot @index={{2}} />
      <otp.Slot @index={{3}} />
    </otp.Group>
  </InputOTP>
</template>
