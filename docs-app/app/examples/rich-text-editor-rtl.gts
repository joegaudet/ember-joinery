import { Field, FieldLabel } from '@ember-joinery/ember'
import { RichTextEditor } from '@ember-joinery/tiptap'

// Every string is an argument; these are the toolbar's in Arabic.
const labels = {
  toolbar: 'التنسيق',
  blockType: 'نمط النص',
  paragraph: 'فقرة',
  heading: (level: number) => `عنوان ${level}`,
  bold: 'غامق',
  italic: 'مائل',
  underline: 'تسطير',
  strike: 'يتوسطه خط',
  code: 'رمز',
  'bullet-list': 'قائمة نقطية',
  'ordered-list': 'قائمة مرقمة',
  blockquote: 'اقتباس',
  'code-block': 'كتلة رمز',
  undo: 'تراجع',
  redo: 'إعادة',
}

const NOTES = '<h2>ملاحظات الإصدار</h2><p>محرر نصوص <strong>منسقة</strong> يتبع اتجاه الصفحة.</p>'

<template>
  <Field class="w-full max-w-xl">
    <FieldLabel for="notes-rtl">الملاحظات</FieldLabel>
    <RichTextEditor
      @name="notes"
      @id="notes-rtl"
      @labels={{labels}}
      @placeholder="اكتب شيئًا"
      @defaultValue={{NOTES}}
    />
  </Field>
</template>
