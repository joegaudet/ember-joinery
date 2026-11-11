import { BadgeCheck, Bookmark } from 'lucide'
import { Badge, Icon } from '@ember-joinery/ember'

<template>
  {{! Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's Arabic. }}
  <div class="flex w-full flex-wrap justify-center gap-2">
    <Badge>شارة</Badge>
    <Badge @variant="secondary">ثانوي</Badge>
    <Badge @variant="destructive">مدمر</Badge>
    <Badge @variant="outline">مخطط</Badge>
    <Badge @variant="secondary">
      <Icon @icon={{BadgeCheck}} data-icon="inline-start" />
      متحقق
    </Badge>
    <Badge @variant="outline">
      إشارة مرجعية
      <Icon @icon={{Bookmark}} data-icon="inline-end" />
    </Badge>
  </div>
</template>
