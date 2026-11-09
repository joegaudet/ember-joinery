import { Field, FieldLabel, Switch } from '@ember-joinery/ember'

<template>
  <Field @orientation="horizontal" class="w-fit">
    <FieldLabel for="2fa">Multi-factor authentication</FieldLabel>
    <Switch id="2fa" />
  </Field>
</template>
