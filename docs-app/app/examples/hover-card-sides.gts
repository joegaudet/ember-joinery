import { Button, HoverCard } from '@ember-joinery/ember'

const HOVER_CARD_SIDES = ['left', 'top', 'bottom', 'right'] as const

<template>
  <div class="flex flex-wrap justify-center gap-2">
    {{#each HOVER_CARD_SIDES as |side|}}
      <HoverCard @openDelay={{100}} @closeDelay={{100}} as |h|>
        <Button @variant="outline" class="capitalize" {{h.trigger}}>
          {{side}}
        </Button>
        <h.Content @side={{side}}>
          <div class="flex flex-col gap-1">
            <h4 class="font-medium">Hover Card</h4>
            <p>This hover card appears on the {{side}} side of the trigger.</p>
          </div>
        </h.Content>
      </HoverCard>
    {{/each}}
  </div>
</template>
