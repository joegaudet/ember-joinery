import { ArrowRight, Plus } from 'lucide'
import { Button, Icon, Spinner } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream leaves two names in English, the icon button's aria-label ("Add") and the
    Spinner's built-in "Loading"; Joinery's are in Arabic too ("إضافة", "جاري التحميل"), as a
    right-to-left page would name them. They're read aloud, not drawn, so the screenshot is the
    same.
  }}
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
