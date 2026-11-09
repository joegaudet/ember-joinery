import { ArrowRight, Plus } from 'lucide'
import { Button, Icon, Spinner } from '@ember-joinery/ember'

<template>
  {{! Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor). }}
  <div class="flex flex-wrap items-center gap-2 md:flex-row">
    <Button @variant="outline">زر</Button>
    <Button @variant="destructive">حذف</Button>
    <Button @variant="outline">
      إرسال
      <Icon @icon={{ArrowRight}} class="rtl:rotate-180" data-icon="inline-end" />
    </Button>
    <Button @variant="outline" @size="icon" aria-label="إضافة">
      <Icon @icon={{Plus}} />
    </Button>
    <Button @variant="secondary" disabled>
      <Spinner @label="جاري التحميل" data-icon="inline-start" />
      جاري التحميل
    </Button>
  </div>
</template>
