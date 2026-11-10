import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import { MaskedInput, dateMask, numberMask } from '@ember-joinery/maskito'

const dateOfBirth = dateMask()
const amount = numberMask({ maximumFractionDigits: 2, thousandSeparator: ',', postfix: ' ر.س' })

<template>
  <FieldGroup class="w-full max-w-xs">
    <Field>
      <FieldLabel for="masked-input-rtl-date">تاريخ الميلاد</FieldLabel>
      <MaskedInput
        id="masked-input-rtl-date"
        @name="date"
        @mask={{dateOfBirth}}
        placeholder="يوم/شهر/سنة"
        inputmode="numeric"
      />
    </Field>
    <Field>
      <FieldLabel for="masked-input-rtl-amount">المبلغ</FieldLabel>
      <MaskedInput
        id="masked-input-rtl-amount"
        @name="amount"
        @mask={{amount}}
        placeholder="0.00 ر.س"
        inputmode="decimal"
        aria-describedby="masked-input-rtl-amount-hint"
      />
      <FieldDescription id="masked-input-rtl-amount-hint">بالريال السعودي.</FieldDescription>
    </Field>
  </FieldGroup>
</template>
