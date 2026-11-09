import { Field, FieldDescription, FieldLabel, Textarea } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the field and its parts; Joinery's take it from the nearest dir.
  }}
  <Field class="w-full max-w-xs">
    <FieldLabel for="feedback">
      التعليقات
    </FieldLabel>
    <Textarea id="feedback" placeholder="تعليقاتك تساعدنا على التحسين..." rows="4" />
    <FieldDescription>شاركنا أفكارك حول خدمتنا.</FieldDescription>
  </Field>
</template>
