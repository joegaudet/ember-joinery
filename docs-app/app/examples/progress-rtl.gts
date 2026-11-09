import { Field, FieldLabel, Progress } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic, with its Arabic numerals: its preview opens in Arabic, and the frame has no
    language picker. As in progress-label, the bar names itself by its label with
    aria-labelledby, so the audit passes. The ids differ from progress-label's, which shares
    the page.
  }}
  <Field class="w-full max-w-sm">
    <FieldLabel for="progress-upload-rtl" id="progress-upload-rtl-label">
      <span>تقدم الرفع</span>
      <span class="ms-auto">٦٦%</span>
    </FieldLabel>
    <Progress
      @value={{66}}
      id="progress-upload-rtl"
      class="rtl:rotate-180"
      aria-labelledby="progress-upload-rtl-label"
    />
  </Field>
</template>
