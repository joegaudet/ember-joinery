import { Field, FieldContent, FieldDescription, FieldLabel, Switch } from '@ember-joinery/ember'

<template>
  <Field @orientation="horizontal" class="max-w-sm" @invalid={{true}}>
    <FieldContent>
      <FieldLabel for="switch-terms">
        Accept terms and conditions
      </FieldLabel>
      <FieldDescription>
        You must accept the terms and conditions to continue.
      </FieldDescription>
    </FieldContent>
    <Switch id="switch-terms" aria-invalid="true" />
  </Field>
</template>
