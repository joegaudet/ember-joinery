import { Button, Field, FieldGroup, FieldLabel, Input, Sheet } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the content and opens it from the left right to left; Joinery's takes its direction
    from the nearest dir, and @side="left" is upstream's side for Arabic.
  }}
  <Sheet as |s|>
    <Button @variant="outline" {{s.trigger}}>فتح</Button>
    <s.Content @side="left">
      <s.Header>
        <s.Title>تعديل الملف الشخصي</s.Title>
        <s.Description>قم بإجراء تغييرات على ملفك الشخصي هنا. انقر حفظ عند الانتهاء.</s.Description>
      </s.Header>
      <FieldGroup class="px-4">
        <Field>
          <FieldLabel for="sheet-rtl-name">الاسم</FieldLabel>
          <Input id="sheet-rtl-name" @defaultValue="Pedro Duarte" />
        </Field>
        <Field>
          <FieldLabel for="sheet-rtl-username">اسم المستخدم</FieldLabel>
          <Input id="sheet-rtl-username" @defaultValue="peduarte" />
        </Field>
      </FieldGroup>
      <s.Footer>
        <Button type="submit">حفظ التغييرات</Button>
        <Button @variant="outline" {{s.close}}>إغلاق</Button>
      </s.Footer>
    </s.Content>
  </Sheet>
</template>
