import { Field, FieldDescription, FieldLabel, Textarea } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="textarea-message">Message</FieldLabel>
    <FieldDescription>Enter your message below.</FieldDescription>
    <Textarea id="textarea-message" placeholder="Type your message here." />
  </Field>
</template>
