import { Field, FieldDescription, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field @disabled={{true}}>
    <FieldLabel for="input-demo-disabled">Email</FieldLabel>
    <Input id="input-demo-disabled" type="email" placeholder="Email" disabled />
    <FieldDescription>This field is currently disabled.</FieldDescription>
  </Field>
</template>
