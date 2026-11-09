import { get } from '@ember/helper'
import { Button, HoverCard } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  trigger: 'سماعات لاسلكية',
  name: 'سماعات لاسلكية',
  price: '٩٩.٩٩ $',
  left: 'يسار',
  top: 'أعلى',
  bottom: 'أسفل',
  right: 'يمين',
}

const physicalSides = ['left', 'top', 'bottom', 'right'] as const

<template>
  <div class="flex flex-wrap justify-center gap-2">
    {{#each physicalSides as |side|}}
      <HoverCard @openDelay={{10}} @closeDelay={{100}} as |h|>
        <Button @variant="outline" {{h.trigger}}>{{get t side}}</Button>
        <h.Content @side={{side}} class="flex w-64 flex-col gap-1" dir="rtl">
          <div class="font-semibold">{{t.name}}</div>
          <div class="text-sm text-muted-foreground">{{t.price}}</div>
        </h.Content>
      </HoverCard>
    {{/each}}
  </div>
</template>
