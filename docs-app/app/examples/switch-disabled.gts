import { Field, FieldLabel, Switch } from '@ember-joinery/ember'

<template>
  <Field @orientation="horizontal" @disabled={{true}} class="w-fit">
    <Switch id="switch-disabled-unchecked" @disabled={{true}} />
    <FieldLabel for="switch-disabled-unchecked">Disabled</FieldLabel>
  </Field>
</template>
