import { Field, FieldContent, FieldDescription, FieldLabel, Switch } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the field and its parts; Joinery's take it from the nearest dir.
  }}
  <Field @orientation="horizontal" class="max-w-sm">
    <FieldContent>
      <FieldLabel for="switch-focus-mode-rtl">
        المشاركة عبر الأجهزة
      </FieldLabel>
      <FieldDescription>
        يتم مشاركة التركيز عبر الأجهزة، ويتم إيقاف تشغيله عند مغادرة التطبيق.
      </FieldDescription>
    </FieldContent>
    <Switch id="switch-focus-mode-rtl" />
  </Field>
</template>
