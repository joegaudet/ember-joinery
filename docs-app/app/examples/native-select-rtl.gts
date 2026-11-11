import { NativeSelect } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream puts dir on the select from its language picker; here the preview's dir
    does it, and the chevron moves to the left with it. Upstream's select has no name; Joinery's
    gets aria-label ("الحالة", status), so the audit passes.
  }}
  <NativeSelect aria-label="الحالة" as |s|>
    <s.Option @value="">اختر الحالة</s.Option>
    <s.Option @value="todo">مهام</s.Option>
    <s.Option @value="in-progress">
      قيد التنفيذ
    </s.Option>
    <s.Option @value="done">منجز</s.Option>
    <s.Option @value="cancelled">ملغي</s.Option>
  </NativeSelect>
</template>
