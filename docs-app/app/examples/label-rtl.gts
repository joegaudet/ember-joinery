import { Checkbox, Label } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream also
    puts dir on the checkbox and the label; Joinery's take it from the nearest dir.
  }}
  <div class="flex gap-2">
    <Checkbox id="terms-rtl" />
    <Label for="terms-rtl">قبول الشروط والأحكام</Label>
  </div>
</template>
