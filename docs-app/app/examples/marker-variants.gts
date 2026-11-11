import { Marker } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker as |m|>
      <m.Content>A default marker for inline notes.</m.Content>
    </Marker>
    <Marker @variant="separator" as |m|>
      <m.Content>A separator marker</m.Content>
    </Marker>
    <Marker @variant="border" as |m|>
      <m.Content>A border marker for row boundaries.</m.Content>
    </Marker>
  </div>
</template>
