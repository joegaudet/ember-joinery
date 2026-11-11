import { Popover } from '@ember-joinery/primitives/popover'

<template>
  {{!
    The headless popover, styled here with utility classes alone, with ember-primitives'
    Popover's arguments on its root, an arrow of your own, and where the content went, from
    `data`: it flips below when there's no room above.
  }}
  <Popover @placement="top" @offsetOptions={{8}} as |p|>
    <button type="button" class="rounded-md border px-3 py-1.5 text-sm" {{p.trigger}}>
      Details
    </button>
    <p.Content class="m-0 w-56 rounded-md border-0 bg-gray-900 p-3 text-sm text-white">
      <p.Title class="m-0 text-sm font-semibold">Placed {{p.data.placement}}</p.Title>
      <p.Description class="m-0 mt-1">Escape or a press outside closes it.</p.Description>
      <p.Close class="mt-2 rounded bg-white px-2 py-1 text-gray-900">Done</p.Close>
      <div class="size-3 rotate-45 bg-gray-900" {{p.arrow}}></div>
    </p.Content>
  </Popover>
</template>
