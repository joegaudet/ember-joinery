import { Field, FieldLabel, Progress } from '@ember-joinery/ember'

<template>
  {{!
    The bar names itself by its label with aria-labelledby: upstream's FieldLabel htmlFor
    doesn't name a progressbar (it isn't a labelable element), so the audit would fail.
  }}
  <Field class="w-full max-w-sm">
    <FieldLabel for="progress-upload" id="progress-upload-label">
      <span>Upload progress</span>
      <span class="ml-auto">66%</span>
    </FieldLabel>
    <Progress @value={{66}} id="progress-upload" aria-labelledby="progress-upload-label" />
  </Field>
</template>
