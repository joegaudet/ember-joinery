import { Field, FieldDescription, FieldLabel, Textarea } from '@ember-joinery/ember'

<template>
  <Field @invalid={{true}}>
    <FieldLabel for="textarea-invalid">Message</FieldLabel>
    <Textarea id="textarea-invalid" placeholder="Type your message here." aria-invalid="true" />
    <FieldDescription>Please enter a valid message.</FieldDescription>
  </Field>
</template>
