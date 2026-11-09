import { get } from '@ember/helper'
import { Button, Tooltip } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  content: 'إضافة إلى المكتبة',
  left: 'يسار',
  top: 'أعلى',
  bottom: 'أسفل',
  right: 'يمين',
}

const sides = ['left', 'top', 'bottom', 'right'] as const

<template>
  <div class="flex flex-wrap gap-2">
    {{#each sides as |side|}}
      <Tooltip as |tooltip|>
        <Button @variant="outline" class="w-fit capitalize" {{tooltip.trigger}}>
          {{get t side}}
        </Button>
        <tooltip.Content @side={{side}}>{{t.content}}</tooltip.Content>
      </Tooltip>
    {{/each}}
  </div>
</template>
