import { Item, ItemGroup } from '@ember-joinery/ember'

const models = [
  {
    name: 'v0-1.5-sm',
    description: 'Everyday tasks and UI generation.',
    image:
      'https://images.unsplash.com/photo-1650804068570-7fb2e3dbf888?q=80&w=640&auto=format&fit=crop',
    credit: 'Valeria Reverdo on Unsplash',
  },
  {
    name: 'v0-1.5-lg',
    description: 'Advanced thinking or reasoning.',
    image:
      'https://images.unsplash.com/photo-1610280777472-54133d004c8c?q=80&w=640&auto=format&fit=crop',
    credit: 'Michael Oeser on Unsplash',
  },
  {
    name: 'v0-2.0-mini',
    description: 'Open Source model for everyone.',
    image:
      'https://images.unsplash.com/photo-1602146057681-08560aee8cde?q=80&w=640&auto=format&fit=crop',
    credit: 'Cherry Laithang on Unsplash',
  },
]

<template>
  {{!
    Upstream's next/image is a plain <img>, with h-auto: ui.shadcn.com's preflight gives an
    image height: auto, so aspect-square sizes it rather than its height attribute, and the
    guide has no preflight. Each item is a listitem, as the group is a list, so the
    accessibility audit passes; upstream's leave the role off.
  }}
  <div class="flex w-full max-w-xl flex-col gap-6">
    <ItemGroup class="grid grid-cols-3 gap-4">
      {{#each models as |model|}}
        <Item @variant="outline" role="listitem" as |i|>
          <i.Header>
            <img
              src={{model.image}}
              alt={{model.name}}
              width="128"
              height="128"
              class="aspect-square h-auto w-full rounded-sm object-cover"
            />
          </i.Header>
          <i.Content>
            <i.Title>{{model.name}}</i.Title>
            <i.Description>{{model.description}}</i.Description>
          </i.Content>
        </Item>
      {{/each}}
    </ItemGroup>
  </div>
</template>
