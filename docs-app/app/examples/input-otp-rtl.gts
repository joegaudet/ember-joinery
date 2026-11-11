import { Field, FieldLabel, InputOTP } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts dir
    on the input; Joinery's takes it from the nearest dir.
  }}
  <Field class="mx-auto max-w-xs">
    <FieldLabel for="input-otp-rtl">رمز التحقق</FieldLabel>
    <InputOTP @maxLength={{6}} @defaultValue="123456" id="input-otp-rtl" as |otp|>
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
