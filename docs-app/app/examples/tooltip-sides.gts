import { Button, Tooltip } from '@ember-joinery/ember'

const sides = ['left', 'top', 'bottom', 'right'] as const

<template>
  <div class="flex flex-wrap gap-2">
    {{#each sides as |side|}}
      <Tooltip as |t|>
        <Button @variant="outline" class="w-fit capitalize" {{t.trigger}}>
          {{side}}
        </Button>
        <t.Content @side={{side}}>
          <p>Add to library</p>
        </t.Content>
      </Tooltip>
    {{/each}}
  </div>
</template>
