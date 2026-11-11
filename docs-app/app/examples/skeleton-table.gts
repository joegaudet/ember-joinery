import { Skeleton } from '@ember-joinery/ember'

const ROWS = Array.from({ length: 5 }, (_, index) => index)

<template>
  <div class="flex w-full max-w-sm flex-col gap-2">
    {{#each ROWS}}
      <div class="flex gap-4">
        <Skeleton class="h-4 flex-1" />
        <Skeleton class="h-4 w-24" />
        <Skeleton class="h-4 w-20" />
      </div>
    {{/each}}
  </div>
</template>
