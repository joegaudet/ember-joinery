import { Field, FieldDescription, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="picture">Picture</FieldLabel>
    <Input id="picture" type="file" />
    <FieldDescription>Select a picture to upload.</FieldDescription>
  </Field>
</template>
