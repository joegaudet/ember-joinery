import { Copy, FileCode } from 'lucide'
import {
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  Icon,
  InputGroup,
} from '@ember-joinery/ember'

<template>
  <FieldGroup class="max-w-sm">
    <Field>
      <FieldLabel for="block-start-input">Input</FieldLabel>
      <InputGroup class="h-auto" as |g|>
        <g.Input id="block-start-input" placeholder="Enter your name" />
        <g.Addon @align="block-start">
          <g.Text>Full Name</g.Text>
        </g.Addon>
      </InputGroup>
      <FieldDescription>Header positioned above the input.</FieldDescription>
    </Field>
    <Field>
      <FieldLabel for="block-start-textarea">Textarea</FieldLabel>
      <InputGroup as |g|>
        <g.Textarea
          id="block-start-textarea"
          placeholder="console.log('Hello, world!');"
          class="font-mono text-sm"
        />
        <g.Addon @align="block-start">
          <Icon @icon={{FileCode}} class="text-muted-foreground" />
          <g.Text class="font-mono">script.js</g.Text>
          <g.Button @size="icon-xs" class="ml-auto">
            <Icon @icon={{Copy}} />
            <span class="sr-only">Copy</span>
          </g.Button>
        </g.Addon>
      </InputGroup>
      <FieldDescription>
        Header positioned above the textarea.
      </FieldDescription>
    </Field>
  </FieldGroup>
</template>
