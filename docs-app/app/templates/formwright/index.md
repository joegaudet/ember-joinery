# Formwright

shadcn's forms are built on a form library: React Hook Form, TanStack Form or Formisch, with the
[Field](/components/field.md) component setting each field out. Joinery's are built on
[Formwright](https://joegaudet.com/ember-formwright/), through `@ember-joinery/formwright`:
Joinery's inputs are Formwright controls, a field layout sets each field out in shadcn's
Field anatomy, and the harnesses are built on Formwright's own.

<Example @name="formwright-demo" @title="Bug Report" />

## Installation

```bash
pnpm add @ember-joinery/formwright @ember-joinery/ember @ember-formwright/ember
pnpm add -D @ember-formwright/test-support @ember-joinery/test-support
```

`@ember-formwright/ember` and `@ember-joinery/ember` are peers, so the app has one copy of each:
Formwright keeps its controls and layouts in one registry, and Joinery's CSS styles every field.
The package ships no CSS of its own; Joinery's `joinery.css` (or any of its styles) styles its
fields, as it does every component.

Set it up once, at boot, in `app.ts`:

```ts
import { setupJoineryForms } from '@ember-joinery/formwright'

setupJoineryForms()
```

That registers every [control](/formwright/controls.md) and [layout](/formwright/layout.md),
and makes Joinery's layout the one every field uses. Formwright's own names (`input`, `select`,
`radio`, `checkbox`…) then render Joinery's components, so a Formwright form an app already has
takes on Joinery's look with no change to its templates. Its tests may need one: Formwright's
harnesses for a native select, radio, checkbox or range can't drive Joinery's, and
[Testing](/formwright/testing.md#moving-from-formwrights-harnesses) lists the harness that
replaces each.

## Usage

```gts
import { Form } from '@ember-formwright/ember'
import { FieldGroup, asButton } from '@ember-joinery/ember'
import * as z from 'zod'

const schema = z.object({
  name: z.string().min(1, 'Enter your name.'),
  language: z.string().min(1, 'Choose a language.'),
})

<template>
  <Form @model={{@profile}} @validator={{schema}} @onSubmit={{@save}} as |f|>
    <FieldGroup>
      <f.Field @for="name" @label="Name" @hint="Your public display name." />
      <f.Field @for="language" @control="select" @label="Language" @options={{@languages}} />
      <f.Field @for="newsletter" @control="switch" @label="Send me the newsletter" />
    </FieldGroup>
    <f.Submit {{asButton}}>Save</f.Submit>
  </Form>
</template>
```

Formwright does the form's work: it reads and writes the model, validates it with any
[Standard Schema](https://standardschema.dev) (zod, valibot…) or a function, shows each
field's errors after a submit and as they are fixed, keeps the field's ids, labels and
`aria-*` in step, and resets. Joinery draws it: each field is a `Field` with its `FieldLabel`,
`FieldDescription` and `FieldError`, and each control the Joinery component of that name.
Formwright's `f.Submit`, `f.Reset` and `f.Button` take Joinery's Button with `{{asButton}}`.

The [Forms](/formwright/forms.md) page builds shadcn's form examples this way, one for each of
upstream's.

<SectionList @section="formwright" />
