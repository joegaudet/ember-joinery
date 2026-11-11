import { Separator } from '@ember-joinery/ember'

<template>
  {{! m-0 on each <dl>: ui.shadcn.com's preflight takes away a list's margins, and the guide has no preflight. }}
  <div class="flex w-full max-w-sm flex-col gap-2 text-sm">
    <dl class="m-0 flex items-center justify-between">
      <dt>Item 1</dt>
      <dd class="text-muted-foreground">Value 1</dd>
    </dl>
    <Separator />
    <dl class="m-0 flex items-center justify-between">
      <dt>Item 2</dt>
      <dd class="text-muted-foreground">Value 2</dd>
    </dl>
    <Separator />
    <dl class="m-0 flex items-center justify-between">
      <dt>Item 3</dt>
      <dd class="text-muted-foreground">Value 3</dd>
    </dl>
  </div>
</template>
