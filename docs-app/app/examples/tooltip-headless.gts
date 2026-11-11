import { Tooltip, TooltipProvider } from '@ember-joinery/primitives/tooltip'

const tools = ['Bold', 'Italic', 'Underline']

<template>
  {{!
    Headless tooltips in a provider, styled here with utility classes alone: the first waits for
    the provider's delay, and moving along the toolbar shows each of the others at once.
  }}
  <TooltipProvider @delayDuration={{400}}>
    <div class="flex gap-1">
      {{#each tools as |tool|}}
        <Tooltip as |t|>
          <t.Trigger class="rounded-md border px-3 py-1.5 text-sm">{{tool}}</t.Trigger>
          <t.Content class="m-0 rounded border-0 bg-gray-900 px-2 py-1 text-xs text-white">
            {{tool}}
            <t.Arrow class="fill-gray-900" />
          </t.Content>
        </Tooltip>
      {{/each}}
    </div>
  </TooltipProvider>
</template>
