import { Calculator, Calendar, CreditCard, Settings, Smile, User } from 'lucide'
import { Command, Icon } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream's passes its language's `dir` to the Command and its input; Joinery's take
    it from the nearest `dir`, so the search icon and the headings start on the right, and each
    shortcut ends its item on the left.
  }}
  <Command class="max-w-sm rounded-lg border" as |c|>
    <c.Input placeholder="اكتب أمرًا أو ابحث..." />
    <c.List>
      <c.Empty>لم يتم العثور على نتائج.</c.Empty>
      <c.Group @heading="اقتراحات">
        <c.Item>
          <Icon @icon={{Calendar}} />
          <span>التقويم</span>
        </c.Item>
        <c.Item>
          <Icon @icon={{Smile}} />
          <span>البحث عن الرموز التعبيرية</span>
        </c.Item>
        <c.Item @disabled={{true}}>
          <Icon @icon={{Calculator}} />
          <span>الآلة الحاسبة</span>
        </c.Item>
      </c.Group>
      <c.Separator />
      <c.Group @heading="الإعدادات">
        <c.Item>
          <Icon @icon={{User}} />
          <span>الملف الشخصي</span>
          <c.Shortcut>⌘P</c.Shortcut>
        </c.Item>
        <c.Item>
          <Icon @icon={{CreditCard}} />
          <span>الفوترة</span>
          <c.Shortcut>⌘B</c.Shortcut>
        </c.Item>
        <c.Item>
          <Icon @icon={{Settings}} />
          <span>الإعدادات</span>
          <c.Shortcut>⌘S</c.Shortcut>
        </c.Item>
      </c.Group>
    </c.List>
  </Command>
</template>
