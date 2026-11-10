import { Button, ButtonGroup, Field, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="input-button-group">Search</FieldLabel>
    <ButtonGroup>
      <Input id="input-button-group" placeholder="Type to search..." />
      <Button @variant="outline">Search</Button>
    </ButtonGroup>
  </Field>
</template>
