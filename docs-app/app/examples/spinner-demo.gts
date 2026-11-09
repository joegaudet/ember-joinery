import { Item, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-xs flex-col gap-4 [--radius:1rem]">
    <Item @variant="muted" as |i|>
      <i.Media>
        <Spinner />
      </i.Media>
      <i.Content>
        <i.Title class="line-clamp-1">Processing payment...</i.Title>
      </i.Content>
      <i.Content class="flex-none justify-end">
        <span class="text-sm tabular-nums">$100.00</span>
      </i.Content>
    </Item>
  </div>
</template>
