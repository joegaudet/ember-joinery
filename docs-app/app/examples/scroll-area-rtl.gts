import { ScrollArea, Separator } from '@ember-joinery/ember'

// Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
// Arabic: its preview opens in Arabic, and the frame has no language picker. These are its
// strings, upstream's `t`. Upstream puts dir on the area from its language picker; Joinery's
// components take their direction from the nearest dir, so it needs none of its own.
const t = {
  tags: 'العلامات',
}

const tags = Array.from({ length: 50 }).map((_, i, a) => `v1.2.0-beta.${a.length - i}`)

<template>
  <ScrollArea class="h-72 w-48 rounded-md border">
    <div class="p-4">
      <h4 class="mb-4 text-sm leading-none font-medium">{{t.tags}}</h4>
      {{#each tags as |tag|}}
        <div class="text-sm">{{tag}}</div>
        <Separator class="my-2" />
      {{/each}}
    </div>
  </ScrollArea>
</template>
