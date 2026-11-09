import { ArrowUpRight, FolderCode } from 'lucide'
import { Button, Empty, Icon } from '@ember-joinery/ember'

<template>
  {{!
    Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
    Arabic. Upstream's sets dir on its own root from a language picker; Joinery's components take
    their direction from the nearest dir, so the example needs none of its own. Upstream's draws
    Tabler's folder-code; Joinery's icons are lucide's.
  }}
  <Empty as |e|>
    <e.Header>
      <e.Media @variant="icon">
        <Icon @icon={{FolderCode}} />
      </e.Media>
      <e.Title>لا توجد مشاريع بعد</e.Title>
      <e.Description>لم تقم بإنشاء أي مشاريع بعد. ابدأ بإنشاء مشروعك الأول.</e.Description>
    </e.Header>
    <e.Content class="flex-row justify-center gap-2">
      <Button>إنشاء مشروع</Button>
      <Button @variant="outline">استيراد مشروع</Button>
    </e.Content>
    <Button @as="a" href="#" @variant="link" @size="sm" class="text-muted-foreground">
      تعرف على المزيد
      <Icon @icon={{ArrowUpRight}} class="rtl:rotate-270" data-icon="inline-end" />
    </Button>
  </Empty>
</template>
