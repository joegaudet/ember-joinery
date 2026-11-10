import { CreditCard } from 'lucide'
import { Field, FieldLabel, Icon, InputGroup } from '@ember-joinery/ember'
import { dateMask, maskito } from '@ember-joinery/maskito'

const cardMask = {
  mask: [
    ...[/\d/, /\d/, /\d/, /\d/, ' '],
    ...[/\d/, /\d/, /\d/, /\d/, ' '],
    ...[/\d/, /\d/, /\d/, /\d/, ' '],
    ...[/\d/, /\d/, /\d/, /\d/],
  ],
}
const expiryMask = dateMask({ mode: 'mm/yy' })

<template>
  <div class="grid w-full max-w-sm grid-cols-3 gap-4">
    <Field class="col-span-2">
      <FieldLabel for="masked-input-input-group-card">Card number</FieldLabel>
      {{! The maskito modifier masks the group's own input, which g.input styles. }}
      <InputGroup as |g|>
        <input
          id="masked-input-input-group-card"
          placeholder="1234 5678 9012 3456"
          inputmode="numeric"
          autocomplete="cc-number"
          {{g.input name="card"}}
          {{maskito cardMask}}
        />
        <g.Addon>
          <Icon @icon={{CreditCard}} />
        </g.Addon>
      </InputGroup>
    </Field>
    <Field>
      <FieldLabel for="masked-input-input-group-expiry">Expires</FieldLabel>
      <InputGroup as |g|>
        <input
          id="masked-input-input-group-expiry"
          placeholder="MM/YY"
          inputmode="numeric"
          autocomplete="cc-exp"
          {{g.input name="expiry"}}
          {{maskito expiryMask}}
        />
      </InputGroup>
    </Field>
  </div>
</template>
