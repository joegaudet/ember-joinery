import { Badge, Field, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="input-badge">
      Webhook URL
      <Badge @variant="secondary" class="ml-auto">
        Beta
      </Badge>
    </FieldLabel>
    <Input id="input-badge" type="url" placeholder="https://api.example.com/webhook" />
  </Field>
</template>
