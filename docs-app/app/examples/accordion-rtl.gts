import { Accordion } from '@ember-joinery/ember'

// Upstream's Arabic, the language its right-to-left preview opens in.
const items = [
  {
    value: 'item-1',
    question: 'كيف يمكنني إعادة تعيين كلمة المرور؟',
    answer:
      "انقر على 'نسيت كلمة المرور' في صفحة تسجيل الدخول، أدخل عنوان بريدك الإلكتروني، وسنرسل لك رابطًا لإعادة تعيين كلمة المرور. سينتهي صلاحية الرابط خلال 24 ساعة.",
  },
  {
    value: 'item-2',
    question: 'هل يمكنني تغيير خطة الاشتراك الخاصة بي؟',
    answer:
      'نعم، يمكنك ترقية أو تخفيض خطتك في أي وقت من إعدادات حسابك. ستظهر التغييرات في دورة الفوترة التالية.',
  },
  {
    value: 'item-3',
    question: 'ما هي طرق الدفع التي تقبلونها؟',
    answer:
      'نقبل جميع بطاقات الائتمان الرئيسية و PayPal والتحويلات المصرفية. تتم معالجة جميع المدفوعات بأمان من خلال شركاء الدفع لدينا.',
  },
]

<template>
  {{! Shown right to left: the frame's RTL switch, or dir="rtl" on any ancestor. }}
  <Accordion
    @type="single"
    @collapsible={{true}}
    @defaultValue="item-1"
    class="max-w-md"
    as |accordion|
  >
    {{#each items as |item|}}
      <accordion.Item @value={{item.value}} as |i|>
        <i.Trigger>{{item.question}}</i.Trigger>
        <i.Content>{{item.answer}}</i.Content>
      </accordion.Item>
    {{/each}}
  </Accordion>
</template>
