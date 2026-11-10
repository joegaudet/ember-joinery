import { Bubble } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Bubble @variant="muted" as |b|>
      <b.Content>
        This bubble is aligned to the start. This is the default alignment.
      </b.Content>
    </Bubble>
    <Bubble @align="end" as |b|>
      <b.Content>
        This bubble is aligned to the end. Use this for user messages.
      </b.Content>
    </Bubble>
  </div>
</template>
