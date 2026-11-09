import { Bluetooth } from 'lucide'
import { AlertDialog, Button, Icon } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream also puts dir on each content, which Radix portals out of the page; Joinery's
    stays inside it, in the top layer, so it takes the page's direction.
  }}
  <div class="flex gap-4">
    <AlertDialog as |d|>
      <Button @variant="outline" {{d.trigger}}>إظهار الحوار</Button>
      <d.Content>
        <d.Header>
          <d.Title>هل أنت متأكد تمامًا؟</d.Title>
          <d.Description>
            لا يمكن التراجع عن هذا الإجراء. سيؤدي هذا إلى حذف حسابك نهائيًا من خوادمنا.
          </d.Description>
        </d.Header>
        <d.Footer>
          <d.Cancel>إلغاء</d.Cancel>
          <d.Action>متابعة</d.Action>
        </d.Footer>
      </d.Content>
    </AlertDialog>
    <AlertDialog as |d|>
      <Button @variant="outline" {{d.trigger}}>إظهار الحوار (صغير)</Button>
      <d.Content @size="sm">
        <d.Header>
          <d.Media>
            <Icon @icon={{Bluetooth}} />
          </d.Media>
          <d.Title>السماح للملحق بالاتصال؟</d.Title>
          <d.Description>
            هل تريد السماح لملحق USB بالاتصال بهذا الجهاز؟
          </d.Description>
        </d.Header>
        <d.Footer>
          <d.Cancel>عدم السماح</d.Cancel>
          <d.Action>السماح</d.Action>
        </d.Footer>
      </d.Content>
    </AlertDialog>
  </div>
</template>
