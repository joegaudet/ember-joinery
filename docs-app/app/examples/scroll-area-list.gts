import { ScrollArea } from '@ember-joinery/ember'

const tags = Array.from({ length: 50 }).map((_, i, a) => `v1.2.0-beta.${a.length - i}`)

<template>
  {{!
    Joinery's own example. Upstream's first example (scroll-area-demo) puts a Separator between
    the tags, and Separator hasn't landed yet; until it does, this is that list with space
    between the tags instead. Its title is a paragraph: upstream's h4 would skip heading levels
    under the guide page's.
  }}
  <ScrollArea class="h-72 w-48 rounded-md border">
    <div class="p-4">
      <p class="mb-4 text-sm leading-none font-medium">Tags</p>
      {{#each tags as |tag|}}
        <div class="py-1 text-sm">{{tag}}</div>
      {{/each}}
    </div>
  </ScrollArea>
</template>
