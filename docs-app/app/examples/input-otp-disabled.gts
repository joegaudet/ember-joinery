import { InputOTP } from '@ember-joinery/ember'

<template>
  <InputOTP id="disabled" @maxLength={{6}} disabled @value="123456" as |otp|>
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
