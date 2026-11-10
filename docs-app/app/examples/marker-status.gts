import { Marker, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker role="status" as |m|>
      <m.Icon>
        <Spinner />
      </m.Icon>
      <m.Content>Compacting conversation</m.Content>
    </Marker>
    <Marker @variant="separator" role="status" as |m|>
      <m.Icon>
        <Spinner />
      </m.Icon>
      <m.Content>Running tests</m.Content>
    </Marker>
  </div>
</template>
