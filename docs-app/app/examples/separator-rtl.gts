import { Separator } from '@ember-joinery/ember'

<template>
  {{! Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's Arabic. }}
  <div class="flex max-w-sm flex-col gap-4 text-sm">
    <div class="flex flex-col gap-1.5">
      <div class="leading-none font-medium">shadcn/ui</div>
      <div class="text-muted-foreground">الأساس لنظام التصميم الخاص بك</div>
    </div>
    <Separator />
    <div>مجموعة من المكونات المصممة بشكل جميل يمكنك تخصيصها وتوسيعها والبناء عليها.</div>
  </div>
</template>
