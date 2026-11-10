import { Info } from 'lucide'
import { Field, FieldLabel, Icon, InputGroup } from '@ember-joinery/ember'

<template>
  <Field>
    <FieldLabel for="input-group-url">Website URL</FieldLabel>
    <InputGroup as |g|>
      <g.Input id="input-group-url" placeholder="example.com" />
      <g.Addon>
        <g.Text>https://</g.Text>
      </g.Addon>
      <g.Addon @align="inline-end">
        <Icon @icon={{Info}} />
      </g.Addon>
    </InputGroup>
  </Field>
</template>
