import { Checkbox, Field, FieldGroup, FieldLabel } from '@ember-joinery/ember'

<template>
  <FieldGroup class="mx-auto w-56">
    <Field @orientation="horizontal" @invalid={{true}}>
      <Checkbox id="terms-checkbox-invalid" name="terms-checkbox-invalid" aria-invalid="true" />
      <FieldLabel for="terms-checkbox-invalid">
        Accept terms and conditions
      </FieldLabel>
    </Field>
  </FieldGroup>
</template>
