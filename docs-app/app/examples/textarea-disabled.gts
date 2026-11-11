import { Field, FieldLabel, Textarea } from '@ember-joinery/ember'

<template>
  <Field @disabled={{true}}>
    <FieldLabel for="textarea-disabled">Message</FieldLabel>
    <Textarea id="textarea-disabled" placeholder="Type your message here." disabled />
  </Field>
</template>
