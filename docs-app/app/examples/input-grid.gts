import { Field, FieldGroup, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <FieldGroup class="grid max-w-sm grid-cols-2">
    <Field>
      <FieldLabel for="first-name">First Name</FieldLabel>
      <Input id="first-name" placeholder="Jordan" />
    </Field>
    <Field>
      <FieldLabel for="last-name">Last Name</FieldLabel>
      <Input id="last-name" placeholder="Lee" />
    </Field>
  </FieldGroup>
</template>
