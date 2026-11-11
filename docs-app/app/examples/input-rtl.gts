import { Field, FieldDescription, FieldLabel, Input } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the field and the input; Joinery's take it from the nearest dir.
  }}
  <Field>
    <FieldLabel for="input-rtl-api-key">مفتاح API</FieldLabel>
    <Input id="input-rtl-api-key" type="password" placeholder="sk-..." />
    <FieldDescription>مفتاح API الخاص بك مشفر ومخزن بأمان.</FieldDescription>
  </Field>
</template>
