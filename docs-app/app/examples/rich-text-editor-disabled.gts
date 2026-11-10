import { Field, FieldDescription, FieldGroup, FieldLabel } from '@ember-joinery/ember'
import { RichTextEditor } from '@ember-joinery/tiptap'

const NOTICE =
  '<p>The office is closed on <strong>Friday</strong>. Deliveries resume on Monday.</p>'

<template>
  <FieldGroup class="w-full max-w-md">
    <Field>
      <FieldLabel for="notice">Notice</FieldLabel>
      <RichTextEditor @name="notice" @id="notice" @readonly={{true}} @defaultValue={{NOTICE}} />
      <FieldDescription>Read-only: it can be read and copied, not changed.</FieldDescription>
    </Field>
    <Field @disabled={{true}}>
      <FieldLabel for="draft">Draft</FieldLabel>
      <RichTextEditor
        @name="draft"
        @id="draft"
        @disabled={{true}}
        @defaultValue="<p>Waiting for review.</p>"
      />
    </Field>
  </FieldGroup>
</template>
