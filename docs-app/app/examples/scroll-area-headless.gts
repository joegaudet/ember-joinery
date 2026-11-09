import { ScrollArea } from '@ember-joinery/primitives/scroll-area'

const releases = Array.from({ length: 30 }).map((_, i) => `Release ${30 - i}`)

<template>
  {{! A headless scroll area, its scrollbar drawn with utilities; @type="auto" shows it whenever the list overflows. }}
  <ScrollArea @type="auto" class="h-48 w-56 overflow-hidden rounded-md border" as |s|>
    <s.Viewport class="size-full">
      <ul class="p-3 text-sm">
        {{#each releases as |release|}}
          <li class="py-1">{{release}}</li>
        {{/each}}
      </ul>
    </s.Viewport>
    <s.Scrollbar class="flex w-2 touch-none p-px select-none" as |bar|>
      <bar.Thumb class="flex-1 rounded-full bg-border" />
    </s.Scrollbar>
  </ScrollArea>
</template>
