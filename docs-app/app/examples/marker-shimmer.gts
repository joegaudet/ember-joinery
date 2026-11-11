import { Marker } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker role="status" as |m|>
      <m.Content class="shimmer">Thinking...</m.Content>
    </Marker>
    <Marker @variant="separator" role="status" as |m|>
      <m.Content class="shimmer">Reading 4 files</m.Content>
    </Marker>
  </div>
</template>
