import { Button, Dialog, Field, FieldGroup, Input, Label } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the content; Joinery's takes it from the nearest dir. The ids differ from
    dialog-demo's, which shares the page.
  }}
  <Dialog as |d|>
    <form>
      <Button @variant="outline" {{d.trigger}}>فتح الحوار</Button>
      <d.Content class="sm:max-w-sm">
        <d.Header>
          <d.Title>تعديل الملف الشخصي</d.Title>
          <d.Description>قم بإجراء تغييرات على ملفك الشخصي هنا. انقر فوق حفظ عند الانتهاء.</d.Description>
        </d.Header>
        <FieldGroup>
          <Field>
            <Label for="name-1-rtl">الاسم</Label>
            <Input id="name-1-rtl" name="name" @defaultValue="Pedro Duarte" />
          </Field>
          <Field>
            <Label for="username-1-rtl">اسم المستخدم</Label>
            <Input id="username-1-rtl" name="username" @defaultValue="@peduarte" />
          </Field>
        </FieldGroup>
        <d.Footer>
          <Button @variant="outline" {{d.close}}>إلغاء</Button>
          <Button type="submit">حفظ التغييرات</Button>
        </d.Footer>
      </d.Content>
    </form>
  </Dialog>
</template>
