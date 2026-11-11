import { GitBranch, Search } from 'lucide'
import { Icon, Marker, Spinner } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-8 py-12">
    <Marker as |m|>
      <m.Icon>
        <Icon @icon={{GitBranch}} />
      </m.Icon>
      <m.Content>Switched to a new branch</m.Content>
    </Marker>
    <Marker role="status" as |m|>
      <m.Icon>
        <Spinner />
      </m.Icon>
      <m.Content class="shimmer">Thinking...</m.Content>
    </Marker>
    <Marker @variant="separator" as |m|>
      <m.Content>Conversation compacted</m.Content>
    </Marker>
    <Marker as |m|>
      <m.Icon>
        <Icon @icon={{Search}} />
      </m.Icon>
      <m.Content>Explored 4 files</m.Content>
    </Marker>
  </div>
</template>
