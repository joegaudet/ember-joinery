import { Field, FieldDescription, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field @invalid={{true}}>
    <FieldLabel for="input-invalid">Invalid Input</FieldLabel>
    <Input id="input-invalid" placeholder="Error" aria-invalid="true" />
    <FieldDescription>
      This field contains validation errors.
    </FieldDescription>
  </Field>
</template>
