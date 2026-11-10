import { FileUpload } from '@ember-joinery/file-upload'

const report = [
  new File([new Uint8Array(184_320)], 'التقرير-السنوي.pdf', { type: 'application/pdf' }),
]
const removeLabel = (name: string) => `إزالة ${name}`
const retryLabel = (name: string) => `إعادة رفع ${name}`
const progressLabel = (name: string) => `جارٍ رفع ${name}`
const rejectedLabel = (names: string[]) => `نوع غير مقبول: ${names.join('، ')}`

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in Arabic: every
    string is an argument, and @locale writes the sizes in Arabic too. The media moves to the
    right and the remove buttons to the left.
  }}
  <FileUpload
    @name="documents"
    @multiple={{true}}
    @accept="image/*,.pdf"
    @defaultValue={{report}}
    @locale="ar"
    @prompt="اختر الملفات"
    @hint="أو اسحبها وأفلتها هنا"
    @dropLabel="أفلت للإضافة"
    @description="صور أو ملفات PDF، حتى 5 ميغابايت"
    @removeLabel={{removeLabel}}
    @retryLabel={{retryLabel}}
    @progressLabel={{progressLabel}}
    @rejectedLabel={{rejectedLabel}}
    class="w-full max-w-md"
  />
</template>
