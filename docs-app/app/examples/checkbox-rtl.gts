import {
  Checkbox,
  Field,
  FieldContent,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldTitle,
  Label,
} from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the group; Joinery's parts take it from the nearest dir. The last checkbox names
    itself by its title with aria-labelledby, as in checkbox-demo, so the audit passes.
  }}
  <FieldGroup class="max-w-sm">
    <Field @orientation="horizontal">
      <Checkbox id="terms-checkbox-rtl" name="terms-checkbox" />
      <Label for="terms-checkbox-rtl">قبول الشروط والأحكام</Label>
    </Field>
    <Field @orientation="horizontal">
      <Checkbox id="terms-checkbox-2-rtl" name="terms-checkbox-2" @defaultChecked={{true}} />
      <FieldContent>
        <FieldLabel for="terms-checkbox-2-rtl">
          قبول الشروط والأحكام
        </FieldLabel>
        <FieldDescription>بالنقر على هذا المربع، فإنك توافق على الشروط.</FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal" @disabled={{true}}>
      <Checkbox id="toggle-checkbox-rtl" name="toggle-checkbox" @disabled={{true}} />
      <FieldLabel for="toggle-checkbox-rtl">
        تفعيل الإشعارات
      </FieldLabel>
    </Field>
    <FieldLabel>
      <Field @orientation="horizontal">
        <Checkbox
          id="toggle-checkbox-2-rtl"
          name="toggle-checkbox-2"
          aria-labelledby="toggle-checkbox-2-rtl-title"
        />
        <FieldContent>
          <FieldTitle id="toggle-checkbox-2-rtl-title">تفعيل الإشعارات</FieldTitle>
          <FieldDescription>
            يمكنك تفعيل أو إلغاء تفعيل الإشعارات في أي وقت.
          </FieldDescription>
        </FieldContent>
      </Field>
    </FieldLabel>
  </FieldGroup>
</template>
