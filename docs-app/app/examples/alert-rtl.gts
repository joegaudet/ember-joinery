import { CheckCircle2, Info } from 'lucide'
import { Alert, Icon } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream's sets dir on its own root from a language picker; Joinery's components take
    their direction from the nearest dir, so the example needs none of its own.
  }}
  <div class="grid w-full max-w-md items-start gap-4">
    <Alert as |a|>
      <Icon @icon={{CheckCircle2}} />
      <a.Title>تم الدفع بنجاح</a.Title>
      <a.Description>
        تمت معالجة دفعتك البالغة 29.99 دولارًا. تم إرسال إيصال إلى عنوان بريدك الإلكتروني.
      </a.Description>
    </Alert>
    <Alert as |a|>
      <Icon @icon={{Info}} />
      <a.Title>ميزة جديدة متاحة</a.Title>
      <a.Description>
        لقد أضفنا دعم الوضع الداكن. يمكنك تفعيله في إعدادات حسابك.
      </a.Description>
    </Alert>
  </div>
</template>
