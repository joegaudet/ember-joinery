import { Search } from 'lucide'
import { Field, FieldDescription, FieldLabel, Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <Field class="max-w-sm">
    <FieldLabel for="inline-start-input">Input</FieldLabel>
    <InputGroup as |g|>
      <g.Input id="inline-start-input" placeholder="Search..." />
      <g.Addon @align="inline-start">
        <Icon @icon={{Search}} class="text-muted-foreground" />
      </g.Addon>
    </InputGroup>
    <FieldDescription>Icon positioned at the start.</FieldDescription>
  </Field>
</template>
