import { Field, FieldDescription, FieldGroup, FieldLabel, InputGroup } from '@ember-joinery/ember'

<template>
  <FieldGroup class="max-w-sm">
    <Field>
      <FieldLabel for="block-end-input">Input</FieldLabel>
      <InputGroup class="h-auto" as |g|>
        <g.Input id="block-end-input" placeholder="Enter amount" />
        <g.Addon @align="block-end">
          <g.Text>USD</g.Text>
        </g.Addon>
      </InputGroup>
      <FieldDescription>Footer positioned below the input.</FieldDescription>
    </Field>
    <Field>
      <FieldLabel for="block-end-textarea">Textarea</FieldLabel>
      <InputGroup as |g|>
        <g.Textarea id="block-end-textarea" placeholder="Write a comment..." />
        <g.Addon @align="block-end">
          <g.Text>0/280</g.Text>
          <g.Button @variant="default" @size="sm" class="ml-auto">
            Post
          </g.Button>
        </g.Addon>
      </InputGroup>
      <FieldDescription>
        Footer positioned below the textarea.
      </FieldDescription>
    </Field>
  </FieldGroup>
</template>
