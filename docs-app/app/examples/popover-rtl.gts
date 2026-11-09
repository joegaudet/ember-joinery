import { get } from '@ember/helper'
import { Button, Popover } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  title: 'الأبعاد',
  description: 'تعيين الأبعاد للطبقة.',
  left: 'يسار',
  top: 'أعلى',
  bottom: 'أسفل',
  right: 'يمين',
}

const physicalSides = ['left', 'top', 'bottom', 'right'] as const

<template>
  <div class="flex flex-wrap justify-center gap-2">
    {{#each physicalSides as |side|}}
      <Popover as |p|>
        <Button @variant="outline" {{p.trigger}}>{{get t side}}</Button>
        <p.Content @side={{side}} dir="rtl">
          <p.Header>
            <p.Title>{{t.title}}</p.Title>
            <p.Description>{{t.description}}</p.Description>
          </p.Header>
        </p.Content>
      </Popover>
    {{/each}}
  </div>
</template>
