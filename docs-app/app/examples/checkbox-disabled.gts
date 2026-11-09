import { Checkbox, Field, FieldGroup, FieldLabel } from '@ember-joinery/ember'

<template>
  <FieldGroup class="mx-auto w-56">
    <Field @orientation="horizontal" @disabled={{true}}>
      <Checkbox id="toggle-checkbox-disabled" name="toggle-checkbox-disabled" @disabled={{true}} />
      <FieldLabel for="toggle-checkbox-disabled">
        Enable notifications
      </FieldLabel>
    </Field>
  </FieldGroup>
</template>
