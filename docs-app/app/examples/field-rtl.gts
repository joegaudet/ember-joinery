import {
  Button,
  Checkbox,
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSeparator,
  FieldSet,
  Input,
  Select,
  Textarea,
} from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  paymentMethod: 'طريقة الدفع',
  secureTransactions: 'جميع المعاملات آمنة ومشفرة',
  nameOnCard: 'الاسم على البطاقة',
  cardNumber: 'رقم البطاقة',
  cardNumberDescription: 'أدخل رقم البطاقة المكون من 16 رقمًا',
  month: 'الشهر',
  year: 'السنة',
  cvv: 'CVV',
  monthPlaceholder: 'ش.ش',
  month01: '٠١',
  month02: '٠٢',
  month03: '٠٣',
  month04: '٠٤',
  month05: '٠٥',
  month06: '٠٦',
  month07: '٠٧',
  month08: '٠٨',
  month09: '٠٩',
  month10: '١٠',
  month11: '١١',
  month12: '١٢',
  billingAddress: 'عنوان الفوترة',
  billingAddressDescription: 'عنوان الفوترة المرتبط بطريقة الدفع الخاصة بك',
  sameAsShipping: 'نفس عنوان الشحن',
  comments: 'تعليقات',
  commentsPlaceholder: 'أضف أي تعليقات إضافية',
  submit: 'إرسال',
  cancel: 'إلغاء',
}

const months = [
  { label: 'MM', value: null },
  { label: '01', value: '01' },
  { label: '02', value: '02' },
  { label: '03', value: '03' },
  { label: '04', value: '04' },
  { label: '05', value: '05' },
  { label: '06', value: '06' },
  { label: '07', value: '07' },
  { label: '08', value: '08' },
  { label: '09', value: '09' },
  { label: '10', value: '10' },
  { label: '11', value: '11' },
  { label: '12', value: '12' },
]

const years = [
  { label: 'YYYY', value: null },
  { label: '2024', value: '2024' },
  { label: '2025', value: '2025' },
  { label: '2026', value: '2026' },
  { label: '2027', value: '2027' },
  { label: '2028', value: '2028' },
  { label: '2029', value: '2029' },
]

const itemValue = (item: { label: string; value: string | null }) => item.value ?? item.label

const labels: Record<string, string> = t

const getMonthLabel = (value: string | null): string => {
  if (value === null) return t.monthPlaceholder
  return labels[`month${value}`] || value
}

<template>
  <div class="w-full max-w-md py-6" dir="rtl">
    <form>
      <FieldGroup>
        <FieldSet>
          <FieldLegend>{{t.paymentMethod}}</FieldLegend>
          <FieldDescription>{{t.secureTransactions}}</FieldDescription>
          <FieldGroup>
            <Field>
              <FieldLabel for="checkout-7j9-card-name-43j-rtl">
                {{t.nameOnCard}}
              </FieldLabel>
              <Input id="checkout-7j9-card-name-43j-rtl" placeholder="Evil Rabbit" required />
            </Field>
            <Field>
              <FieldLabel for="checkout-7j9-card-number-uw1-rtl">
                {{t.cardNumber}}
              </FieldLabel>
              <Input
                id="checkout-7j9-card-number-uw1-rtl"
                placeholder="1234 5678 9012 3456"
                required
              />
              <FieldDescription>{{t.cardNumberDescription}}</FieldDescription>
            </Field>
            <div class="grid grid-cols-3 gap-4">
              <Field>
                <FieldLabel for="checkout-exp-month-ts6-rtl">
                  {{t.month}}
                </FieldLabel>
                <Select as |s|>
                  <s.Trigger id="checkout-exp-month-ts6-rtl">
                    <s.Value />
                  </s.Trigger>
                  <s.Content dir="rtl">
                    <s.Group>
                      {{#each months as |item|}}
                        <s.Item @value={{itemValue item}}>
                          {{getMonthLabel item.value}}
                        </s.Item>
                      {{/each}}
                    </s.Group>
                  </s.Content>
                </Select>
              </Field>
              <Field>
                <FieldLabel for="checkout-7j9-exp-year-f59-rtl">
                  {{t.year}}
                </FieldLabel>
                <Select as |s|>
                  <s.Trigger id="checkout-7j9-exp-year-f59-rtl">
                    <s.Value />
                  </s.Trigger>
                  <s.Content dir="rtl">
                    <s.Group>
                      {{#each years as |item|}}
                        <s.Item @value={{itemValue item}}>
                          {{item.label}}
                        </s.Item>
                      {{/each}}
                    </s.Group>
                  </s.Content>
                </Select>
              </Field>
              <Field>
                <FieldLabel for="checkout-7j9-cvv-rtl">
                  {{t.cvv}}
                </FieldLabel>
                <Input id="checkout-7j9-cvv-rtl" placeholder="123" required />
              </Field>
            </div>
          </FieldGroup>
        </FieldSet>
        <FieldSeparator />
        <FieldSet>
          <FieldLegend>{{t.billingAddress}}</FieldLegend>
          <FieldDescription>{{t.billingAddressDescription}}</FieldDescription>
          <FieldGroup>
            <Field @orientation="horizontal">
              <Checkbox id="checkout-7j9-same-as-shipping-wgm-rtl" @defaultChecked={{true}} />
              <FieldLabel for="checkout-7j9-same-as-shipping-wgm-rtl" class="font-normal">
                {{t.sameAsShipping}}
              </FieldLabel>
            </Field>
          </FieldGroup>
        </FieldSet>
        <FieldSet>
          <FieldGroup>
            <Field>
              <FieldLabel for="checkout-7j9-optional-comments-rtl">
                {{t.comments}}
              </FieldLabel>
              <Textarea
                id="checkout-7j9-optional-comments-rtl"
                placeholder={{t.commentsPlaceholder}}
                class="resize-none"
              />
            </Field>
          </FieldGroup>
        </FieldSet>
        <Field @orientation="horizontal">
          <Button type="submit">{{t.submit}}</Button>
          <Button @variant="outline" type="button">
            {{t.cancel}}
          </Button>
        </Field>
      </FieldGroup>
    </form>
  </div>
</template>
