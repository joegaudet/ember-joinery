import { Field, FieldDescription, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="input-demo-api-key">API Key</FieldLabel>
    <Input id="input-demo-api-key" type="password" placeholder="sk-..." />
    <FieldDescription>
      Your API key is encrypted and stored securely.
    </FieldDescription>
  </Field>
</template>
