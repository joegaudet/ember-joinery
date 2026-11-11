import { Field, FieldContent, FieldDescription, FieldLabel, RadioGroup } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts
    dir on the group and its parts; Joinery's take it from the nearest dir, the arrow keys
    included.
  }}
  <RadioGroup @defaultValue="comfortable" class="w-fit" as |group|>
    <Field @orientation="horizontal">
      <group.Item @value="default" id="r1-rtl" />
      <FieldContent>
        <FieldLabel for="r1-rtl">
          افتراضي
        </FieldLabel>
        <FieldDescription>تباعد قياسي لمعظم حالات الاستخدام.</FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal">
      <group.Item @value="comfortable" id="r2-rtl" />
      <FieldContent>
        <FieldLabel for="r2-rtl">
          مريح
        </FieldLabel>
        <FieldDescription>
          مساحة أكبر بين العناصر.
        </FieldDescription>
      </FieldContent>
    </Field>
    <Field @orientation="horizontal">
      <group.Item @value="compact" id="r3-rtl" />
      <FieldContent>
        <FieldLabel for="r3-rtl">
          مضغوط
        </FieldLabel>
        <FieldDescription>تباعد أدنى للتخطيطات الكثيفة.</FieldDescription>
      </FieldContent>
    </Field>
  </RadioGroup>
</template>
