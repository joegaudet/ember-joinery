import { Marker } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker @variant="separator" as |m|>
      <m.Content>Today</m.Content>
    </Marker>
    <Marker @variant="separator" as |m|>
      <m.Content>Worked for 42s</m.Content>
    </Marker>
    <Marker @variant="separator" as |m|>
      <m.Content>Conversation compacted</m.Content>
    </Marker>
  </div>
</template>
