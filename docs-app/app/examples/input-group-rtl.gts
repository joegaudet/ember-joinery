import { Search } from 'lucide'
import {
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  Icon,
  InputGroup,
  Spinner,
} from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic: its preview opens in Arabic, and the frame has no language picker. Upstream puts dir
    on each group and the field group; Joinery's take it from the nearest dir. Upstream's three
    groups with no label are named by their placeholders.
  }}
  <div class="grid w-full max-w-sm gap-6">
    <InputGroup class="max-w-xs" as |g|>
      <g.Input placeholder="بحث..." />
      <g.Addon>
        <Icon @icon={{Search}} />
      </g.Addon>
      <g.Addon @align="inline-end">١٢ نتيجة</g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="جاري البحث..." />
      <g.Addon @align="inline-end">
        <Spinner />
      </g.Addon>
    </InputGroup>
    <InputGroup as |g|>
      <g.Input placeholder="جاري حفظ التغييرات..." />
      <g.Addon @align="inline-end">
        <g.Text>جاري الحفظ...</g.Text>
        <Spinner />
      </g.Addon>
    </InputGroup>
    <FieldGroup class="max-w-sm">
      <Field>
        <FieldLabel for="rtl-textarea">منطقة النص</FieldLabel>
        <InputGroup as |g|>
          <g.Textarea id="rtl-textarea" placeholder="اكتب تعليقًا..." />
          <g.Addon @align="block-end">
            <g.Text>٠/٢٨٠</g.Text>
            <g.Button @variant="default" @size="sm" class="ml-auto">
              نشر
            </g.Button>
          </g.Addon>
        </InputGroup>
        <FieldDescription>تذييل موضع أسفل منطقة النص.</FieldDescription>
      </Field>
    </FieldGroup>
  </div>
</template>
