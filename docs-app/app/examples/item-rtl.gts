import { BadgeCheck, ChevronRight } from 'lucide'
import { Button, Icon, Item } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. The actions move to the left; upstream's chevron points right in both directions,
    and so does this one.
  }}
  <div class="flex w-full max-w-md flex-col gap-6">
    <Item @variant="outline" as |i|>
      <i.Content>
        <i.Title>عنصر أساسي</i.Title>
        <i.Description>عنصر بسيط يحتوي على عنوان ووصف.</i.Description>
      </i.Content>
      <i.Actions>
        <Button @variant="outline" @size="sm">
          إجراء
        </Button>
      </i.Actions>
    </Item>
    <Item @variant="outline" @size="sm" @as="a" href="#" as |i|>
      <i.Media>
        <Icon @icon={{BadgeCheck}} class="size-5" />
      </i.Media>
      <i.Content>
        <i.Title>تم التحقق من ملفك الشخصي.</i.Title>
      </i.Content>
      <i.Actions>
        <Icon @icon={{ChevronRight}} class="size-4" />
      </i.Actions>
    </Item>
  </div>
</template>
