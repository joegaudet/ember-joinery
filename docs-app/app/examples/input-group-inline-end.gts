import { EyeOff } from 'lucide'
import { Field, FieldDescription, FieldLabel, Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <Field class="max-w-sm">
    <FieldLabel for="inline-end-input">Input</FieldLabel>
    <InputGroup as |g|>
      <g.Input id="inline-end-input" type="password" placeholder="Enter password" />
      <g.Addon @align="inline-end">
        <Icon @icon={{EyeOff}} />
      </g.Addon>
    </InputGroup>
    <FieldDescription>Icon positioned at the end.</FieldDescription>
  </Field>
</template>
