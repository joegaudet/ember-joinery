import { BookOpenCheck, GitBranch, Search } from 'lucide'
import { Icon, Marker } from '@ember-joinery/ember'

<template>
  <div class="flex w-full max-w-sm flex-col gap-12 py-12">
    <Marker as |m|>
      <m.Icon>
        <Icon @icon={{GitBranch}} />
      </m.Icon>
      <m.Content>Switched to a new branch</m.Content>
    </Marker>
    <Marker @variant="separator" as |m|>
      <m.Icon>
        <Icon @icon={{Search}} />
      </m.Icon>
      <m.Content>Explored 4 files</m.Content>
    </Marker>
    <Marker class="flex-col" as |m|>
      <m.Icon>
        <Icon @icon={{BookOpenCheck}} />
      </m.Icon>
      <m.Content>Syncing completed</m.Content>
    </Marker>
  </div>
</template>
